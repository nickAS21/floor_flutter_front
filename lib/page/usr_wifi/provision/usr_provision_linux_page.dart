import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'http/usr_http_client_helper.dart';
import 'usr_provision_base_page.dart';
import 'http/usr_http_client.dart';
import '../../data_home/data_location_type.dart';


class UsrProvisionLinuxPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionLinuxPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionLinuxPage> createState() => _UsrProvisionLinuxPageState();
}

class _UsrProvisionLinuxPageState extends UsrProvisionBasePage<UsrProvisionLinuxPage> {
  final _httpClient = UsrHttpClient();
  final _provision = UsrProvisionLinux();
  final TextEditingController _macController = TextEditingController();

  List<Map<String, dynamic>> _networks = [];
  bool _scanSuccess = false;
  String? _selectedSsid;
  String _selectedPrefix = UsrHttpClientHelper.wifiSsidB2;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScan());
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

  Future<void> _onScan() async {
    if (!mounted) return;
    setState(() { isLoading = true; status = "Пошук..."; detectedMac = null; _scanSuccess = false; _networks = []; _selectedSsid = null; });

    // Отримуємо MAC
    final mac = await _httpClient.getMacAddress();
    if (mac != null) {
      final String cleanMac = mac.replaceAll(':', '');
      final String suffix = cleanMac.substring(cleanMac.length - 4).toUpperCase();
      setState(() {
        detectedMac = mac;
        ssidNameController.text = "$_selectedPrefix$suffix";
      });
    }
    final results = await _provision.scanNetworks(mac);

    if (mounted) {
      if (results.isNotEmpty) {
        _scanSuccess = true;
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var net in results) {
          final String ssid = (net['ssid'] ?? "").toString();
          if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
          if (!uniqueMap.containsKey(ssid) || (net['level'] ?? 0) > (uniqueMap[ssid]!['level'] ?? 0)) {
            uniqueMap[ssid] = net;
          }
        }

        setState(() {
          _networks = uniqueMap.values.toList();
          _networks.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
          status = "Знайдено: ${_networks.length}";
          isLoading = false;
        });
      } else {
        setState(() { _networks = []; status = "Timeout"; isLoading = false; _scanSuccess = false; });
      }
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
    final bool hasValue = _networks.any((n) => n['ssid'].toString() == _selectedSsid);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: hasValue ? _selectedSsid : null,
      isDense: true,
      decoration: const InputDecoration(labelText: "Available Networks", isDense: true, border: OutlineInputBorder()),
      items: _networks.map((n) => DropdownMenuItem<String>(
          value: n['ssid'].toString(),
          child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12))
      )).toList(),
      onChanged: (v) async {
        if (v == null) return;

        setState(() {
          _selectedSsid = v;
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