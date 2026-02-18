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
  Future<void> onScan() async {
    if (!mounted) return;

    // 1. Повне скидання через наш метод
    resetProvisioningState();

    setState(() {
      isLoading = true;
      status = "Пошук...";
    });

    try {
      final results = await provision.scanNetworks(null);

      if (mounted && results.isNotEmpty) {
        // 2. Отримуємо мережі
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var net in results) {
          final String ssid = (net['ssid'] ?? "").toString();
          if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
          uniqueMap[ssid] = net;
        }

        setState(() {
          networks = uniqueMap.values.toList();
          networks.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
          scanSuccess = true;
          isLoading = false; // РОЗБЛОКУЄМО ВІДЖЕТИ ВІДРАЗУ ТУТ
          status = "Знайдено мереж: ${networks.length}";
        });

        // 3. Тільки ПІСЛЯ розблокування спокійно шукаємо MAC
        final mac = await httpClient.getMacAddress().timeout(const Duration(seconds: 2)).catchError((_) => null);
        if (mac != null && mounted) {
          updateModuleSsid(mac); // Оновить MAC та валідує форму
        }
      } else {
        if (mounted) setState(() { status = "Мереж не знайдено"; isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { status = "Помилка: $e"; isLoading = false; });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        validateFormInternal(); // Активує кнопку Save
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);

    return Scaffold(
      appBar: AppBar(
        title: const Text("UDP Configuration"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: onScan)],
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