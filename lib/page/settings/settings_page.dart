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

  // Поточні значення в UI
  bool _currentHandleControl = false;
  final TextEditingController _batteryController = TextEditingController();
  final TextEditingController _logsLimitController = TextEditingController(); // Додано

  // Значення, отримані з сервера (для порівняння)
  bool _originalHandleControl = false;
  String _originalBatteryValue = "";
  String _originalLogsDachaLimitValue = ""; // Додано

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    // Слухаємо зміни в полі введення, щоб вчасно оновлювати стан кнопки
    _batteryController.addListener(() => setState(() {}));
    _logsLimitController.addListener(() => setState(() {})); // Додано
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _resetAndFetch();
    }
  }

  void _resetAndFetch() {
    setState(() {
      _isLoading = true;
      _batteryController.clear();
      _logsLimitController.clear(); // Додано
    });
    _fetchSettings();
  }

  // Перевірка: чи відрізняються поточні дані від тих, що прийшли з сервера
  bool _hasChanges() {
    bool handleControlChanged = _currentHandleControl != _originalHandleControl;

    bool batteryChanged = false;
    if (widget.location == LocationType.dacha) {
      batteryChanged = _batteryController.text != _originalBatteryValue;
    }

    bool dachaLimitChanged = false; // Додано
    if (widget.location == LocationType.dacha) {
      dachaLimitChanged = _logsLimitController.text != _originalLogsDachaLimitValue;
    }

    return handleControlChanged || batteryChanged || dachaLimitChanged;
  }

  String _getApiUrl() {
    String path = widget.location == LocationType.dacha
        ? AppHelper.pathDacha
        : AppHelper.pathGolego;
    return '${ApiServerHelper.backendUrl}${AppHelper.apiPathSettings}$path';
  }

  Future<void> _fetchSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(_getApiUrl()),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final data = SettingsModel.fromJson(jsonDecode(response.body));
        setState(() {
          // Зберігаємо оригінал
          _originalHandleControl = data.devicesChangeHandleControl;
          _originalBatteryValue = data.batteryCriticalNightSocWinter?.toString() ?? "";
          _originalLogsDachaLimitValue = data.logsDachaLimit?.toString() ?? ""; // Додано

          // Встановлюємо поточні значення
          _currentHandleControl = _originalHandleControl;
          _batteryController.text = _originalBatteryValue;
          _logsLimitController.text = _originalLogsDachaLimitValue; // Додано

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Помилка завантаження: $e")),
      );
    }
  }

  Future<void> _updateSettings() async {
    if (!_hasChanges()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final body = SettingsModel(
        devicesChangeHandleControl: _currentHandleControl,
        batteryCriticalNightSocWinter: widget.location == LocationType.dacha
            ? double.tryParse(_batteryController.text)
            : null,
        logsDachaLimit: widget.location == LocationType.dacha
            ? int.tryParse(_logsLimitController.text)
            : null, // Додано
      );

      final response = await http.post(
        Uri.parse(_getApiUrl()),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Налаштування збережено")),
        );
        _fetchSettings(); // Перезавантажуємо, щоб оновити "original" значення
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Не вдалося зберегти: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canSave = _hasChanges() && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text("Налаштування: ${widget.location == LocationType.dacha ? 'Дача' : 'Golego'}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetAndFetch)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: SwitchListTile(
                title: const Text("Ручне керування пристроями"),
                value: _currentHandleControl,
                onChanged: (val) => setState(() => _currentHandleControl = val),
              ),
            ),
            if (widget.location == LocationType.dacha) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _batteryController,
                    decoration: const InputDecoration(
                      labelText: "Критичний рівень заряду (SoC %)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Додано
              Card( // Додано
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _logsLimitController,
                    decoration: const InputDecoration(
                      labelText: "Кількість рядків логів Dacha",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canSave ? _updateSettings : null,
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                label: const Text("ЗБЕРЕГТИ"),
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
    _logsLimitController.dispose(); // Додано
    super.dispose();
  }
}