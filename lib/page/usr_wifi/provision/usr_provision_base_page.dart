import 'dart:io';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_udp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data_home/data_location_type.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import 'http/usr_http_client.dart';
import 'http/usr_http_client_helper.dart';

abstract class UsrProvisionBasePage<T extends StatefulWidget> extends State<T> {
// Контролери
  final idController = TextEditingController(text: "0");
  final macController = TextEditingController();
  final ssidNameController = TextEditingController();
  final targetSsidController = TextEditingController();
  final passController = TextEditingController();
  final ipAController = TextEditingController(text: UsrHttpClientHelper.backendHostHome);
  final portAController = TextEditingController();
  final ipBController = TextEditingController(text: UsrHttpClientHelper.backendHostKubernet);
  final portBController = TextEditingController();

  // Спільні стани (тепер публічні для віджетів)
  String? detectedMac;
  bool obscurePassword = true;
  String status = "Очікування...";
  bool isLoading = false;
  bool isFormValid = false;

  List<Map<String, dynamic>> networks = []; // Винесено з нащадків
  bool scanSuccess = false;                 // Винесено з нащадків
  String? selectedSsid;                     // Винесено з нащадків
  String selectedPrefix = UsrHttpClientHelper.wifiSsidB2;

  // Інструменти
  final httpClient = UsrHttpClient();

  // АБСТРАКТНИЙ геттер: кожен нащадок підставить свою версію (UDP або Linux)
  UsrProvisionBase get provision;

  // Спільна логіка валідації (щоб не писати в кожному файлі)
  void validateFormInternal() {
    final String idText = idController.text.trim();
    final int? idValue = int.tryParse(idText);

    final bool isValid = targetSsidController.text.isNotEmpty &&
        passController.text.isNotEmpty &&
        // ПЕРЕВІРКА: ID не порожній, є числом і НЕ дорівнює 0
        idText.isNotEmpty && idValue != null && idValue != 0 &&
        ssidNameController.text.isNotEmpty &&
        (detectedMac != null && detectedMac!.isNotEmpty); // Додаткова перевірка MAC

    if (isValid != isFormValid) {
      setState(() => isFormValid = isValid);
    }
  }

  final _provisionUdp = UsrProvisionUdp();

  @override
  void initState() {
    super.initState();

    // 1. Оновлення портів при зміні ID
    _updatePortsInternal();
    idController.addListener(_updatePortsInternal);

    // 2. Синхронізація MAC-адреси (винесено з Linux)
    macController.addListener(() {
      if (!mounted) return;
      final cleanMac = macController.text.trim().toUpperCase();
      if (detectedMac != cleanMac) {
        setState(() => detectedMac = cleanMac);
      }
    });

    // 3. Загальна валідація для ВСІХ полів (винесено з UDP та Linux)
    final controllers = [
      idController,
      macController,
      targetSsidController,
      passController,
      ssidNameController,
      ipAController,
      ipBController,
    ];

    for (var c in controllers) {
      c.addListener(validateFormInternal);
    }
  }

  // Розрахунок портів на основі ID
  void _updatePortsInternal() {
    final int id = int.tryParse(idController.text) ?? 0;
    // Прямий запис у контролери, щоб UI миттєво бачив зміни
    portAController.text = (UsrHttpClientHelper.netPortADef + id).toString();
    portBController.text = (UsrHttpClientHelper.netPortBDef + id).toString();

    // Виклик валідації після оновлення портів
    validateFormInternal();
  }

  // Єдина логіка валідації
// Єдина логіка валідації
//   void validateFormInternal() {
//     final String idText = idController.text.trim();
//     final int? idValue = int.tryParse(idText);
//
//     final bool isValid = targetSsidController.text.isNotEmpty &&
//         passController.text.isNotEmpty &&
//         // ПЕРЕВІРКА: ID не порожній, є числом і НЕ дорівнює 0
//         idText.isNotEmpty && idValue != null && idValue != 0 &&
//         ssidNameController.text.isNotEmpty &&
//         (detectedMac != null && detectedMac!.isNotEmpty); // Додаткова перевірка MAC
//
//     if (isValid != isFormValid) {
//       setState(() => isFormValid = isValid);
//     }
//   }
  // Оновлення SSID модуля при отриманні MAC або зміні префікса
  void updateModuleSsid(String mac) {
    final String cleanMac = mac.replaceAll(':', '');
    final String suffix = cleanMac.length >= 4
        ? cleanMac.substring(cleanMac.length - 4).toUpperCase()
        : "0000";

    setState(() {
      detectedMac = mac.toUpperCase();
      // Синхронізуємо текст у полях
      macController.text = detectedMac!;
      ssidNameController.text = "$selectedPrefix$suffix";
    });
  }
  // Побудова селектора префіксів (B2/A2/Ax)
  Widget buildPrefixSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPrefix,
          isDense: true,
          items: UsrHttpClientHelper.usrPrefixes.map((s) => DropdownMenuItem(
              value: s,
              child: Text(
                  s.replaceFirst("USR-WIFI232-", "").replaceFirst("_", ""),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
              )
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

  // Уніфіковане поле введення
  Widget buildCompactField(TextEditingController ctrl, String label, {
    bool isNumber = false,
    bool readOnly = false,
    bool obscure = false,
    Widget? suffix
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.withValues(alpha: 0.1) : null,
        suffixIcon: suffix,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  // Відображення статусу MAC
  Widget buildMacStatus() {
    if (detectedMac == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Text(
        "MAC: $detectedMac",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void onLoadDefault() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Скинути налаштування?"),
        content: const Text("Модуль повернеться до заводських параметрів і перезавантажиться."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("СКАСУВАТИ")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Скинути", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { isLoading = true; status = "Скидання..."; });
    try {
      await httpClient.postLoadDefaultWtithRestart();
      setState(() {
        status = "Заводські параметри встановлено!";
        detectedMac = null;
        macController.clear();
        validateFormInternal();
      });
    } catch (e) {
      setState(() => status = "Помилка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

// СПІЛЬНИЙ ВІДЖЕТ КНОПОК
  Widget buildActionButtons({required VoidCallback onSave, String saveLabel = "ЗБЕРЕГТИ"}) {
    return Column(
      children: [
        Row(
          children: [
            // Кнопка Factory Reset (спільна для всіх)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (detectedMac != null) ? onLoadDefault : null,
                icon: const Icon(Icons.factory, color: Colors.red, size: 18),
                label: const Text("FACTORY RESET", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: (detectedMac != null) ? Colors.red : Colors.grey),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Основна кнопка (Зберегти або Start Provisioning)
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            // Перевірка ID != 0 вже всередині isFormValid
            onPressed: isFormValid ? onSave : null,
            child: Text(saveLabel),
          ),
        ),
      ],
    );
  }

  void onSaveHttpUpdate(LocationType selectedLocation) async {
    setState(() { isLoading = true; status = "Запис параметрів..."; });

    try {
      // Кожен запит тепер сам "кричить" про помилку, якщо вона є
      await _safeRequest(httpClient.postApStaMode(), "Режим");
      await _safeRequest(httpClient.postApStaOn(), "Активація");
      await _safeRequest(httpClient.postDhcpModeWanAuto(ssidNameController.text) , "Wan name, Ip auto");
      await _safeRequest(httpClient.postApLan(ssidNameController.text), "SSID модуля");

      await _safeRequest(
          httpClient.postApStaOnWithUpdateSsidPwd(targetSsidController.text, passController.text),
          "Пароль WiFi"
      );

      await _safeRequest(
          httpClient.postAppSetting(
              serverIpA: ipAController.text,
              serverPortA: int.tryParse(portAController.text)!,
              serverIpB: ipBController.text,
              serverPortB: int.tryParse(portBController.text)!
          ),
          "Сервери"
      );

      // Рестарт теж через safeRequest або через ваш новий метод з описом
      final restart = await _onUpdateSsidPwdAndRestart();
      if (!restart["success"]) {
        throw "Рестарт: ${restart["message"]}";
      }

      // ТІЛЬКИ ТУТ — запис у базу, бо всі виклики вище пройшли без throw
      final infoBms = await _onUpdateDataUsrWiFiInfo(selectedLocation);

      setState(() {
        isLoading = false;
        status = "Успіх! Налаштування збережено.";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Оновлено: $infoBms"), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      // Сюди потрапить повідомлення на кшталт "Пароль WiFi: error 403"
      setState(() {
        status = "Помилка: $e";
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _onUpdateSsidPwdAndRestart() async {
    String res = "";
    try {
      if (Platform.isLinux) {
        res = await httpClient.postRestart();
      } else {
        res = await _provisionUdp.saveAndRestart(targetSsidController.text, passController.text);
      }

      bool success = Platform.isLinux
          ? (res.toLowerCase().contains("<html") || res.contains("rc=0") || res == "ok")
          : res == "ok";

      return {"success": success, "message": res};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<String> _onUpdateDataUsrWiFiInfo(LocationType selectedLocation) async {
    final info = DataUsrWiFiInfo(
        locationType: selectedLocation,
        id: int.tryParse(idController.text)!,
        bssidMac: detectedMac ?? "",
        ssidWifiBms: ssidNameController.text,
        netIpA: ipAController.text,
        netAPort: int.tryParse(portAController.text)!,
        netIpB: ipBController.text,
        netBPort: int.tryParse(portBController.text)!
    );
    await UsrWiFiInfoStorage().updateOrAddById(info);
    return info.ssidWifiBms;
  }

  @override
  void dispose() {
    idController.dispose();
    macController.dispose(); // Додати
    ssidNameController.dispose();
    targetSsidController.dispose();
    passController.dispose();
    ipAController.dispose();
    portAController.dispose();
    ipBController.dispose();
    portBController.dispose();
    super.dispose();
  }

  bool _isResponseOk(String response) {
    final res = response.toLowerCase();
    // Модуль вважає успіхом +ok, ok, або повернення HTML сторінки (для Linux)
    return res.contains("+ok") || res == "ok" || res.contains("<html") || res.contains("rc=0");
  }

  Future<void> _safeRequest(Future<String> request, String errorLabel) async {
    final res = await request;
    if (!_isResponseOk(res)) {
      // Передаємо і ваш ярлик, і те, що реально відповів модуль
      throw "$errorLabel: $res";
    }
  }

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }
}