import 'dart:io';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'client/usr_client_factory.dart';
import 'usr_provision_base_page.dart';
import '../../data_home/data_location_type.dart';

class UsrProvisionLinuxPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionLinuxPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionLinuxPage> createState() => _UsrProvisionLinuxPageState();
}

class _UsrProvisionLinuxPageState extends UsrProvisionBasePage<UsrProvisionLinuxPage> {

  @override
  late final provision = UsrProvisionLinux();

  @override
  void initState() {
    super.initState();
    // Початкове отримання даних при завантаженні сторінки
    onScan();
  }

  @override
  void updateModuleSsid(String mac) {
    super.updateModuleSsid(mac);
    if (macController.text != mac) {
      macController.text = mac;
    }
  }

  /// ОСНОВНИЙ МЕТОД СКАНУВАННЯ ТА РОЗВІДКИ
  @override
  Future<void> onScan() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      status = "Розвідка пристрою...";
      detectedMac = null;
      scanSuccess = false;
      networks = [];
      selectedSsid = null;
    });

    try {
      // 1. Примусовий Rescan через фабрику
      httpClient = await UsrClientFactory.discoverDevice();

      // 2. Отримуємо свіжий MAC
      final mac = await httpClient.getMacAddress();
      if (mac != null) {
        updateModuleSsid(mac);
      }

      // 3. Скануємо мережі через нативного провайдера Linux
      final results = await provision.scanNetworks(mac);

      if (mounted) {
        if (results.isNotEmpty) {
          scanSuccess = true;
          final Map<String, Map<String, dynamic>> uniqueMap = {};
          for (var net in results) {
            final String ssid = (net['ssid'] ?? "").toString();
            if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
            if (!uniqueMap.containsKey(ssid) || (net['level'] ?? 0) > (uniqueMap[ssid]!['level'] ?? 0)) {
              uniqueMap[ssid] = net;
            }
          }

          setState(() {
            networks = uniqueMap.values.toList();
            networks.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
            status = "Знайдено доступних (Linux) через пристрій WiFi мереж: ${networks.length}";
          });
        } else {
          setState(() { status = "Мереж не знайдено (Timeout)"; scanSuccess = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        validateFormInternal(); // Оновлюємо стан кнопки Save
      }
    }
  }

  Future<void> onRefreshDevice() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      status = "Оновлення MAC...";
    });

    try {
      // Перевизначаємо клієнта перед кожним оновленням
      httpClient = await UsrClientFactory.discoverDevice();
      final mac = await httpClient.getMacAddress().timeout(const Duration(seconds: 2));

      if (mounted && mac != null) {
        updateModuleSsid(mac);
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка MAC: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        validateFormInternal(); //
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);

    return Scaffold(
      appBar: AppBar(
      title: const Text("Linux Configuration"),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: onScan)],
      ),
      body: widgets.buildCommonForm(
        networkSelector: _buildNetworkSelector(),
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "ЗБЕРЕГТИ ТА РЕСТАРТ",
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    final bool hasValue = networks.any((n) => n['ssid'].toString() == selectedSsid);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: hasValue ? selectedSsid : null,
      isDense: true,
      decoration: const InputDecoration(labelText: "Available Networks", isDense: true, border: OutlineInputBorder()),
      items: networks.map((n) => DropdownMenuItem<String>(
          value: n['ssid'].toString(),
          child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12))
      )).toList(),
      onChanged: (v) async {
        if (v == null) return;

        setState(() {
          selectedSsid = v;
          targetSsidController.text = v;
        });

        // Якщо пристрій ще не визначений (немає MAC) — пробуємо підключитися системно
        if (detectedMac == null || detectedMac!.isEmpty) {
          setState(() { isLoading = true; status = "Підключення до $v..."; });

          try {
            final result = await Process.run('nmcli', ['dev', 'wifi', 'connect', v]);
            if (result.exitCode == 0) {
              await Future.delayed(const Duration(seconds: 2)); // Даємо час на асоціацію
              await onScan(); // Повний Rescan після підключення
            } else {
              setState(() => status = "Помилка підключення nmcli");
            }
          } catch (e) {
            setState(() => status = "Помилка: $e");
          } finally {
            setState(() => isLoading = false);
          }
        }
      },
    );
  }
}