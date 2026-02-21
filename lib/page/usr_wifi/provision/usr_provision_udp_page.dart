import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import 'usr_wifi_232_provision_udp.dart';
import '../../data_home/data_location_type.dart';

class UsrProvisionUdpPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionUdpPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionUdpPage> createState() => _UsrProvisionUdpPageState();
}

class _UsrProvisionUdpPageState extends UsrProvisionBasePage<UsrProvisionUdpPage> {

  @override
  final provision = UsrWiFi232ProvisionUdp();

  @override
  void initState() {
    super.initState();
    // Усі слухачі вже підключені в базовому класі
    WidgetsBinding.instance.addPostFrameCallback((_) => onScan());
  }

  @override
  Future<bool> onScan() async {
    if (!mounted) return false;

    // 1. АНТИ-БРЕД: Якщо ми не знайшли девайс (MAC == null) — на Android сканувати нічого
    if (httpClient.mac == null) {
      setState(() {
        networks = [];
        isLoading = false; // Вимикаємо колесо
        status = "Девайс не знайдено. Перевірте Wi-Fi.";
      });
      return false; // ЗАВЕРШУЄМО
    }

    setState(() {
      status = "Отримання мереж...";
     });

    try {
      List<Map<String, dynamic>> results = [];

      // 2. АНАЛІЗ ПО КЛІЄНТУ: Працюємо через залізо
      if (selectedPrefix.contains("S100")) {
        results = await httpClient.getScanResults();
      } else {
        results = await provision.scanNetworks(null, httpClient); // Твій UDP для 232
      }

      if (mounted) {
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var net in results) {
          final String ssid = (net['ssid'] ?? "").toString();
          if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
          uniqueMap[ssid] = net;
        }

        setState(() {
          networks = uniqueMap.values.toList();
          networks.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
          scanSuccess = networks.isNotEmpty;
          status = scanSuccess ? "Знайдено: ${networks.length}" : "Мереж не знайдено";
        });
        return scanSuccess;
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false); // ГАСИМО КОЛЕСО ТУТ
        validateFormInternal();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);

    return Scaffold(
      appBar: AppBar(
        title: const Text("UDP Configuration"),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                // ПОВНИЙ RESCAN: спочатку ініціалізація (очистить MAC), потім скан
                await runSetupSequence(null);
                await onScan();
              }
          )
        ],
      ),
      body: widgets.buildCommonForm(
        networkSelector: _buildNetworkSelector(), // Передаємо специфічний для сторінки віджет
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "START PROVISIONING (UDP)",
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    final bool hasValue = networks.any((n) => n['ssid'].toString() == selectedSsid);
    return DropdownButtonFormField<String>(isExpanded: true, initialValue: hasValue ? selectedSsid : null, isDense: true, decoration: const InputDecoration(labelText: "Available Networks", isDense: true, border: OutlineInputBorder()),
      items: networks.map((n) => DropdownMenuItem<String>(value: n['ssid'].toString(), child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) {
        setState(() {
          selectedSsid = v;
          if (v != null) targetSsidController.text = v;
        });
      },
    );
  }
}