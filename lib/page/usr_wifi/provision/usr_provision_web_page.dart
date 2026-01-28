import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'http/usr_http_client_helper.dart';
import 'usr_provision_web.dart';
import 'http/usr_http_client.dart';
import '../../data_home/data_location_type.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';

class UsrProvisionWebPage extends StatefulWidget {
  final LocationType selectedLocation; // Додано параметр від батька

  const UsrProvisionWebPage({
    super.key,
    required this.selectedLocation, // Обов'язковий параметр
  });

  @override
  State<UsrProvisionWebPage> createState() => _UsrProvisionWebPageState();
}

class _UsrProvisionWebPageState extends State<UsrProvisionWebPage> {
  final _provision = UsrProvisionWeb();
  final _httpClient = UsrHttpClient();
  final _infoStorage = UsrWiFiInfoStorage(); // Для локального збереження

  late final TextEditingController _urlController = TextEditingController(
      text: UsrHttpClientHelper.baseUrlHttp
  );

  // Контролери для даних (як у UDP версії)
  final _idController = TextEditingController(text: "9");
  late final TextEditingController _ipAController;

  String? _detectedMac;
  String _status = "Очікування...";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ініціалізуємо IP відповідно до локації
    _ipAController = TextEditingController(
      text: widget.selectedLocation == LocationType.golego
          ? UsrHttpClientHelper.backendHostKubernet
          : UsrHttpClientHelper.backendHostHome,
    );
    _checkModuleConnection();
  }

  // Слідкуємо за зміною локації у верхньому контейнері
  @override
  void didUpdateWidget(UsrProvisionWebPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      setState(() {
        _ipAController.text = widget.selectedLocation == LocationType.golego
            ? UsrHttpClientHelper.backendHostKubernet
            : UsrHttpClientHelper.backendHostHome;
      });
    }
  }

  Future<void> _checkModuleConnection() async {
    final mac = await _httpClient.getMacAddress();
    if (mac != null) {
      setState(() { _detectedMac = mac; });
    }
  }

  // НОВИЙ МЕТОД: Збереження локальної інфо (аналог UDP)
  void _onSaveLocalInfo() async {
    final int id = int.tryParse(_idController.text) ?? 9;

    final wifiInfo = DataUsrWiFiInfo(
      id: id,
      locationType: widget.selectedLocation, // З верхнього фільтра
      bssidMac: _detectedMac ?? '',
      ssidWifiBms: "WEB_CONFIGURED", // Або зчитати з модуля
      netIpA: _ipAController.text,
      netAPort: 18890 + id,
      netIpB: "0.0.0.0", // Web mode не завжди дає ці дані одразу
      netBPort: 8890 + id,
    );

    await _infoStorage.saveInfo(wifiInfo); // Зберігаємо в SharedPreferences
    setState(() { _status = "Інфо збережено для ${widget.selectedLocation.label}"; });
  }

  void _onOpen() async {
    _onSaveLocalInfo(); // Зберігаємо інфу при відкритті панелі

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      UsrHttpClientHelper.openModuleInChrome();
      setState(() { _status = "Запуск Chrome..."; });
    } else {
      setState(() { _isLoading = true; });
      final authUrl = "http://${UsrHttpClientHelper.baseHttpLogin}:${UsrHttpClientHelper.baseHttpPwd}@${UsrHttpClientHelper.baseIpAtHttp}";
      final result = await _provision.saveAndRestart(authUrl, "");
      setState(() {
        _isLoading = false;
        _status = result == "opened_in_browser" ? "Відкрито сторінку" : "Помилка: $result";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Прибираємо AppBar, бо він є у батьківському UsrWifiPage
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHintCard("Platform: ${defaultTargetPlatform.name} | Location: ${widget.selectedLocation.label}"),
            const SizedBox(height: 16),
            if (_detectedMac != null) _buildMacInfo(),

            // Додаємо поля ID та IP як у UDP версії для синхронності
            Row(
              children: [
                SizedBox(width: 60, child: TextField(controller: _idController, decoration: const InputDecoration(labelText: "ID", border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _ipAController, decoration: const InputDecoration(labelText: "Server IP A", border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: "URL модуля", border: OutlineInputBorder())),
            const SizedBox(height: 24),

            if (_isLoading) const CircularProgressIndicator()
            else SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                  onPressed: _onOpen,
                  child: const Text("ВІДКРИТИ ПАНЕЛЬ ТА ЗБЕРЕГТИ ІНФО")
              ),
            ),
            const SizedBox(height: 20),
            Text("Статус: $_status", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildMacInfo() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: Colors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
    ),
    child: Text(
      "З'єднано з пристроєм: $_detectedMac",
      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildHintCard(String hint) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue)),
  );
}