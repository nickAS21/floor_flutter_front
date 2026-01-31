import 'usr_wifi_info_page.dart';
import '../info/usr_wifi_info_storage.dart';
import '../info/data_usr_wifi_info.dart';
import 'package:flutter/material.dart';

import '../../data_home/data_location_type.dart';

class UsrWiFiInfoListPage extends StatefulWidget {
  final LocationType selectedLocation; // [1] Додаємо поле

  const UsrWiFiInfoListPage({
    super.key,
    required this.selectedLocation // [2] Робимо обов'язковим
  });

  @override
  State<UsrWiFiInfoListPage> createState() => _UsrWiFiInfoListPageState();
}

class _UsrWiFiInfoListPageState extends State<UsrWiFiInfoListPage> {
  final _storage = UsrWiFiInfoStorage();
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [3] Прибираємо ListView і показуємо тільки одну вибрану секцію
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _buildLocationSection(widget.selectedLocation),
      ),
    );
  }

  Widget _buildLocationSection(LocationType type) {
    return FutureBuilder<List<DataUsrWiFiInfo>>(
      future: _storage.loadAllInfoForLocation(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(
              Icons.settings_input_antenna,
              color: type == LocationType.golego ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(
              _isSelectionMode ? "Вибрано: ${_selectedIds.length}" : "Модулі зв'язку USR",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // КНОПКИ КЕРУВАННЯ В ЗАГОЛОВКУ ПРАВОРУЧ
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => _addNewInfo(type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.red, size: 28),
                    onPressed: _selectedIds.isEmpty ? null : () => _deleteSelected(type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                    onPressed: () => setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    }),
                  ),
                ],
                const Icon(Icons.expand_more), // Повертаємо стрілку розгортання
              ],
            ),
            children: [
              if (list.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text("Список порожній"))
              else
                ...list.map((info) {
                  final bool isSelected = _selectedIds.contains(info.id);
                  return Column(
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(value: isSelected, activeColor: Colors.red, onChanged: (_) => _toggleSelection(info.id))
                            : const Icon(Icons.router_outlined, color: Colors.blueAccent),
                        title: Text(info.ssidWifiBms),
                        subtitle: Text("ID: ${info.id} | MAC: ${info.bssidMac}"),
                        onTap: () => _isSelectionMode ? _toggleSelection(info.id) : _showInfoDetails(info),
                      ),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected(LocationType type) async {
    final int count = _selectedIds.length;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Видалення"),
        content: Text("Буде видалено $count Usr. Ви впевнені?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("СКАСУВАТИ")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ВИДАЛИТИ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Отримуємо актуальний список
      List<DataUsrWiFiInfo> list = await _storage.loadAllInfoForLocation(type);

      // Видаляємо відмічені
      list.removeWhere((info) => _selectedIds.contains(info.id));

      // Зберігаємо оновлений масив
      await _storage.saveFullList(type, list);

      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _addNewInfo(LocationType type) async {
    final newInfo = DataUsrWiFiInfo(
      id: 0, // Початкове значення 0 (помилкове)
      locationType: type,
      bssidMac: "",
      ssidWifiBms: "",
      netIpA: "",
      netAPort: 18890, // Базовий порт
      netIpB: "0.0.0.0",
      netBPort: 8890,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: newInfo)),
    );

    if (result == true) setState(() {});
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _editInfo(DataUsrWiFiInfo info) async {
    // Додаємо перехід на сторінку редагування
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsrWiFiInfoPage(info: info),
      ),
    );

    // Якщо ми повернулися зі збереженням (result == true), оновлюємо екран
    if (result == true) {
      setState(() {
        // FutureBuilder сам перечитає дані з SharedPreferences
      });
    }
  }

  void _showInfoDetails(DataUsrWiFiInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(info.ssidWifiBms),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("ID (BMS Index)", info.id.toString()),
              _detailRow("MAC Address", info.bssidMac),
              // Додаємо OUI, якщо він не порожній
              if (info.oui != null && info.oui!.isNotEmpty)
                _detailRow("Vendor (OUI)", info.oui!),
              const Divider(),
              _detailRow("Server IP (NetA)", info.netIpA),
              _detailRow("Server Port", info.netAPort.toString()),
              const Divider(),
              _detailRow("Device IP (NetB)", info.netIpB),
              _detailRow("Device Port", info.netBPort.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ЗАКРИТИ")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editInfo(info);
            },
            child: const Text("РЕДАГУВАТИ"),
          ),
        ],
      ),
    );
  }
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}