import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_wifi_232_provision_udp.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/app_helper.dart';
import '../../data_home/data_location_type.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import 'client/http/usr_wifi_232_http_client.dart';
import 'client/usr_client.dart';
import 'client/http/usr_wifi_232_http_client_helper.dart';
import 'client/usr_client_factory.dart';

abstract class UsrProvisionBasePage<T extends StatefulWidget> extends State<T> {
  // Контролери
  final idController = TextEditingController(text: "0");
  final macController = TextEditingController();
  final ssidNameController = TextEditingController();
  final targetSsidController = TextEditingController();
  final passController = TextEditingController();
  final ipAController = TextEditingController(text: AppHelper.backendHostHome);
  final portAController = TextEditingController();
  final ipBController = TextEditingController(text: AppHelper.backendHostKubernet);
  final portBController = TextEditingController();
  final bitrateController = TextEditingController(text: "2400");
  bool keepTargetSettings = true;

  // Спільні стани
  String? detectedMac;
  bool obscurePassword = true;
  String status = "Очікування...";
  bool isLoading = false;
  bool isFormValid = false;

  List<Map<String, dynamic>> networks = [];
  bool scanSuccess = false;
  String? selectedSsid;
  String selectedPrefix = UsrWiFi232HttpClientHelper.wifiSsidB2;

  // Інструменти
  late UsrClient httpClient;
  final _provisionUdp = UsrWiFi232ProvisionUdp();

  // АБСТРАКТНИЙ геттер
  UsrProvisionBase get provision;

  @override
  void initState() {
    super.initState();

    httpClient = UsrWiFi232HttpClient();
// ВІДНОВЛЕНО: Тепер дані реально завантажуються при старті
    _loadPreferences().then((_) => _initDevice());

    _updatePortsInternal();

    // ОСЬ ЦЕЙ СПИСОК «ОЖИВИТЬ» КНОПКУ
    final fields = [
      idController,
      targetSsidController,
      passController,
      ssidNameController,
      ipAController,
      ipBController,
      bitrateController
    ];

    for (var controller in fields) {
      // Слухаємо кожну зміну тексту
      controller.addListener(() {
        if (controller == idController) _updatePortsInternal();
        validateFormInternal();
      });
    }
  }

  Future<void> _initDevice() async {
    // 1. Скидання старих даних перед пошуком нового пристрою
    setState(() {
      detectedMac = null;
      macController.clear();
      status = "Пошук пристрою...";
    });

    // Discovery оновить клієнт на правильний (наприклад, S100), коли отримає відповідь
    final discoveredClient = await UsrClientFactory.discoverDevice();
    setState(() {
      httpClient = discoveredClient;
    });

    final mac = await httpClient.getMacAddress();
    if (mac != null) {
      updateModuleSsid(mac);
    } else {
      setState(() => status = "Пристрій не знайдено");
    }
    validateFormInternal();
  }

  void _updatePortsInternal() {
    final int id = int.tryParse(idController.text) ?? 0;
    portAController.text = (UsrWiFi232HttpClientHelper.netPortADef + id).toString();
    portBController.text = (UsrWiFi232HttpClientHelper.netPortBDef + id).toString();
  }

  void validateFormInternal() {
    final String idText = idController.text.trim();
    final int? idValue = int.tryParse(idText);

    final bool isValid = targetSsidController.text.isNotEmpty &&
        passController.text.isNotEmpty &&
        idText.isNotEmpty &&
        idValue != null && idValue != 0 && // Перевірка на нуль є
        ssidNameController.text.isNotEmpty &&
        ipAController.text.isNotEmpty &&   // ДОДАНО: перевірка IP A
        ipBController.text.isNotEmpty &&   // ДОДАНО: перевірка IP B
        bitrateController.text.isNotEmpty && // ДОДАНО: Валідація BitRate
        (detectedMac != null && detectedMac!.isNotEmpty);

    if (isValid != isFormValid) {
      setState(() => isFormValid = isValid);
    }
  }

  void updateModuleSsid(String mac) {
    final String cleanMac = mac.replaceAll(':', '');
    final String suffix = cleanMac.length >= 4
        ? cleanMac.substring(cleanMac.length - 4).toUpperCase()
        : "0000";

    setState(() {
      detectedMac = mac.toUpperCase();
      macController.text = detectedMac!;
      ssidNameController.text = "$selectedPrefix$suffix";

      // ЛОГІКА: якщо false — очищаємо, якщо true — не трогаємо
      if (!keepTargetSettings) {
        targetSsidController.clear();
        passController.clear();
      }
    });
  }

  // ТОЙ САМИЙ МЕТОД, ЯКИЙ ПОВЕРНУЛИ
  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
    _savePreferences(); // Зберігаємо вибір негайно
  }

  void toggleKeepSettings(bool? value) {
    setState(() {
      keepTargetSettings = value ?? false;
    });
    _savePreferences(); // Зберігаємо вибір негайно
  }

  // --- UI Методи ---
  Widget buildPrefixSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPrefix, isDense: true,
          items: UsrWiFi232HttpClientHelper.usrPrefixes.map((s) => DropdownMenuItem(
              value: s, child: Text(s.replaceFirst("USR-WIFI232-", "").replaceFirst("_", ""), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => selectedPrefix = v);
              if (detectedMac != null) updateModuleSsid(detectedMac!);
            }
          },
        ),
      ),
    );
  }

  Widget buildCompactField(TextEditingController ctrl, String label, {bool isNumber = false, bool readOnly = false, bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl, readOnly: readOnly, obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label, isDense: true, filled: readOnly,
        fillColor: readOnly ? Colors.grey.withAlpha(25) : null,
        suffixIcon: suffix, border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  Widget buildMacStatus() {
    if (detectedMac == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withAlpha(75))),
      child: Text("MAC: $detectedMac", textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ОСНОВНИЙ МЕТОД ЗБЕРЕЖЕННЯ
  void onSaveHttpUpdate(LocationType selectedLocation) async {
    setState(() { isLoading = true; status = "Запис параметрів..."; });
    try {
      await httpClient.onSaveUpdate(
        targetSsid: targetSsidController.text,
        targetPass: passController.text,
        moduleSsid: ssidNameController.text,
        ipA: ipAController.text,
        portA: int.tryParse(portAController.text) ?? 0,
        ipB: ipBController.text,
        portB: int.tryParse(portBController.text) ?? 0,
        bitrate: int.tryParse(bitrateController.text) ?? 2400,
      );

      final infoBms = await _onUpdateDataUsrWiFiInfo(selectedLocation);
      setState(() { isLoading = false; status = "Успіх! Налаштування збережено."; });
      // ВІДНОВЛЕНО: Зберігаємо останній успішний IP та прапорець
      await _savePreferences();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Оновлено: $infoBms"), backgroundColor: Colors.green));
    } catch (e) {
      setState(() { status = "Помилка: $e"; isLoading = false; });
    }
  }

  void onLoadDefault() async {
    setState(() { isLoading = true; status = "Скидання..."; });
    try {
      await httpClient.postRestart();
      setState(() => status = "Модуль перезавантажується...");
    } catch (e) {
      setState(() => status = "Помилка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _onUpdateDataUsrWiFiInfo(LocationType selectedLocation) async {
    final info = DataUsrWiFiInfo(
        locationType: selectedLocation, id: int.tryParse(idController.text)!, bssidMac: detectedMac ?? "",
        ssidWifiBms: ssidNameController.text, netIpA: ipAController.text, netAPort: int.tryParse(portAController.text)!,
        netIpB: ipBController.text, netBPort: int.tryParse(portBController.text)!
    );
    await UsrWiFiInfoStorage().updateOrAddById(info);
    return info.ssidWifiBms;
  }

  @override
  void dispose() {
    idController.dispose(); macController.dispose(); ssidNameController.dispose();
    targetSsidController.dispose(); passController.dispose();
    ipAController.dispose(); portAController.dispose(); ipBController.dispose(); portBController.dispose();
    bitrateController.dispose();
    super.dispose();
  }
// lib/page/usr_wifi/provision/usr_provision_base_page.dart

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Важливо: обгортаємо в setState, щоб UI оновився
    setState(() {
      keepTargetSettings = prefs.getBool('keepTargetSettings') ?? true;

      // Завантажуємо IP, якщо вони були збережені
      String? savedIpA = prefs.getString('ipA');
      if (savedIpA != null) ipAController.text = savedIpA;

      String? savedIpB = prefs.getString('ipB');
      if (savedIpB != null) ipBController.text = savedIpB;

      // Якщо галочка активна, повертаємо SSID та Pass
      if (keepTargetSettings) {
        targetSsidController.text = prefs.getString('targetSsid') ?? "";
        passController.text = prefs.getString('targetPass') ?? "";
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepTargetSettings', keepTargetSettings);
    await prefs.setString('ipA', ipAController.text);
    await prefs.setString('ipB', ipBController.text);

    // Завжди зберігаємо поточні дані, щоб вони були доступні при наступному старті
    await prefs.setString('targetSsid', targetSsidController.text);
    await prefs.setString('targetPass', passController.text);
  }
}