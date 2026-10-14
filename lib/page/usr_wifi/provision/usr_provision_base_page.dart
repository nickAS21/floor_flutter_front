import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/app_helper.dart';
import '../../data_home/data_location_type.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import 'client/http/usr_s100_http_client.dart';
import 'client/http/usr_wifi_232_http_client.dart';
import 'client/usr_client.dart';
import 'client/usr_client_factory.dart';
import 'client/usr_client_node_type.dart';
import 'client/usr_client_helper.dart';
import 'client/connect_interface_type.dart';

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
  ConnectInterfaceType selectedUartType = ConnectInterfaceType.rxTx;

  // Спільні стани
  bool obscurePassword = true;
  String status = "Очікування...";
  bool isLoading = false;
  bool isFormValid = false;

  List<Map<String, dynamic>> networks = [];
  bool scanSuccess = false;
  String? selectedSsid;
  String selectedPrefix = UsrClientNodeType.a2.prefix;

  // Інструменти (Клієнт зв'язку з Node-вузлом)
  late UsrClient nodeClient;

  // АБСТРАКТНІ геттери та методи
  UsrProvisionBase get provision;
  Future<bool> onScanNode();

  /// Віртуальні методи для BLE-сканування (перевизначаються на Linux / Android)
  Future<void> startBleScanNode() async {}
  Future<void> stopBleScanNode() async {}

  @override
  void initState() {
    super.initState();
    nodeClient = UsrWiFi232HttpClient();

    runSetupSequence(null);

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
      controller.addListener(() {
        if (controller == idController) _updatePortsInternal();
        validateFormInternal();
      });
    }
  }

  Future<void> runSetupSequence(String? ssid) async {
    if (!mounted || isLoading) return;
    resetProvisioningState(true, "Розвідка пристрою...");

    try {
      await _loadPreferences();

      debugPrint("КРОК 3.1: Викликаємо розвідку заліза/node (шукаємо MAC)");
      await initNodeClient();
      String? mac = nodeClient.mac;

      if (mac.isNotBlank) {
        updateModuleSsid(mac);
        if (ssid.isBlank) {
          ssid = await provision.getActiveSsid();
        }
        if (ssid.isNotBlank) {
          nodeClient.ssidName = ssid;
          debugPrint("Активний SSID node встановлено: $ssid");
        }
      }
      debugPrint("КРОК 3.2: MAC: $mac");

      debugPrint("КРОК 4: Викликаємо сканування WiFi мереж node");
      bool isScanOk = await onScanNode();

      if (mounted) {
        setState(() {
          isLoading = false;
          if (isScanOk) {
            status = "Готово. Знайдено ${networks.length} WiFi мереж через node";
          } else {
            if (mac.isNotBlank) {
              status = "Node знайдено, але список WiFi порожній";
            } else {
              status = "Node не знайдено...";
            }
          }
        });

        validateFormInternal();
      }

    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> initNodeClient() async {
    if (!mounted) return;
    await Future(() {});

    try {
      nodeClient = await UsrClientFactory.discoverDevice();

      if (mounted && nodeClient.mac != null) {
        setState(() => status = "Пристрій готовий");
      } else {
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
        idValue != null && idValue != 0 &&
        ssidNameController.text.isNotEmpty &&
        ipAController.text.isNotEmpty &&
        ipBController.text.isNotEmpty &&
        bitrateController.text.isNotEmpty &&
        (nodeClient.mac != null && nodeClient.mac!.isNotEmpty);

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
      if (nodeClient is UsrS100HttpClient) {
        selectedPrefix = UsrClientNodeType.s100.prefix;
      } else if (selectedPrefix == UsrClientNodeType.s100.prefix) {
        selectedPrefix = UsrClientNodeType.b2.prefix;
      }
      macController.text = mac.toUpperCase();
      ssidNameController.text = "$selectedPrefix$suffix";
    });
  }

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
    _savePreferences();
  }

  void toggleKeepSettings(bool? value) {
    setState(() {
      keepTargetSettings = value ?? false;
    });
    _savePreferences();
  }

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
          items: UsrClientNodeType.values.map((device) => DropdownMenuItem(
              value: device.prefix,
              child: Text(
                  device.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
              )
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                onPrefixChanged(v);

                if (nodeClient.mac.isNotBlank) {
                  updateModuleSsid(nodeClient.mac);
                } else {
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

  void onSaveHttpUpdate(LocationType selectedLocation) async {
    setState(() { isLoading = true; status = "Запис параметрів..."; });
    try {
      await nodeClient.onSaveUpdate(
        targetSsid: targetSsidController.text,
        targetPass: passController.text,
        moduleSsid: ssidNameController.text,
        ipA: ipAController.text,
        portA: int.tryParse(portAController.text) ?? 0,
        ipB: ipBController.text,
        portB: int.tryParse(portBController.text) ?? 0,
        bitrate: int.tryParse(bitrateController.text) ?? UsrProvisionHelper.bitrateDef,
        isRs485Enabled: selectedUartType.isRs485Enabled,
      );

      final infoBms = await _onUpdateDataUsrWiFiInfo(selectedLocation);
      setState(() { isLoading = false; status = "Успіх! Налаштування збережено."; });
      await _savePreferences();
      if (mounted) {
        if (selectedPrefix.contains("S100")) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Оновлено, перепідключення нової мережі - вручну: $infoBms"), backgroundColor: Colors.green)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Оновлено: $infoBms"), backgroundColor: Colors.green)
          );
        }
        resetProvisioningState(false, "Оновлення пристрою завершено");
      }
    } catch (e) {
      setState(() { status = "Помилка: $e"; isLoading = false; });
    }
  }

  void onLoadDefault() async {
    setState(() { isLoading = true; status = "Скидання..."; });
    try {
      await nodeClient.postRestart();
      setState(() => status = "Модуль перезавантажується...");
    } catch (e) {
      setState(() => status = "Помилка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _onUpdateDataUsrWiFiInfo(LocationType selectedLocation) async {
    final info = DataUsrWiFiInfo(
        locationType: selectedLocation, id: int.tryParse(idController.text)!, bssidMac: nodeClient.mac ?? "",
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

    setState(() {
      keepTargetSettings = prefs.getBool('keepTargetSettings') ?? true;

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
      idController.text = "0";

      networks = [];
      scanSuccess = false;
      selectedSsid = null;
      macController.clear();
      isLoading = isStart;

      if (!keepTargetSettings) {
        targetSsidController.clear();
        passController.clear();
        bitrateController.text = UsrProvisionHelper.bitrateDef.toString();
      }

      ssidNameController.text = selectedPrefix;
      status = statusStr;
      selectedUartType = ConnectInterfaceType.rs485;
    });
  }

  /// Викликається при зміні префікса (A2 / B2 / S100 / ESP / BL602)
  void onPrefixChanged(String newPrefix) {
    final oldDeviceType = UsrClientNodeType.fromPrefix(selectedPrefix);
    final newDeviceType = UsrClientNodeType.fromPrefix(newPrefix);

    setState(() {
      selectedPrefix = newPrefix;

      if (newDeviceType.isBleSupported) {
        if (selectedUartType == ConnectInterfaceType.rxTx) {
          selectedUartType = ConnectInterfaceType.rs485;
        }
      } else {
        if (selectedUartType == ConnectInterfaceType.ble) {
          selectedUartType = ConnectInterfaceType.rs485;
        }
      }
    });

    if (!oldDeviceType.isBleSupported && newDeviceType.isBleSupported) {
      debugPrint("Перехід USR -> BLE Node: Зупиняємо HTTP, відкриваємо BLE");

      stopHttpScanNode(
        statusMsg: "Переключено на ${newDeviceType.label}. Запуск BLE...",
      );

      startBleScanNode();

    } else if (oldDeviceType.isBleSupported && !newDeviceType.isBleSupported) {
      debugPrint("Перехід BLE -> USR Node: Зупиняємо BLE, повертаємо HTTP");

      stopBleScanNode();

      setState(() {
        status = "Переключено на ${newDeviceType.label}. Запуск пошуку USR...";
      });

      runSetupSequence(null);
    }
  }

  /// Зупиняє HTTP-сканування та скидає стан HTTP Node-клієнта
  void stopHttpScanNode({String? statusMsg}) {
    setState(() {
      networks.clear();
      nodeClient.mac = null;
      nodeClient.ssidName = null;
      isLoading = false;
      if (statusMsg != null) {
        status = statusMsg;
      }
    });
  }
}