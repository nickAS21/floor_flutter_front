import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/app_helper.dart';
import '../../data_home/data_location_type.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import 'client/http/usr_wifi_232_http_client.dart';
import 'client/usr_client.dart';
import 'client/usr_client_factory.dart';
import 'client/usr_client_device_type.dart';
import 'client/usr_client_helper.dart';

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
  final bitrateController = TextEditingController(text: UsrProvisionHelper.bitrateDef.toString());
  bool keepTargetSettings = true;

  // Спільні стани
  // String? detectedMac;
  bool obscurePassword = true;
  String status = "Очікування...";
  bool isLoading = false;
  bool isFormValid = false;

  List<Map<String, dynamic>> networks = [];
  bool scanSuccess = false;
  String? selectedSsid;
  String selectedPrefix = UsrClientDeviceType.b2.prefix;

  // Інструменти
  late UsrClient httpClient;

  // АБСТРАКТНИЙ геттер
  UsrProvisionBase get provision;

  Future<bool> onScan();

  @override
  void initState() {
    super.initState();
    httpClient = UsrWiFi232HttpClient();

    // Запускаємо єдиний ланцюжок і більше нічого не чіпаємо
    runSetupSequence(null);

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

  Future<void> runSetupSequence(String? ssid) async {
    if (!mounted || isLoading) return;
    if (!mounted) return;
    resetProvisioningState(true, "Розвідка пристрою...");

    try {
      // КРОК 2: Завантажуємо налаштування (IP, Порти)
      await _loadPreferences();

      // КРОК 3: Викликаємо розвідку заліза (шукаємо MAC)
      debugPrint("КРОК 3.1: Викликаємо розвідку заліза (шукаємо MAC)");
      await initDevice();
      String? mac = httpClient.mac;
      // 2. Отримуємо свіжий MAC
      if (mac != null) {
        updateModuleSsid(mac);
        if (ssid.isBlank) {
          ssid = await provision.getActiveSsid();
        }
        if (ssid.isNotBlank) {
          httpClient.ssidName = ssid;
          debugPrint("Активний SSID встановлено: $ssid");
        }
      }
      debugPrint("КРОК 3.2: MAC: $mac");

      // КРОК 4: Викликаємо сканування мереж
      debugPrint("КРОК 4: Викликаємо сканування мереж");
      bool isScanOk = await onScan();

      if (mounted) {
        setState(() {
          isLoading = false; // Остаточно гасимо колесо
          if (isScanOk) {
            status = "Готово. Знайдено ${networks.length} мереж";
          } else {
            status = "Пристрій знайдено, але список WiFi порожній";
          }
        });

        // Перевіряємо кнопку збереження ще раз
        validateFormInternal();
      }

    } catch (e) {
      // Якщо впало на старті — гасимо колесо тут
      if (mounted) setState(() => isLoading = false);
    }
    // Зверни увагу: тут немає finally з isLoading = false,
    // бо за вимкнення колеса тепер відповідає фінальний метод onScan
  }

  Future<void> initDevice() async {
    if (!mounted) return;
    // 2. КРИТИЧНО: Чекаємо 100 мілісекунд.
    // Це звільняє потік, і Flutter встигає намалювати колесо ПЕРЕД мережевим запитом.
    await Future(() {});

    try {
      // Фабрика сама робить всю брудну роботу: шукає, пінгує, отримує MAC
      httpClient = await UsrClientFactory.discoverDevice();

      if (mounted && httpClient.mac != null) {
        // Якщо MAC є — ми готові
        setState(() => status = "Пристрій готовий");
      } else {
        // Якщо MAC немає — показуємо, що пристрій не знайдено (режим Linux скан)
        if (mounted) setState(() => status = "Пристрій не знайдено в мережі");
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка зв'язку: $e");
    } finally {
      if (mounted) validateFormInternal();
    }
  }

  void _updatePortsInternal() {
    final int id = int.tryParse(idController.text) ?? 0;
    portAController.text = (UsrClientHelper.netPortADef + id).toString();
    portBController.text = (UsrClientHelper.netPortBDef + id).toString();
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
        (httpClient.mac != null && httpClient.mac!.isNotEmpty);

    if (isValid != isFormValid) {
      setState(() => isFormValid = isValid);
    }
  }

  void updateModuleSsid(String? mac) {
    if (mac == null) return;

    final String cleanMac = mac.replaceAll(':', '');
    final String suffix = cleanMac.length >= 4
        ? cleanMac.substring(cleanMac.length - 4).toUpperCase()
        : "0000";

    setState(() {
      // Встановлюємо в контролер для візуалізації
      macController.text = mac.toUpperCase();
      // detectedMac = mac.toUpperCase();
      ssidNameController.text = "$selectedPrefix$suffix";
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
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPrefix,
          isDense: true,
          items: UsrClientDeviceType.values.map((device) => DropdownMenuItem(
              value: device.prefix,
              child: Text(
                  device.label, // Відображаємо "B2", "A2" або "S100"
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
              )
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                selectedPrefix = v; // 1. Оновлюємо вибраний префікс

                // 2. Отримуємо актуальний MAC (з детектора або з клієнта)
                // final currentMac = detectedMac ?? httpClient.mac;

                if (httpClient.mac.isNotBlank) {
                  // Якщо MAC є — перераховуємо повний SSID (префікс + суфікс)
                  updateModuleSsid(httpClient.mac);
                } else {
                  // Якщо MAC ще немає — просто записуємо префікс у поле,
                  // щоб юзер бачив, що тип змінився
                  ssidNameController.text = v;
                }
              });
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

  // Widget buildMacStatus() {
  //   if (detectedMac == null) return const SizedBox.shrink();
  //   return Container(
  //     width: double.infinity, padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(color: Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withAlpha(75))),
  //     child: Text("MAC: $detectedMac", textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
  //   );
  // }

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
        bitrate: int.tryParse(bitrateController.text) ?? UsrProvisionHelper.bitrateDef,
      );

      final infoBms = await _onUpdateDataUsrWiFiInfo(selectedLocation);
      setState(() { isLoading = false; status = "Успіх! Налаштування збережено."; });
      // ВІДНОВЛЕНО: Зберігаємо останній успішний IP та прапорець
      await _savePreferences();
      if (mounted) {
        // Перевіряємо, чи це S100 через префікс або тип клієнта
        if (selectedPrefix.contains("S100")) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Оновлено, перепідключення нової мережі - вручну: $infoBms"), backgroundColor: Colors.green)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Оновлено: $infoBms"), backgroundColor: Colors.green)
          );
        }
        resetProvisioningState(false, "Оновлення пристрою. завершено");
      }
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
        locationType: selectedLocation, id: int.tryParse(idController.text)!, bssidMac: httpClient.mac ?? "",
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

      String? savedBitrate = prefs.getString('bitrate');
      if (savedBitrate != null) bitrateController.text = savedBitrate;

    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepTargetSettings', keepTargetSettings);
    await prefs.setString('ipA', ipAController.text);
    await prefs.setString('ipB', ipBController.text);
    await prefs.setString('bitrate', bitrateController.text);
  }

  void resetProvisioningState(bool isStart, String statusStr) {
    setState(() {
      // 1. Ідентифікатори - завжди в 0/null
      idController.text = "0";

      // 2. Стан сканування
      networks = [];
      scanSuccess = false;
      selectedSsid = null;
      macController.clear();
      isLoading = isStart;

      // 3. Поля, що залежать від keepTargetSettings.  Якщо true - нічого не робимо, залишаємо значення з контролерів
      if (!keepTargetSettings) {
        targetSsidController.clear();
        passController.clear();
        bitrateController.text = UsrProvisionHelper.bitrateDef.toString(); // Скидаємо до заводського для BMS
      }

      // 4. Скидання статусу та префікса модуля
      ssidNameController.text = selectedPrefix;
      status = statusStr;
    });
  }
}