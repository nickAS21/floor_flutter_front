import 'dart:io';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
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
    // super.initState() вже додав слухача для MAC та валідації

    _onRefresh(); // Отримуємо початковий MAC
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScan());
  }

  @override
  void updateModuleSsid(String mac) {
    // 1. Виконуємо базову логіку (оновлення SSID модуля)
    super.updateModuleSsid(mac);

    // 2. Синхронізуємо текст у полі вводу з отриманим MAC
    if (macController.text != mac) {
      macController.text = mac;
    }
  }

  Future<void> _onScan() async {
    if (!mounted) return;
    setState(() { isLoading = true; status = "Пошук..."; detectedMac = null; scanSuccess = false; networks = []; selectedSsid = null; });

    // Отримуємо MAC
    final mac = await httpClient.getMacAddress();
    if (mac != null) {
      final String cleanMac = mac.replaceAll(':', '');
      final String suffix = cleanMac.substring(cleanMac.length - 4).toUpperCase();
      setState(() {
        detectedMac = mac;
        ssidNameController.text = "$selectedPrefix$suffix";
      });
    }
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
          status = "Знайдено: ${networks.length}";
          isLoading = false;
        });
      } else {
        setState(() { networks = []; status = "Timeout"; isLoading = false; scanSuccess = false; });
      }
    }
  }


  Future<void> _onRefresh() async {
    // Додаємо перевірку на самому вході
    if (!mounted) return;

    setState(() {
      isLoading = true;
      status = "Отримання даних...";

      detectedMac = null;
      macController.clear();
      targetSsidController.clear();
      passController.clear();
      ssidNameController.clear();
    });

    try {
      // Додаємо .timeout, щоб запит не "висів" у пам'яті довше 2 секунд
      final mac = await httpClient.getMacAddress().timeout(
        const Duration(seconds: 2),
      );

      // ПЕРЕВІРКА: чи ми ще на цій вкладці після того, як прийшла відповідь?
      if (mounted && mac != null) {
        updateModuleSsid(mac);
      }
    } catch (e) {
      // Захищаємо setState в блоці помилки
      if (mounted) {
        setState(() => status = "Помилка: $e");
      }
    } finally {
      // Захищаємо фінальний setState
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this); // Передаємо 'this' (State)

    return Scaffold(
      appBar: AppBar(
        title: const Text("Linux Configuration"),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _onScan)]
      ),
      body: widgets.buildCommonForm(
        networkSelector: _buildNetworkSelector(), // Передаємо специфічний для сторінки віджет
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

        // ЛОГІКА: якщо MAC порожній — підключаємо Linux до цієї мережі
        if (detectedMac == null || detectedMac!.isEmpty) {
          setState(() {
            isLoading = true;
            status = "Підключення до $v...";
          });

          try {
            // Використовуємо nmcli для підключення.
            // Примітка: якщо мережа з паролем, nmcli може запитати його або видати помилку,
            // якщо пароль не збережений раніше.
            final result = await Process.run('nmcli', [
              'dev', 'wifi', 'connect', v
            ]);

            if (result.exitCode == 0) {
              // Якщо підключилися успішно — робимо refresh, щоб отримати новий MAC
              await _onRefresh();
              await  _onScan();
            } else {
              setState(() => status = "Помилка підключення: ${result.stderr}");
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