import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import 'http/usr_http_client.dart';
import 'http/usr_http_client_helper.dart';
import '../../data_home/data_location_type.dart';


class UsrProvisionWebPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionWebPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionWebPage> createState() => _UsrProvisionWebPageState();
}

class _UsrProvisionWebPageState extends UsrProvisionBasePage<UsrProvisionWebPage> {
  final _httpClient = UsrHttpClient();
  final TextEditingController _macController = TextEditingController();

  List<Map<String, dynamic>> _networks = [];
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _macController.addListener(() {
      setState(() {
        detectedMac = _macController.text.trim().toUpperCase();
      });
      // ДОДАЙТЕ ЦЕ: викликає перевірку кнопки "Зберегти"
      validateFormInternal();
    });
    _onRefresh();
  }

  @override
  void updateModuleSsid(String mac) {
    // 1. Виконуємо базову логіку (оновлення SSID модуля)
    super.updateModuleSsid(mac);

    // 2. Синхронізуємо текст у полі вводу з отриманим MAC
    if (_macController.text != mac) {
      _macController.text = mac;
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      status = "Отримання даних...";

      // Чистимо ВСЕ: змінні та контролери
      detectedMac = null;
      macController.clear();
      targetSsidController.clear();
      passController.clear();
      // Якщо хочеш скидати і назву модуля:
      ssidNameController.clear();
    });

    try {
      final mac = await _httpClient.getMacAddress();
      if (mac != null) {
        updateModuleSsid(mac); // Це знову заповнить контролери новими даними
      }
    } catch (e) {
      setState(() => status = "Помилка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onOpenWebPanel() async {
    final authUrl = "http://${UsrHttpClientHelper.baseHttpLogin}:${UsrHttpClientHelper.baseHttpPwd}@${UsrHttpClientHelper.baseIpAtHttp}";

    if (Platform.isLinux) {
      try {
        // Намагаємося запустити google-chrome або google-chrome-stable
        // Передаємо URL як аргумент
        await Process.run('google-chrome', [authUrl]);

        setState(() => status = "Chrome відкрито (Linux)");
      } catch (e) {
        // Якщо команда 'google-chrome' не знайдена, пробуємо 'chromium'
        try {
          await Process.run('chromium', [authUrl]);
          setState(() => status = "Chromium відкрито (Linux)");
        } catch (e) {
          setState(() => status = "Помилка: Chrome не встановлено");
        }
      }
    } else {
      // Код для інших платформ (Android/iOS), який ми обговорювали раніше
    }
  }

  // Метод тільки для збереження в базу (з повною перевіркою)
  // void _onSaveToDatabase() async {
  //   final int id = int.tryParse(idController.text) ?? 9;
  //
  //   if (detectedMac == null || detectedMac!.isEmpty) {
  //     setState(() => status = "Помилка: MAC адресу не вказано!");
  //     return;
  //   }
  //
  //   final wifiInfo = DataUsrWiFiInfo(
  //     id: id,
  //     locationType: widget.selectedLocation,
  //     bssidMac: detectedMac!, // Тут буде або отриманий через HTTP, або введений вручну
  //     ssidWifiBms: ssidNameController.text,
  //     netIpA: ipAController.text,
  //     netAPort: int.tryParse(portAController.text) ?? 0,
  //     netIpB: ipBController.text,
  //     netBPort: int.tryParse(portBController.text) ?? 0,
  //   );
  //
  //   await _infoStorage.updateOrAddById(wifiInfo);
  //   setState(() => status = "Дані успішно збережені в базу");
  // }

  @override
  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this); // Передаємо 'this' (State)

    return Scaffold(
      appBar: AppBar(
        title: const Text("Web Configuration"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh)],
      ),
      body: widgets.buildCommonForm(
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "ЗБЕРЕГТИ ТА РЕСТАРТ",
        ),
      ),
    );
  }

  // Метод для Dropdown списку мереж
  Widget _buildNetworkSelector() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      value: _selectedSsid,
      decoration: const InputDecoration(labelText: "Available Networks", border: OutlineInputBorder(), isDense: true),
      items: _networks.map((n) => DropdownMenuItem<String>(
          value: n['ssid'].toString(),
          child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12))
      )).toList(),
      onChanged: (v) {
        setState(() {
          _selectedSsid = v;
          if (v != null) targetSsidController.text = v;
        });
      },
    );
  }

  Widget _buildHintCard(String hint) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue)),
  );
}