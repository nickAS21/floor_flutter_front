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

  bool _currentHandleControl = false;
  final TextEditingController _batteryController = TextEditingController();
  final TextEditingController _logsLimitController = TextEditingController();

  bool _originalHandleControl = false;
  String _originalBatteryValue = "";
  String _originalLogsAppLimitValue = "";

  @override
  void initState() {
    super.initState();
    _fetchData(); // Твоя назва методу
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
    return _currentHandleControl != _originalHandleControl ||
        _batteryController.text != _originalBatteryValue ||
        _logsLimitController.text != _originalLogsAppLimitValue;
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    // Твій стандарт формування URL
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
          _originalHandleControl = data.devicesChangeHandleControl;
          _originalBatteryValue = data.batteryCriticalNightSocWinter?.toString() ?? "";
          _originalLogsAppLimitValue = data.logsAppLimit.toString();

          _currentHandleControl = _originalHandleControl;
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
        }),
      );

      if (response.statusCode == 200) {
        final updatedData = SettingsModel.fromJson(jsonDecode(response.body));
        List<String> failedFields = [];

        setState(() {
          if (updatedData.devicesChangeHandleControl == sentHandle) {
            _originalHandleControl = updatedData.devicesChangeHandleControl;
          } else {
            failedFields.add(SettingsModel.fieldLabels[SettingsModel.keyHandle]!);
          }

          if (updatedData.logsAppLimit == sentLimit) {
            _originalLogsAppLimitValue = updatedData.logsAppLimit.toString();
          } else {
            failedFields.add(SettingsModel.fieldLabels[SettingsModel.keyLogs]!);
          }

          if (widget.location == LocationType.dacha) {
            if (updatedData.batteryCriticalNightSocWinter == sentBattery) {
              _originalBatteryValue = updatedData.batteryCriticalNightSocWinter?.toString() ?? "";
            } else {
              failedFields.add(SettingsModel.fieldLabels[SettingsModel.keySoc]!);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Налаштування: ${widget.location == LocationType.dacha ? 'Дача' : 'Golego'}",
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blueGrey.shade600),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: SwitchListTile(
                title: Text(labels[SettingsModel.keyHandle]!, style: const TextStyle(fontSize: 14)),
                value: _currentHandleControl,
                onChanged: (val) => setState(() => _currentHandleControl = val),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _logsLimitController,
                  decoration: InputDecoration(
                    labelText: labels[SettingsModel.keyLogs],
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            if (widget.location == LocationType.dacha) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _batteryController,
                    decoration: InputDecoration(
                      labelText: labels[SettingsModel.keySoc],
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canSave ? _updateSettings : null,
                icon: const Icon(Icons.save_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                label: const Text("ЗБЕРЕГТИ", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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