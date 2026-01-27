import 'package:flutter/material.dart';
import 'http/usr_http_client_helper.dart';
import 'usr_provision_udp.dart';
import 'http/usr_http_client.dart';

class UsrProvisionUdpPage extends StatefulWidget {
  const UsrProvisionUdpPage({super.key});

  @override
  State<UsrProvisionUdpPage> createState() => _UsrProvisionUdpPageState();
}

class _UsrProvisionUdpPageState extends State<UsrProvisionUdpPage> {
  final _provision = UsrProvisionUdp();
  final _httpClient = UsrHttpClient();

  // Контролери
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _idController = TextEditingController(text: "9");
  final _ipAController = TextEditingController(text: UsrHttpClientHelper.backendHostHome);
  final _portAController = TextEditingController(); // Новий
  final _ipBController = TextEditingController(text: UsrHttpClientHelper.backendHostKubernet);
  final _portBController = TextEditingController(); // Новий
  final _ssidNameController = TextEditingController();

  List<Map<String, dynamic>> _networks = [];
  String? _selectedSsid;
  String _status = "Очікування...";
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _detectedMac;
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
    // Початковий розрахунок портів
    _updatePortsLogic();

    // Слухачі для валідації та автооновлення
    _ssidController.addListener(_validateForm);
    _passController.addListener(_validateForm);
    _ipAController.addListener(_validateForm);
    _portAController.addListener(_validateForm);
    _ipBController.addListener(_validateForm);
    _portBController.addListener(_validateForm);
    _ssidNameController.addListener(_validateForm);

    // Спеціальний слухач для ID: оновлює порти
    _idController.addListener(() {
      _updatePortsLogic();
      _validateForm();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _onScan());
  }

  // Розрахунок портів на основі ID
  void _updatePortsLogic() {
    final int id = int.tryParse(_idController.text) ?? 0;
    setState(() {
      _portAController.text = (UsrHttpClientHelper.netPortADef + id).toString();
      _portBController.text = (UsrHttpClientHelper.netPortBDef + id).toString();
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    _idController.dispose();
    _ipAController.dispose();
    _portAController.dispose();
    _ipBController.dispose();
    _portBController.dispose();
    _ssidNameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final bool isValid = _ssidController.text.isNotEmpty &&
        _passController.text.isNotEmpty &&
        _idController.text.isNotEmpty &&
        _ipAController.text.isNotEmpty &&
        _portAController.text.isNotEmpty &&
        _ipBController.text.isNotEmpty &&
        _portBController.text.isNotEmpty &&
        _ssidNameController.text.isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _fetchMac() async {
    final mac = await _httpClient.getMacAddress();
    if (mounted && mac != null) {
      final String cleanMac = mac.replaceAll(':', '');
      final String suffix = cleanMac.substring(cleanMac.length - 4).toUpperCase();
      setState(() {
        _detectedMac = mac;
        _ssidNameController.text = "$_selectedPrefix$suffix";
      });
    }
  }

  void _onScan() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _status = "Пошук..."; _detectedMac = null; _scanSuccess = false; });
    final results = await _provision.scanNetworks();
    if (mounted) {
      if (results.isNotEmpty) {
        _scanSuccess = true;
        await _fetchMac();
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
          _status = "Знайдено: ${_networks.length}";
          _isLoading = false;
        });
      } else {
        setState(() { _networks = []; _status = "Timeout"; _isLoading = false; _scanSuccess = false; });
      }
    }
  }

  // void _onSave() async {
  //   setState(() { _isLoading = true; _status = "Збереження..."; });
  //   try {
  //     // mode = STA + AP
  //     await _httpClient.postApStaMode();
  //     await _httpClient.postApStaOn();
  //
  //     // Settings: Server_A + Server_B
  //     final int id = int.tryParse(_idController.text) ?? 1;
  //     await _httpClient.postAppSetting(
  //       serverIpA: _ipAController.text,
  //       serverPortA: int.tryParse(_portAController.text) ?? (UsrHttpClientHelper.netPortADef + id),
  //       serverIpB: _ipBController.text,
  //       serverPortB: int.tryParse(_portBController.text) ?? (UsrHttpClientHelper.netPortBDef + id),
  //       deviceId: id,
  //     );
  //
  //     await _httpClient.postApLan(_ssidNameController.text);
  //
  //     // finish -> save with reboot
  //     final res = await _provision.saveAndRestart(_ssidController.text, _passController.text);
  //     setState(() { _isLoading = false; _status = (res == "ok") ? "Успіх! Рестарт..." : "Помилка UDP: $res"; });
  //   } catch (e) { setState(() { _status = "Помилка: $e"; _isLoading = false; }); }
  // }

  void _onSave() async {
    setState(() { _isLoading = true; _status = "Запис параметрів..."; });
    try {
      final int id = int.tryParse(_idController.text) ?? 1;
      bool isOk(String r) => !r.contains("ERROR_HTTP");

      // 1. Режим (STA+AP) + Apply
      String r1 = await _httpClient.postApStaMode();
      if (isOk(r1)) { await _httpClient.postApply(); } else { throw "Помилка Mode"; }

      // 2. Активація STA + Apply
      // String r2 = await _httpClient.postApStaOn();
      // if (isOk(r2)) { await _httpClient.postApply(); } else { throw "Помилка STA On"; }
      String r2 = await _httpClient.postApStaOnWithUpdateSsidPwd(_ssidController.text, _passController.text);
      if (isOk(r2)) { await _httpClient.postApply(); } else { throw "Помилка STA On, Ssid  + Pwd"; }

      // 3. Сервери A/B + Apply
      String r3 = await _httpClient.postAppSetting(
        serverIpA: _ipAController.text,
        serverPortA: int.tryParse(_portAController.text) ?? (UsrHttpClientHelper.netPortADef + id),
        serverIpB: _ipBController.text,
        serverPortB: int.tryParse(_portBController.text) ?? (UsrHttpClientHelper.netPortBDef + id),
        deviceId: id,
      );
      if (isOk(r3)) { await _httpClient.postApply(); } else { throw "Помилка Settings"; }

      // 4. SSID для AP (Остання HTTP дія) + Apply
      String r4 = await _httpClient.postApLan(_ssidNameController.text);
      if (isOk(r4)) { await _httpClient.postApply(); } else { throw "Помилка SSID"; }

      // 5. ФІНАЛЬНИЙ UDP ЗАПИС (saveAndRestart)
      // Саме ця команда через UDP ініціює реальне збереження і ПЕРЕЗАВАНТАЖЕННЯ (Reboot)
      setState(() { _status = "Фіналізація та рестарт..."; });


      // final res = await _provision.saveAndRestart(_ssidController.text, _passController.text);
      final res = await  _httpClient.postRestart();

      setState(() {
        _isLoading = false;
        // _status = (res == "ok") ? "Успіх! Модуль перезавантажується..." : "Помилка UDP: $res";
        _status = (res == true) ? "Успіх! Модуль перезавантажується..." : "Помилка UDP: $res";
      });

    } catch (e) {
      setState(() { _status = "Помилка: $e"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_scanSuccess ? "Connected" : "Not Connected", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 22), onPressed: _onScan)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            _buildOptimizedHint(),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 55,
                  child: TextField(
                    controller: _idController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(labelText: "ID", isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 6),
                _buildPrefixSelector(),
                const SizedBox(width: 6),
                Expanded(child: _buildCompactField(_ssidNameController, "Module SSID")),
              ],
            ),
            const SizedBox(height: 10),
            _buildCompactField(_ssidController, "WiFi SSID (Target)"),
            const SizedBox(height: 10),
            _buildCompactField(
              _passController,
              "WiFi Password",
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 10),

            // Server A Row
            Row(
              children: [
                Expanded(flex: 3, child: _buildCompactField(_ipAController, "Server IP A")),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildCompactField(_portAController, "Port A")),
              ],
            ),
            const SizedBox(height: 10),

            // Server B Row
            Row(
              children: [
                Expanded(flex: 3, child: _buildCompactField(_ipBController, "Server IP B")),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildCompactField(_portBController, "Port B")),
              ],
            ),
            const SizedBox(height: 16),
            if (_networks.isNotEmpty) _buildNetworkSelector(),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator()
            else SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _isFormValid ? _onSave : null, child: const Text("ЗБЕРЕГТИ"))),
            const SizedBox(height: 10),
            Text("Статус: $_status", style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Допоміжні методи ...
  Widget _buildOptimizedHint() {
    final bool hasMac = _scanSuccess && _detectedMac != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _scanSuccess ? Colors.green.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _scanSuccess ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
      ),
      child: Text(hasMac ? "MAC: $_detectedMac" : _provision.getHint(), textAlign: TextAlign.center, style: TextStyle(color: _scanSuccess ? Colors.green.shade700 : Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
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
          onChanged: (String? nv) { if (nv != null) setState(() { _selectedPrefix = nv; if (_detectedMac != null) { final s = _detectedMac!.replaceAll(':', '').substring(_detectedMac!.replaceAll(':', '').length - 4).toUpperCase(); _ssidNameController.text = "$_selectedPrefix$s"; } }); },
        ),
      ),
    );
  }

  Widget _buildCompactField(TextEditingController ctrl, String label, {bool obscure = false, Widget? suffix}) {
    return TextField(controller: ctrl, obscureText: obscure, style: const TextStyle(fontSize: 13), decoration: InputDecoration(labelText: label, isDense: true, suffixIcon: suffix, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)));
  }

  Widget _buildNetworkSelector() {
    return DropdownButtonFormField<String>(isExpanded: true, value: _selectedSsid, isDense: true, decoration: const InputDecoration(labelText: "Available Networks", isDense: true, border: OutlineInputBorder()),
      items: _networks.map((n) => DropdownMenuItem<String>(value: n['ssid'].toString(), child: Text("${n['ssid']} (${n['level']}%)", style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) { setState(() { _selectedSsid = v; if (v != null) _ssidController.text = v; }); },
    );
  }
}