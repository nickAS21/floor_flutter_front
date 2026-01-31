import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import 'usr_provision_udp.dart';
import 'http/usr_http_client.dart';
import 'http/usr_http_client_helper.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import '../../data_home/data_location_type.dart';

class UsrProvisionUdpPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionUdpPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionUdpPage> createState() => _UsrProvisionUdpPageState();
}

class _UsrProvisionUdpPageState extends UsrProvisionBasePage<UsrProvisionUdpPage> {
  final _provision = UsrProvisionUdp();
  final _httpClient = UsrHttpClient();

  List<Map<String, dynamic>> _networks = [];
  String? _selectedSsid;
  bool _scanSuccess = false;
  bool _isFormValid = false;

  static const List<String> _usrPrefixes = [
    UsrHttpClientHelper.wifiSsidB2,
    UsrHttpClientHelper.wifiSsidA2,
    UsrHttpClientHelper.wifiSsidAx
  ];
  String _selectedPrefix = UsrHttpClientHelper.wifiSsidB2;

  @override
  void initState() {
    super.initState();
    // Повертаємо твої оригінальні слухачі для валідації
    targetSsidController.addListener(_validateForm);
    passController.addListener(_validateForm);
    idController.addListener(_validateForm);
    ssidNameController.addListener(_validateForm);
    ipAController.addListener(_validateForm);
    ipBController.addListener(_validateForm);

    WidgetsBinding.instance.addPostFrameCallback((_) => _onScan());
  }

  void _validateForm() {
    final bool isValid = targetSsidController.text.isNotEmpty &&
        passController.text.isNotEmpty &&
        idController.text.isNotEmpty &&
        ssidNameController.text.isNotEmpty;
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
  }

  void _onScan() async {
    if (!mounted) return;
    setState(() { isLoading = true; status = "Пошук..."; detectedMac = null; _scanSuccess = false; _networks = []; _selectedSsid = null; });

    final results = await _provision.scanNetworks();

    if (mounted) {
      if (results.isNotEmpty) {
        _scanSuccess = true;
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

  // void _onSaveHttpUpdate() async {
  //   setState(() { isLoading = true; status = "Запис параметрів..."; });
  //   try {
  //     await _httpClient.postApStaMode();                      // +
  //     await _httpClient.postApLan(ssidNameController.text);   // +
  //     await _httpClient.postApStaOnWithUpdateSsidPwd(         // +
  //         targetSsidController.text,
  //         passController.text
  //     );
  //     await _httpClient.postAppSetting(                       // +
  //         serverIpA: ipAController.text,
  //         serverPortA: int.tryParse(portAController.text)!,
  //         serverIpB: ipBController.text,
  //         serverPortB: int.tryParse(portBController.text)!
  //     );
  //
  //
  //     _onUpdateSsidPwdAndRestart();
  //     setState(() { isLoading = false; status = "Успіх! Рестарт..."; });
  //
  //   final infoBms = _onUpdateDataUsrWiFiInfo();
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Оновлено ${infoBms}")));
  //     }
  //   } catch (e) {
  //     setState(() { status = "Помилка: $e"; isLoading = false; });
  //   }
  // }
  //
  // void _onUpdateSsidPwdAndRestart() async {
  //   var res = "";
  //   if (Platform.isLinux) {
  //     res = await _httpClient.postRestart();
  //   } else {
  //     res = await _provision.saveAndRestart(
  //         targetSsidController.text, passController.text);
  //   }
  //
  //   if (res != "ok") {
  //     setState(() { isLoading = false; status = "Помилка конфігурації: $res"; });
  //     return;
  //   }
  // }
  //
  // Future<String> _onUpdateDataUsrWiFiInfo() async {
  //   final info = DataUsrWiFiInfo(
  //       locationType: widget.selectedLocation,
  //       id: int.tryParse(idController.text)!,
  //       bssidMac: detectedMac ?? "",
  //       ssidWifiBms: ssidNameController.text,
  //       netIpA: ipAController.text,
  //       netAPort: int.tryParse(portAController.text)!,
  //       netIpB: ipBController.text,
  //       netBPort: int.tryParse(portBController.text)!
  //   );
  //   await UsrWiFiInfoStorage().updateOrAddById(info);
  //   return info.ssidWifiBms;
  // }


  @override
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

  Widget _buildOptimizedHint() {
    final bool hasMac = _scanSuccess && detectedMac != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _scanSuccess ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _scanSuccess ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Text(hasMac ? "MAC: $detectedMac" : _provision.getHint(), textAlign: TextAlign.center, style: TextStyle(color: _scanSuccess ? Colors.green.shade700 : Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPrefixSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPrefix, isDense: true,
          items: _usrPrefixes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value.replaceFirst("USR-WIFI232-", "").replaceFirst("_", ""), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
          onChanged: (String? nv) { if (nv != null) setState(() { _selectedPrefix = nv; if (detectedMac != null) { ssidNameController.text = _getEffectiveSsidName(detectedMac); } }); },
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    final bool hasValue = _networks.any((n) => n['ssid'].toString() == _selectedSsid);
    return DropdownButtonFormField<String>(isExpanded: true, value: hasValue ? _selectedSsid : null, isDense: true, decoration: const InputDecoration(labelText: "Available Networks", isDense: true, border: OutlineInputBorder()),
      items: _networks.map((n) => DropdownMenuItem<String>(value: n['ssid'].toString(), child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) { setState(() { _selectedSsid = v; if (v != null) targetSsidController.text = v; }); },
    );
  }

  String _getEffectiveSsidName(String? mac) {
    if (ssidNameController.text.isNotEmpty && mac == null) return ssidNameController.text;
    final String cleanMac = (mac ?? "f4:70:0c:62:26:d0").replaceAll(':', '');
    final String suffix = cleanMac.length >= 4 ? cleanMac.substring(cleanMac.length - 4).toUpperCase() : "0000";
    return "$_selectedPrefix$suffix";
  }
}