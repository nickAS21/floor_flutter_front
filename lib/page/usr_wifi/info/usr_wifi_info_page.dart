// lib/page/usr_wifi/info/usr_wifi_info_page.dart
import 'package:flutter/material.dart';
import 'data_usr_wifi_info.dart';
import 'usr_wifi_info_storage.dart';

class UsrWiFiInfoPage extends StatefulWidget {
  final DataUsrWiFiInfo info;

  const UsrWiFiInfoPage({super.key, required this.info});

  @override
  State<UsrWiFiInfoPage> createState() => _UsrWiFiInfoPageState();
}

class _UsrWiFiInfoPageState extends State<UsrWiFiInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _macController;
  late TextEditingController _ssidController;
  late TextEditingController _ipAController;
  late TextEditingController _portAController; // Додано
  late TextEditingController _ipBController;
  late TextEditingController _portBController; // Додано
  late TextEditingController _ouiController;   // Додано

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.info.id.toString());
    _macController = TextEditingController(text: widget.info.bssidMac);
    _ssidController = TextEditingController(text: widget.info.ssidWifiBms);
    _ipAController = TextEditingController(text: widget.info.netIpA);
    _portAController = TextEditingController(text: widget.info.netAPort.toString());
    _ipBController = TextEditingController(text: widget.info.netIpB);
    _portBController = TextEditingController(text: widget.info.netBPort.toString());
    _ouiController = TextEditingController(text: widget.info.oui ?? '');

    // Слухач для автоматичного перерахунку портів при зміні ID
    _idController.addListener(_updatePortsFromId);
  }

  void _updatePortsFromId() {
    final int? id = int.tryParse(_idController.text);
    if (id != null) {
      setState(() {
        _portAController.text = (18890 + id).toString();
        _portBController.text = (8890 + id).toString();
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _portAController.dispose();
    _portBController.dispose();
    // ... інші діспози за потреби
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final int newId = int.tryParse(_idController.text) ?? 0;

      widget.info.id = newId;
      widget.info.bssidMac = _macController.text;
      widget.info.ssidWifiBms = _ssidController.text;
      widget.info.netIpA = _ipAController.text;
      widget.info.netAPort = int.tryParse(_portAController.text) ?? (18890 + newId);
      widget.info.netIpB = _ipBController.text;
      widget.info.netBPort = int.tryParse(_portBController.text) ?? (8890 + newId);
      widget.info.oui = _ouiController.text.isEmpty ? null : _ouiController.text;

      await UsrWiFiInfoStorage().saveInfo(widget.info);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Редагувати: ${widget.info.locationType.label}"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(_idController, "Device ID", isNumber: true),
            _buildField(_ouiController, "OUI (Vendor/Chip)"), // Нове поле
            _buildField(_macController, "MAC-адреса"),
            _buildField(_ssidController, "SSID модуля"),

            const Divider(height: 30, thickness: 1),
            const Text("Налаштування NetA (Сервер)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildField(_ipAController, "IP Server")),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: _buildField(_portAController, "Port", isNumber: true)),
              ],
            ),

            const SizedBox(height: 12),
            const Text("Налаштування NetB (BMS)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildField(_ipBController, "IP BMS")),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: _buildField(_portBController, "Port", isNumber: true)),
              ],
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)
              ),
              child: const Text("ЗБЕРЕГТИ ЛОКАЛЬНО"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}