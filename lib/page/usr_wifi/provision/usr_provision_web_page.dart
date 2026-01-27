import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'http/usr_http_client_helper.dart';
import 'usr_provision_web.dart';
import 'http/usr_http_client.dart';

class UsrProvisionWebPage extends StatefulWidget {
  const UsrProvisionWebPage({super.key});

  @override
  State<UsrProvisionWebPage> createState() => _UsrProvisionWebPageState();
}

class _UsrProvisionWebPageState extends State<UsrProvisionWebPage> {
  final _provision = UsrProvisionWeb();
  final _httpClient = UsrHttpClient();

  late final TextEditingController _urlController = TextEditingController(
      text: UsrHttpClientHelper.baseUrlHttp
  );

  String? _detectedMac;
  String _status = "Очікування...";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkModuleConnection();
  }

  Future<void> _checkModuleConnection() async {
    final mac = await _httpClient.getMacAddress();
    if (mac != null) {
      setState(() {
        _detectedMac = mac;
      });
    }
  }

// usr_provision_web_page.dart

  void _onOpen() async {
    // Якщо це Linux, використовуємо примусовий запуск Chrome з авто-авторизацією
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      UsrHttpClientHelper.openModuleInChrome(); // Метод тепер сам знає URL
      setState(() {
        _status = "Запуск Chrome з авто-авторизацією...";
      });
    } else {
      // Для Web залишаємо існуючу логіку, але Chrome може блокувати такий URL з міркувань безпеки
      setState(() { _isLoading = true; });

      // Формуємо URL з авторизацією для передачі в saveAndRestart
      final authUrl = "http://${UsrHttpClientHelper.baseHttpLogin}:${UsrHttpClientHelper.baseHttpPwd}@${UsrHttpClientHelper.baseIpAtHttp}"; //

      final result = await _provision.saveAndRestart(authUrl, "");
      setState(() {
        _isLoading = false;
        _status = result == "opened_in_browser" ? "Відкрито сторінку модуля" : "Помилка: $result";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provisioning (Web/Linux)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHintCard(_provision.getHint()),
            const SizedBox(height: 24),

            if (_detectedMac != null) _buildMacInfo(),

            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                  labelText: "URL модуля",
                  border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading) const CircularProgressIndicator()
            else SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                  onPressed: _onOpen,
                  child: const Text("ВІДКРИТИ ВЕБ-ПАНЕЛЬ")
              ),
            ),
            const SizedBox(height: 20),
            Text(
                "Статус: $_status",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
            ),
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
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withOpacity(0.5)),
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
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue)),
  );
}