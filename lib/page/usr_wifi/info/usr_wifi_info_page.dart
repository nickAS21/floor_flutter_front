import 'package:flutter/material.dart';
import '../provision/client/connect_interface_type.dart';
import '../provision/client/usr_client_node_type.dart';
import '../provision/client/usr_client_helper.dart';
import '../provision/usr_provision_helper.dart';
import 'data_usr_wifi_info.dart';
import 'usr_wifi_info_storage.dart';
import '../../../esp/info/data_esp_bms_info.dart';

class UsrWiFiInfoPage extends StatefulWidget {
  final DataUsrWiFiInfo info;
  final bool isNew;
  const UsrWiFiInfoPage({
    super.key,
    required this.info,
    this.isNew = false,
  });

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
  late TextEditingController _bitrateController;

  String _selectedPrefix = UsrClientNodeType.b2.prefix;
  bool _isFormValid = false;

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
    _bitrateController = TextEditingController(text: widget.info.bitrate.toString());

    for (var device in UsrClientNodeType.values) {
      if (widget.info.ssidWifiBms.startsWith(device.prefix)) {
        _selectedPrefix = device.prefix;
        break;
      }
    }

    final currentDevice = UsrClientNodeType.fromPrefix(_selectedPrefix);
    if (currentDevice.isBleSupported && widget.info.bmsList == null) {
      widget.info.bmsList = [];
    }

    _idController.addListener(_updatePortsFromId);
    _macController.addListener(_updateSsidFromMac);

    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
  }

  void _validateForm() {
    final int? id = int.tryParse(_idController.text);
    final bool isIdValid = id != null && id > 0;
    final bool isFieldsValid = _formKey.currentState?.validate() ?? false;

    bool isBmsValid = true;
    if (widget.info.bmsList != null) {
      if (widget.info.bmsList!.isEmpty) {
        isBmsValid = false;
      } else {
        final macRegex = RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$');
        for (var bms in widget.info.bmsList!) {
          if (bms.name.trim().isEmpty || bms.name.startsWith('-')) {
            isBmsValid = false;
            break;
          }
          if (bms.interfaceType == ConnectInterfaceType.ble &&
              !macRegex.hasMatch(bms.mac.toUpperCase())) {
            isBmsValid = false;
            break;
          }
        }
      }
    }

    final bool isValid = isIdValid && isFieldsValid && isBmsValid;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  String _generateSsidSuffix() {
    final mac = _macController.text.replaceAll(':', '');
    if (mac.length >= 4) {
      return mac.substring(mac.length - 4).toUpperCase();
    }
    return "____";
  }

  void _updateSsidFromMac() {
    _ssidController.text = "$_selectedPrefix${_generateSsidSuffix()}";
    _validateForm();
  }

  void _updatePortsFromId() {
    final int? id = int.tryParse(_idController.text);
    if (id != null) {
      _portAController.text = (UsrClientHelper.netPortADef + id).toString();
      _portBController.text = (UsrClientHelper.netPortBDef + id).toString();
    }
    _validateForm();
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
    _bitrateController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_isFormValid) return;

    final int newId = int.parse(_idController.text);
    final int oldId = widget.info.id;

    final storage = UsrWiFiInfoStorage();
    List<DataUsrWiFiInfo> list = await storage.loadAllInfoForLocation(widget.info.locationType);

    bool isExisting = list.any((e) => e.id == oldId);

    if (isExisting && oldId != newId) {
      bool isOccupied = list.any((e) => e.id == newId);
      String msg = "USR з id=$oldId буде видалено. id=$newId буде ";
      msg += isOccupied ? "ПЕРЕЗАПИСАНО." : "створено.";

      bool? confirm = await _showConfirmReplaceDialog(msg);
      if (confirm != true) return;

      await _deleteOldIdBeforeUpdate(oldId);
    } else if (!isExisting && list.any((e) => e.id == newId)) {
      bool? confirm = await _showConfirmReplaceDialog("ID $newId вже зайнятий іншим пристроєм. Перезаписати його?");
      if (confirm != true) return;
    }

    widget.info.id = newId;
    widget.info.bssidMac = _macController.text;
    widget.info.ssidWifiBms = _ssidController.text;
    widget.info.netIpA = _ipAController.text;
    widget.info.netAPort = int.tryParse(_portAController.text) ?? (UsrClientHelper.netPortADef + newId);
    widget.info.netIpB = _ipBController.text;
    widget.info.netBPort = int.tryParse(_portBController.text) ?? (UsrClientHelper.netPortBDef + newId);
    widget.info.bitrate = int.tryParse(_bitrateController.text) ?? UsrProvisionHelper.bitrateDef;

    await storage.updateOrAddById(widget.info);

    if (mounted) Navigator.pop(context, true);
  }

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

  Future<void> _deleteOldIdBeforeUpdate(int oldId) async {
    final storage = UsrWiFiInfoStorage();
    List<DataUsrWiFiInfo> list = await storage.loadAllInfoForLocation(widget.info.locationType);
    list.removeWhere((e) => e.id == oldId);
    await storage.saveFullList(widget.info.locationType, list);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isNew
        ? "Додати модуль зв'язку: ${widget.info.locationType.label}"
        : "Редагувати: ${widget.info.locationType.label}";
    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: Form(
        key: _formKey,
        onChanged: _validateForm,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _buildField(_idController, "ID", isNumber: true, isId: true)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildField(_bitrateController, "Bit Rate (Baud)", isNumber: true)),
              ],
            ),
            const SizedBox(height: 8),
            _buildField(_ouiController, "OUI (Vendor/Chip)", readOnly: true, isOptional: true),
            const SizedBox(height: 8),
            _buildField(_macController, "MAC-адреса", isMac: true),

            const Text("Налаштування SSID модуля", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  height: 47,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPrefix,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return UsrClientNodeType.values.map((device) {
                        return Text(
                          device.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items: UsrClientNodeType.values.map((device) {
                      return DropdownMenuItem<String>(
                        value: device.prefix,
                        child: Text(
                          device.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (nv) {
                      if (nv != null) {
                        setState(() {
                          _selectedPrefix = nv;
                          _updateSsidFromMac();

                          final deviceType = UsrClientNodeType.fromPrefix(nv);
                          if (deviceType.isBleSupported) {
                            widget.info.bmsList ??= [
                              DataEspBmsInfo(
                                mac: '',
                                name: '',
                                interfaceType: ConnectInterfaceType.rs485,
                                addressRs485: 1,
                              )
                            ];
                            _isFormValid = false;
                          } else {
                            widget.info.bmsList = null;
                          }
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
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

            if (widget.info.bmsList != null) ...[
              const Divider(height: 30, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Перелік підключених BMS",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                    onPressed: () {
                      setState(() {
                        widget.info.bmsList!.add(
                          DataEspBmsInfo(
                            mac: '',
                            name: '',
                            interfaceType: ConnectInterfaceType.rs485,
                            addressRs485: 1,
                          ),
                        );
                        _isFormValid = false;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
                    },
                  ),
                ],
              ),
              ...widget.info.bmsList!.asMap().entries.map((entry) {
                final int idx = entry.key;
                final item = entry.value;

                return _BmsItemCard(
                  key: ValueKey(item),
                  item: item,
                  onDelete: () {
                    setState(() {
                      widget.info.bmsList!.removeAt(idx);
                    });
                    _validateForm();
                  },
                  onChanged: () {
                    setState(() {});
                    _validateForm();
                  },
                );
              }),
            ],

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isFormValid ? _save : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  disabledBackgroundColor: Colors.grey.shade300,
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
    bool isId = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        onChanged: isMac ? (val) {
          ctrl.value = ctrl.value.copyWith(
            text: val.toUpperCase(),
            selection: TextSelection.collapsed(offset: val.length),
          );
          _validateForm();
        } : (_) => _validateForm(),
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

          if (isId) {
            final id = int.tryParse(value);
            if (id == null || id <= 0) return "ID > 0";
          }

          if (isMac) {
            final macRegex = RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$');
            if (!macRegex.hasMatch(value.toUpperCase())) {
              return "Формат: XX:XX:XX:XX:XX:XX";
            }
          }

          if (isNumber && !isId) {
            final n = int.tryParse(value);
            if (n == null || n <= 0) return ">0";
          }
          return null;
        },
      ),
    );
  }
}

class _BmsItemCard extends StatefulWidget {
  final DataEspBmsInfo item;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _BmsItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_BmsItemCard> createState() => _BmsItemCardState();
}

class _BmsItemCardState extends State<_BmsItemCard> {
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    String prefix = widget.item.name;
    if (prefix.contains('-')) {
      prefix = prefix.substring(0, prefix.lastIndexOf('-'));
    }
    _typeController = TextEditingController(text: prefix);
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  void _updateName() {
    widget.item.name = DataEspBmsInfo.buildName(
      customPrefix: _typeController.text,
      interfaceType: widget.item.interfaceType,
      addressRs485: widget.item.addressRs485,
      mac: widget.item.mac,
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: "Тип BMS",
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? "!" : null,
                    onChanged: (_) => _updateName(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<ConnectInterfaceType>(
                    value: widget.item.interfaceType == ConnectInterfaceType.ble
                        ? ConnectInterfaceType.ble
                        : ConnectInterfaceType.rs485,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: "Тип",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ConnectInterfaceType.rs485,
                        child: Text("RS485", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: ConnectInterfaceType.ble,
                        child: Text("BLE", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        widget.item.interfaceType = val;
                        if (val == ConnectInterfaceType.rs485) {
                          widget.item.addressRs485 ??= 1;
                        } else {
                          widget.item.addressRs485 = null;
                        }
                        _updateName();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: widget.item.interfaceType == ConnectInterfaceType.rs485
                      ? TextFormField(
                    initialValue: (widget.item.addressRs485 ?? 1).toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "DIP / Addr",
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n < 1) return ">0";
                      return null;
                    },
                    onChanged: (val) {
                      widget.item.addressRs485 = int.tryParse(val) ?? 1;
                      _updateName();
                    },
                  )
                      : TextFormField(
                    initialValue: widget.item.mac,
                    decoration: const InputDecoration(
                      labelText: "MAC-адреса",
                      hintText: "XX:XX:XX:XX:XX:XX",
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      widget.item.mac = val.toUpperCase();
                      _updateName();
                    },
                    validator: (value) {
                      if (widget.item.interfaceType == ConnectInterfaceType.ble) {
                        if (value == null || value.isEmpty) return "!";
                        final macRegex = RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$');
                        if (!macRegex.hasMatch(value.toUpperCase())) {
                          return "XX:XX:XX:XX:XX:XX";
                        }
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Name BMS: ${widget.item.name}",
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}