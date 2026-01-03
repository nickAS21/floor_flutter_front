import 'package:floor_front/page/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';

class SettingsPage extends StatefulWidget {
  final LocationType location;
  const SettingsPage({super.key, required this.location});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;

  String _versionBackend = "";
  bool _currentHandleControl = false;
  bool _currentHeaterAuto = false;
  int? _currentSeasonsId;

  final TextEditingController _batteryController = TextEditingController();
  final TextEditingController _logsLimitController = TextEditingController();

  bool _originalHandleControl = false;
  bool _originalHeaterAuto = false;
  int? _originalSeasonsId;
  String _originalBatteryValue = "";
  String _originalLogsAppLimitValue = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
    _batteryController.addListener(() => setState(() {}));
    _logsLimitController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      setState(() {
        _isLoading = true;
        _batteryController.clear();
        _logsLimitController.clear();
      });
      _fetchData();
    }
  }

  bool _hasChanges() {
    bool baseChanges = _currentHandleControl != _originalHandleControl ||
        _batteryController.text != _originalBatteryValue ||
        _logsLimitController.text != _originalLogsAppLimitValue;

    if (widget.location == LocationType.dacha) {
      return baseChanges ||
          _currentHeaterAuto != _originalHeaterAuto ||
          _currentSeasonsId != _originalSeasonsId;
    }
    return baseChanges;
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathGolego}';

    try {
      final response = await http.get(
          Uri.parse(apiUrl),
          headers: {"Authorization": "Bearer $token"}
      );

      if (response.statusCode == 200) {
        final data = SettingsModel.fromJson(jsonDecode(response.body));
        setState(() {
          _versionBackend = data.versionBackend;
          _originalHandleControl = data.devicesChangeHandleControl;
          _originalBatteryValue = data.batteryCriticalNightSocWinter?.toString() ?? "";
          _originalLogsAppLimitValue = data.logsAppLimit.toString();
          _originalHeaterAuto = data.heaterNightAutoOnDachaWinter ?? false;
          _originalSeasonsId = data.seasonsId;

          _currentHandleControl = _originalHandleControl;
          _currentHeaterAuto = _originalHeaterAuto;
          _currentSeasonsId = _originalSeasonsId;
          _batteryController.text = _originalBatteryValue;
          _logsLimitController.text = _originalLogsAppLimitValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка завантаження: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateSettings() async {
    if (!_hasChanges()) return;
    setState(() => _isLoading = true);

    final int sentLimit = int.tryParse(_logsLimitController.text) ?? 100;
    final double? sentBattery = widget.location == LocationType.dacha ? double.tryParse(_batteryController.text) : null;
    final bool sentHandle = _currentHandleControl;
    final bool? sentHeaterAuto = widget.location == LocationType.dacha ? _currentHeaterAuto : null;
    final int? sentSeason = widget.location == LocationType.dacha ? _currentSeasonsId : null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathGolego}';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          'devicesChangeHandleControl': sentHandle,
          'logsAppLimit': sentLimit,
          if (sentBattery != null) 'batteryCriticalNightSocWinter': sentBattery,
          if (sentHeaterAuto != null) 'heaterNightAutoOnDachaWinter': sentHeaterAuto,
          if (sentSeason != null) 'seasonsId': sentSeason,
        }),
      );

      if (response.statusCode == 200) {
        final updatedData = SettingsModel.fromJson(jsonDecode(response.body));
        List<String> failedFields = [];
        final labels = SettingsModel.fieldLabels;

        setState(() {
          _versionBackend = updatedData.versionBackend;
          if (updatedData.devicesChangeHandleControl == sentHandle) {
            _originalHandleControl = updatedData.devicesChangeHandleControl;
          } else {
            failedFields.add(labels[SettingsModel.keyHandle]!);
          }
          if (updatedData.logsAppLimit == sentLimit) {
            _originalLogsAppLimitValue = updatedData.logsAppLimit.toString();
          } else {
            failedFields.add(labels[SettingsModel.keyLogs]!);
          }
          if (widget.location == LocationType.dacha) {
            if (updatedData.batteryCriticalNightSocWinter == sentBattery) {
              _originalBatteryValue = updatedData.batteryCriticalNightSocWinter?.toString() ?? "";
            } else {
              failedFields.add(labels[SettingsModel.keySoc]!);
            }
            if (updatedData.heaterNightAutoOnDachaWinter == sentHeaterAuto) {
              _originalHeaterAuto = updatedData.heaterNightAutoOnDachaWinter ?? false;
            } else {
              failedFields.add(labels[SettingsModel.keyHeaterNightAuto]!);
            }
            if (updatedData.seasonsId == sentSeason) {
              _originalSeasonsId = updatedData.seasonsId;
            } else {
              failedFields.add(labels[SettingsModel.keySeasonsId]!);
            }
          }
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failedFields.isEmpty ? "Налаштування збережено" : "Не оновлено: ${failedFields.join(', ')}"),
            backgroundColor: failedFields.isEmpty ? Colors.green.shade600 : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка збереження: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canSave = _hasChanges() && !_isLoading;
    final labels = SettingsModel.fieldLabels;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Налаштування: ${widget.location == LocationType.dacha ? 'Дача' : 'Golego'}",
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _buildInfoCard(labels[SettingsModel.keyVersionBackend]!, _versionBackend),
          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleCard(
                    title: "Ручне",
                    subtitle: labels[SettingsModel.keyHandle]!,
                    value: _currentHandleControl,
                    icon: Icons.touch_app,
                    color: Colors.orange.shade700,
                    onChanged: (val) => setState(() => _currentHandleControl = val),
                  ),
                ),
                if (widget.location == LocationType.dacha) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleCard(
                      title: "Зима",
                      subtitle: "Авто-підігрів підлоги",
                      value: _currentHeaterAuto,
                      icon: Icons.ac_unit,
                      color: Colors.blue.shade700,
                      onChanged: (val) => setState(() => _currentHeaterAuto = val),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (widget.location == LocationType.dacha) ...[
            _buildSeasonDropdown(),
            const SizedBox(height: 12),
          ],

          _buildInputCard(
            controller: _logsLimitController,
            label: labels[SettingsModel.keyLogs]!,
            icon: Icons.list_alt,
          ),

          if (widget.location == LocationType.dacha) ...[
            const SizedBox(height: 12),
            _buildInputCard(
              controller: _batteryController,
              label: labels[SettingsModel.keySoc]!,
              icon: Icons.battery_alert,
              isDecimal: true,
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canSave ? _updateSettings : null,
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text("ЗБЕРЕГТИ ЗМІНИ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonDropdown() {
    final labels = SettingsModel.fieldLabels;

    // Налаштування іконки для поля вибору
    IconData getSeasonIcon() {
      switch (_currentSeasonsId) {
        case 1: return Icons.cloudy_snowing; // Зима: Туча зі снігом
        case 2: return Icons.local_florist;   // Весна: Квітка
        case 3: return Icons.wb_sunny;        // Літо: Сонце
        case 4: return Icons.eco;             // Осінь: Листок
        default: return Icons.calendar_month;
      }
    }

    // Налаштування кольору для поля вибору
    Color getSeasonColor() {
      switch (_currentSeasonsId) {
        case 1: return Colors.blue.shade400;   // Зима: Синій/Блакитний
        case 2: return Colors.green.shade600;  // Весна: Зелений
        case 3: return Colors.orange.shade700; // Літо: Помаранчевий
        case 4: return Colors.yellow.shade800; // Осінь: Жовтий
        default: return Colors.grey;
      }
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: DropdownButtonFormField<int>(
          value: _currentSeasonsId,
          decoration: InputDecoration(
            labelText: labels[SettingsModel.keySeasonsId],
            labelStyle: const TextStyle(fontSize: 13),
            icon: Icon(getSeasonIcon(), color: getSeasonColor()),
            border: InputBorder.none,
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text("Зима (Winter)")),
            DropdownMenuItem(value: 2, child: Text("Весна (Spring)")),
            DropdownMenuItem(value: 3, child: Text("Літо (Summer)")),
            DropdownMenuItem(value: 4, child: Text("Осінь (Autumn)")),
          ],
          onChanged: (val) => setState(() => _currentSeasonsId = val),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Switch(
              value: value,
              activeColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDecimal = false,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.blueGrey),
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _logsLimitController.dispose();
    super.dispose();
  }
}