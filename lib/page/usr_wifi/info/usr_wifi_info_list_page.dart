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
    return FutureBuilder<DataUsrWiFiInfo>(
      future: _storage.loadInfo(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final info = snapshot.data!;

        return Card(
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(Icons.wifi_tethering,
                color: type == LocationType.golego ? Colors.green : Colors.orange),
            title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SSID: ${info.ssidWifiBms.isEmpty ? "Не вказано" : info.ssidWifiBms}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('ID (calculated):', info.id.toString()),
                    _infoRow('MAC:', info.bssidMac),
                    _infoRow('Server (NetA):', '${info.netIpA}:${info.netAPort}'),
                    _infoRow('Device (NetB):', '${info.netIpB}:${info.netBPort}'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _editInfo(info),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Редагувати локально'),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
}