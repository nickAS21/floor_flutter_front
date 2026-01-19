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
  bool _currentAutoAllDay = false;
  int? _currentSeasonsId;

  final TextEditingController _batteryController = TextEditingController();
  final TextEditingController _logsLimitController = TextEditingController();

  bool _originalHandleControl = false;
  bool _originalHeaterAuto = false;
  bool _originalAutoAllDay = false;
  int? _originalSeasonsId;
  String _originalBatteryValue = "";
  String _originalLogsAppLimitValue = "";

  @override
  void initState() {
    super.initState();
    _fetchData();

    // Слухачі для активації кнопки збереження при вводі тексту
    _batteryController.addListener(() { if(mounted) setState(() {}); });
    _logsLimitController.addListener(() { if(mounted) setState(() {}); });
  }

  void _showExclusiveWarning() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Можливо вибрати тільки один із цих режимів керування"),
        backgroundColor: Colors.orangeAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateToggles(String type, bool value) {
    setState(() {
      if (value == true) {
        // Перевіряємо, чи є хоча б один ІНШИЙ перемикач вже активним до зміни
        bool anotherIsActive = false;

        if (type == 'handle') {
          anotherIsActive = _currentHeaterAuto || _currentAutoAllDay;
        } else if (type == 'night') {
          anotherIsActive = _currentHandleControl || _currentAutoAllDay;
        } else if (type == 'allDay') {
          anotherIsActive = _currentHandleControl || _currentHeaterAuto;
        }

        // Виводимо попередження, тільки якщо ми вимикаємо щось інше заради цього режиму
        if (anotherIsActive) {
          _showExclusiveWarning();
        }

        // Встановлюємо ексклюзивний вибір (Radio button logic)
        _currentHandleControl = (type == 'handle');
        _currentHeaterAuto = (type == 'night');
        _currentAutoAllDay = (type == 'allDay');
      } else {
        // Якщо користувач просто вимикає активний перемикач
        if (type == 'handle') _currentHandleControl = false;
        if (type == 'night') _currentHeaterAuto = false;
        if (type == 'allDay') _currentAutoAllDay = false;
      }
    });
  }

  bool _hasChanges() {
    bool baseChanges = _currentHandleControl != _originalHandleControl ||
        _currentAutoAllDay != _originalAutoAllDay ||
        _logsLimitController.text.trim() != _originalLogsAppLimitValue ||
        _batteryController.text.trim() != _originalBatteryValue;

    if (widget.location == LocationType.dacha) {
      return baseChanges ||
          _currentHeaterAuto != _originalHeaterAuto ||
          _currentSeasonsId != _originalSeasonsId;
    }
    return baseChanges;
  }

  String? _validateSoc(String value) {
    final double? soc = double.tryParse(value);
    if (soc == null) return "Введіть число";
    if (soc < SettingsModel.minSoc || soc > SettingsModel.maxSoc) {
      return "Межі: ${SettingsModel.minSoc}% - ${SettingsModel.maxSoc}%";
    }
    return null;
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathGolego}';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final data = SettingsModel.fromJson(jsonDecode(response.body));
        setState(() {
          _versionBackend = data.versionBackend;
          _originalHandleControl = data.devicesChangeHandleControl;
          _originalAutoAllDay = data.heaterGridOnAutoAllDay;
          _originalHeaterAuto = data.heaterNightAutoOnDachaWinter ?? false;
          _originalSeasonsId = data.seasonsId;
          _originalBatteryValue = data.batteryCriticalNightSocWinter?.toString() ?? "";
          _originalLogsAppLimitValue = data.logsAppLimit.toString();

          _currentHandleControl = _originalHandleControl;
          _currentAutoAllDay = _originalAutoAllDay;
          _currentHeaterAuto = _originalHeaterAuto;
          _currentSeasonsId = _originalSeasonsId;
          _batteryController.text = _originalBatteryValue;
          _logsLimitController.text = _originalLogsAppLimitValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    if (!_hasChanges()) return;

    if (widget.location == LocationType.dacha) {
      final error = _validateSoc(_batteryController.text);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> body = {
      'devicesChangeHandleControl': _currentHandleControl,
      'heaterGridOnAutoAllDay': _currentAutoAllDay,
      'logsAppLimit': int.tryParse(_logsLimitController.text) ?? 100,
    };

    if (widget.location == LocationType.dacha) {
      body['batteryCriticalNightSocWinter'] = double.tryParse(_batteryController.text);
      body['heaterNightAutoOnDachaWinter'] = _currentHeaterAuto;
      body['seasonsId'] = _currentSeasonsId;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}${AppHelper.pathGolego}';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final updatedData = SettingsModel.fromJson(jsonDecode(response.body));
        setState(() {
          // 1. Оновлюємо еталони
          _originalHandleControl = updatedData.devicesChangeHandleControl;
          _originalAutoAllDay = updatedData.heaterGridOnAutoAllDay;

          // 2. ПРИМУСОВА СИНХРОНІЗАЦІЯ ПОТОЧНОГО СТАНУ
          _currentHandleControl = _originalHandleControl;
          _currentAutoAllDay = _originalAutoAllDay;

          if (widget.location == LocationType.dacha) {
            _originalHeaterAuto = updatedData.heaterNightAutoOnDachaWinter ?? false;
            _currentHeaterAuto = _originalHeaterAuto; // Синхронізація

            _originalSeasonsId = updatedData.seasonsId;
            _currentSeasonsId = _originalSeasonsId;   // Синхронізація

            _originalBatteryValue = updatedData.batteryCriticalNightSocWinter?.toString() ?? "";
          }

          _originalLogsAppLimitValue = updatedData.logsAppLimit.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = SettingsModel.fieldLabels;
    final bool isDacha = widget.location == LocationType.dacha;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _buildInfoCard(labels[SettingsModel.keyVersionBackend]!, _versionBackend),
          const SizedBox(height: 12),

          _buildToggleCard(
            title: "Ручне керування",
            subtitle: labels[SettingsModel.keyHandle]!,
            value: _currentHandleControl,
            icon: Icons.touch_app,
            color: Colors.orange.shade800,
            onChanged: (val) => _updateToggles('handle', val),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(isDacha ? Icons.hot_tub : Icons.power, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(isDacha ? "Підігрів полів 1-й поверх" : "Grid on/off auto",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                if (isDacha) ...[
                  Expanded(
                    child: _buildToggleCard(
                      title: "Ніч / Зима",
                      subtitle: labels[SettingsModel.keyHeaterNightAuto]!,
                      value: _currentHeaterAuto,
                      icon: Icons.nightlight_round,
                      color: Colors.blue.shade700,
                      onChanged: (val) => _updateToggles('night', val),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _buildToggleCard(
                    title: (_currentAutoAllDay ? "24/7" : "Only night"),
                    subtitle: (_currentAutoAllDay ? labels[SettingsModel.keyHeaterGridOnAutoAllDay]! : "Підключення Grid(on) тільки вночі"),
                    value: _currentAutoAllDay,
                    icon: _currentAutoAllDay ? Icons.wb_sunny : Icons.nightlight_outlined,
                    color: _currentAutoAllDay ? Colors.orange.shade600 : Colors.green.shade700,
                    onChanged: (val) => _updateToggles('allDay', val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          if (isDacha) ...[
            _buildSeasonDropdown(),
            const SizedBox(height: 12),
          ],

          _buildInputCard(controller: _logsLimitController, label: labels[SettingsModel.keyLogs]!, icon: Icons.list_alt),

          if (isDacha) ...[
            const SizedBox(height: 12),
            _buildInputCard(
              controller: _batteryController,
              label: labels[SettingsModel.keySoc]!,
              icon: Icons.battery_alert,
              isDecimal: true,
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _hasChanges() ? _updateSettings : null,
              icon: const Icon(Icons.save),
              label: const Text("ЗБЕРЕГТИ ЗМІНИ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({required String title, required String subtitle, required bool value, required IconData icon, required Color color, required Function(bool) onChanged}) {
    return Card(
      elevation: 1, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color), const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
            SizedBox(height: 30, child: Switch(value: value, activeColor: color, onChanged: onChanged)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54), maxLines: 2),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
    child: ListTile(dense: true, title: Text(title, style: const TextStyle(fontSize: 12)), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
  );

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDecimal = false
  }) {
    // Визначаємо, чи є помилка валідації для SoC
    String? errorText;
    if (label.contains("SoC") && controller.text.isNotEmpty) {
      errorText = _validateSoc(controller.text);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: errorText != null ? Colors.red : Colors.transparent,
            width: 1
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          decoration: InputDecoration(
            icon: Icon(icon, size: 20, color: errorText != null ? Colors.red : null),
            labelText: label,
            errorText: errorText, // Виводить текст помилки під полем
            labelStyle: const TextStyle(fontSize: 13),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonDropdown() {
    return Card(
      elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<int>(
          value: _currentSeasonsId,
          decoration: const InputDecoration(labelText: "Пора року", border: InputBorder.none),
          items: const [
            DropdownMenuItem(value: 1, child: Text("Зима")),
            DropdownMenuItem(value: 2, child: Text("Весна")),
            DropdownMenuItem(value: 3, child: Text("Літо")),
            DropdownMenuItem(value: 4, child: Text("Осінь")),
          ],
          onChanged: (val) => setState(() => _currentSeasonsId = val),
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