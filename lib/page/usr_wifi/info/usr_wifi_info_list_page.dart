import 'package:flutter/material.dart';
import '../info/data_usr_wifi_info.dart';
import '../../data_home/data_location_type.dart';

class UsrWiFiInfoListPage extends StatefulWidget {
  final LocationType selectedLocation;
  final List<DataUsrWiFiInfo> localeList; // Дані з локального сховища
  final List<DataUsrWiFiInfo>? externalList; // Дані, наприклад, з сервера

  // Колбеки для логіки
  final VoidCallback? onAdd;
  final Future<void> Function(Set<int>)? onDelete;
  final Function(DataUsrWiFiInfo)? onEdit;
  final VoidCallback? onRefresh;

  const UsrWiFiInfoListPage({
    super.key,
    required this.selectedLocation,
    required this.localeList,
    this.externalList,
    this.onAdd,
    this.onDelete,
    this.onEdit,
    this.onRefresh,
  });

  @override
  State<UsrWiFiInfoListPage> createState() => _UsrWiFiInfoListPageState();
}

class _UsrWiFiInfoListPageState extends State<UsrWiFiInfoListPage> {
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    // Вибираємо актуальний список
    final list = widget.externalList ?? widget.localeList;
    final sortedList = List<DataUsrWiFiInfo>.from(list)..sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(
              Icons.settings_input_antenna,
              color: widget.selectedLocation == LocationType.golego ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(
              _isSelectionMode ? "Вибрано: ${_selectedIds.length}" : "Модулі зв'язку USR",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: _buildActions(),
            children: [
              if (sortedList.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text("Список порожній"))
              else
                ...sortedList.map((info) => _buildItem(info)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // КНОПКИ КЕРУВАННЯ В ЗАГОЛОВКУ
  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            onPressed: widget.onAdd,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () => setState(() => _isSelectionMode = true),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.red, size: 28),
            onPressed: _selectedIds.isEmpty ? null : () async {
              if (widget.onDelete != null) {
                await widget.onDelete!(_selectedIds);
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
            onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            }),
          ),
        ],
        const Icon(Icons.expand_more),
      ],
    );
  }

  // ПУНКТ СПИСКУ
  Widget _buildItem(DataUsrWiFiInfo info) {
    final bool isSelected = _selectedIds.contains(info.id);
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: _isSelectionMode
              ? Checkbox(
            value: isSelected,
            activeColor: Colors.red,
            onChanged: (_) => _toggleSelection(info.id),
          )
              : const Icon(Icons.router_outlined, color: Colors.blueAccent),
          title: Text(info.ssidWifiBms),
          subtitle: Text("ID: ${info.id} | MAC: ${info.bssidMac}"),
          onTap: () => _isSelectionMode ? _toggleSelection(info.id) : _showInfoDetails(info),
        ),
      ],
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

  // ДІАЛОГ ДЕТАЛЕЙ
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ЗАКРИТИ"),
          ),
          if (widget.onEdit != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onEdit!(info);
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
        crossAxisAlignment: CrossAxisAlignment.start, // Щоб текст рівнявся по верхній лінії, якщо буде 2 рядки
        children: [
          Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13)
          ),
          const SizedBox(width: 12), // Мінімальний відступ між назвою та значенням
          Expanded( // <--- Цей віджет змушує текст вписатися у ширину, що залишилася
            child: Text(
              value,
              textAlign: TextAlign.right, // Зберігаємо логіку "по різних боках"
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              softWrap: true, // Дозволяє перенос на новий рядок, якщо текст дуже довгий
            ),
          ),
        ],
      ),
    );
  }
}