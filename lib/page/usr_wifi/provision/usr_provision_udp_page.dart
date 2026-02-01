import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import 'usr_provision_udp.dart';
import '../../data_home/data_location_type.dart';

class UsrProvisionUdpPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionUdpPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionUdpPage> createState() => _UsrProvisionUdpPageState();
}

class _UsrProvisionUdpPageState extends UsrProvisionBasePage<UsrProvisionUdpPage> {

  @override
  final provision = UsrProvisionUdp();

  @override
  void initState() {
    super.initState();
    // Усі слухачі вже підключені в базовому класі
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScan());
  }

  void _onScan() async {
    if (!mounted) return;
    setState(() { isLoading = true; status = "Пошук..."; detectedMac = null; scanSuccess = false; networks = []; selectedSsid = null; });

    final results = await provision.scanNetworks(null);

    if (mounted) {
      if (results.isNotEmpty) {
        scanSuccess = true;
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

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);

    return Scaffold(
      appBar: AppBar(
        title: const Text("UDP Configuration"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _onScan)],
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