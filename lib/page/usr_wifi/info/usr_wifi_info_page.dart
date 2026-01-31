import 'package:flutter/material.dart';
import '../provision/http/usr_http_client_helper.dart';
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
  late TextEditingController _portAController;
  late TextEditingController _ipBController;
  late TextEditingController _portBController;
  late TextEditingController _ouiController;

  static const List<String> _usrPrefixes = [
    UsrHttpClientHelper.wifiSsidB2,
    UsrHttpClientHelper.wifiSsidA2,
    UsrHttpClientHelper.wifiSsidAx
  ];
  String _selectedPrefix = UsrHttpClientHelper.wifiSsidB2;

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

    for (var prefix in _usrPrefixes) {
      if (widget.info.ssidWifiBms.startsWith(prefix)) {
        _selectedPrefix = prefix;
        break;
      }
    }

    _idController.addListener(_updatePortsFromId);
    _macController.addListener(_updateSsidFromMac);
  }

  String _generateSsidSuffix() {
    final mac = _macController.text.replaceAll(':', '');
    if (mac.length >= 4) {
      return mac.substring(mac.length - 4).toUpperCase();
    }
    return "0000";
  }

  void _updateSsidFromMac() {
    // Оновлюємо тільки якщо поле SSID порожнє або вже містить префікс USR
    if (_ssidController.text.isEmpty || _ssidController.text.contains("USR-WIFI232")) {
      setState(() {
        _ssidController.text = "$_selectedPrefix${_generateSsidSuffix()}";
      });
    }
  }

  void _updatePortsFromId() {
    final int? id = int.tryParse(_idController.text);
    if (id != null) {
      setState(() {
        _portAController.text = (UsrHttpClientHelper.netPortADef + id).toString();
        _portBController.text = (UsrHttpClientHelper.netPortBDef + id).toString();
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _macController.dispose();
    _ssidController.dispose();
    _ipAController.dispose();
    _portAController.dispose();
    _ipBController.dispose();
    _portBController.dispose();
    _ouiController.dispose();
    super.dispose();
  }

  void _save() async {
    // 1. Валідація: перевіряємо, чи всі поля заповнені (TextField validator)
    if (!_formKey.currentState!.validate()) return;

    final int oldId = widget.info.id;
    final int newId = int.tryParse(_idController.text) ?? oldId;

    final storage = UsrWiFiInfoStorage();
    List<DataUsrWiFiInfo> list = await storage.loadAllInfoForLocation(widget.info.locationType);

    // Перевіряємо, чи цей пристрій (за старим ID) вже є в базі
    bool isExisting = list.any((e) => e.id == oldId);

    // ЛОГІКА ЗМІНИ ID АБО ПЕРЕВІРКИ ДУБЛІКАТІВ
    if (isExisting && oldId != newId) {
      // Сценарій: редагуємо старий, але міняємо ID (наприклад, з 1 на 5)
      bool isOccupied = list.any((e) => e.id == newId);
      String msg = "USR з id=$oldId буде видалено. id=$newId буде ";
      msg += isOccupied ? "ПЕРЕЗАПИСАНО." : "створено.";

      bool? confirm = await _showConfirmReplaceDialog(msg);
      if (confirm != true) return;

      // Видаляємо старий ID перед тим як записати новий
      await _deleteOldIdBeforeUpdate(oldId);
    } else if (!isExisting && list.any((e) => e.id == newId)) {
      // Сценарій: додаємо НОВИЙ, але введений ID вже кимось зайнятий
      bool? confirm = await _showConfirmReplaceDialog("ID $newId вже зайнятий іншим пристроєм. Перезаписати його?");
      if (confirm != true) return;
    }

    // ОНОВЛЕННЯ ОБ'ЄКТА ДАНИМИ З КОНТРОЛЕРІВ
    widget.info.id = newId;
    widget.info.bssidMac = _macController.text;
    widget.info.ssidWifiBms = _ssidController.text;
    widget.info.netIpA = _ipAController.text;
    widget.info.netAPort = int.tryParse(_portAController.text) ?? (UsrHttpClientHelper.netPortADef + newId);
    widget.info.netIpB = _ipBController.text;
    widget.info.netBPort = int.tryParse(_portBController.text) ?? (UsrHttpClientHelper.netPortBDef + newId);
    // oui не чіпаємо, воно тільки для читання

    // Остаточне збереження в SharedPreferences
    await storage.updateOrAddById(widget.info);

    if (mounted) Navigator.pop(context, true);
  }

  // Допоміжний метод для діалогу (додай його в цей же клас)
  Future<bool?> _showConfirmReplaceDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Підтвердження"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("СКАСУВАТИ")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ПІДТВЕРДИТИ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

// Твій метод, який ти питав, чи залишати:
  Future<void> _deleteOldIdBeforeUpdate(int oldId) async {
    final storage = UsrWiFiInfoStorage();
    List<DataUsrWiFiInfo> list = await storage.loadAllInfoForLocation(widget.info.locationType);
    list.removeWhere((e) => e.id == oldId);
    await storage.saveFullList(widget.info.locationType, list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Редагувати: ${widget.info.locationType.label}")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _buildField(_idController, "ID", isNumber: true)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildField(_ouiController, "OUI (Vendor/Chip)", readOnly: true, isOptional: true)),
              ],
            ),
            _buildField(_macController, "MAC-адреса", isMac: true,),

            const Text("Налаштування SSID модуля", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 6),

            // РЯДОК: Префікс та SSID з вирівняною висотою
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 75,
                  height: 47, // Фіксована висота для вирівнювання з TextField
                  child: DropdownButtonFormField<String>(
                    value: _selectedPrefix,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    items: _usrPrefixes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value.replaceFirst("USR-WIFI232-", "").replaceFirst("_", ""),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (nv) {
                      if (nv != null) {
                        setState(() {
                          _selectedPrefix = nv;
                          _updateSsidFromMac();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_ssidController, "SSID модуля")),
              ],
            ),

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
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("ЗБЕРЕГТИ ЛОКАЛЬНО"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {
    bool isNumber = false,
    bool readOnly = false,
    bool isOptional = false,
    bool isMac = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        // Автоматичне перетворення на великі літери для MAC
        onChanged: isMac ? (val) => ctrl.value = ctrl.value.copyWith(
          text: val.toUpperCase(),
          selection: TextSelection.collapsed(offset: val.length),
        ) : null,
        style: TextStyle(fontSize: 14, color: readOnly ? Colors.blueGrey : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.withValues(alpha: 0.05) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          hintText: isMac ? "XX:XX:XX:XX:XX:XX" : null,
        ),
        validator: (value) {
          if (isOptional && (value == null || value.isEmpty)) return null;
          if (value == null || value.isEmpty) return "!";

          // СУВОРИЙ РЕГУЛЯРНИЙ ВИРАЗ
          if (isMac) {
            // Дозволяє 6 пар HEX-символів через двокрапку
            final macRegex = RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$');
            if (!macRegex.hasMatch(value.toUpperCase())) {
              return "Формат: XX:XX:XX:XX:XX:XX";
            }
          }

          if (isNumber) {
            final n = int.tryParse(value);
            if (n == null || n <= 0) return ">0";
          }
          return null;
        },
      ),
    );
  }
}