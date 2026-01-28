import 'package:flutter/material.dart';
import '../data_home/data_location_type.dart';
import 'info/usr_wifi_info_list_page.dart';
import 'provision/usr_provision_page.dart';

class UsrWifiPage extends StatefulWidget {
  const UsrWifiPage({super.key});

  @override
  State<UsrWifiPage> createState() => _UsrWifiPageState();
}

// lib/page/usr_wifi/usr_wifi_page.dart
class _UsrWifiPageState extends State<UsrWifiPage> {
  LocationType _selectedLocation = LocationType.dacha; // Початковий стан як у MenuPage

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          // ВИКОРИСТОВУЄМО СТИЛЬ З MENU_PAGE
          title: DropdownButton<LocationType>(
            value: _selectedLocation,
            underline: const SizedBox(),
            icon: const SizedBox.shrink(),
            selectedItemBuilder: (BuildContext context) {
              return LocationType.values.map((LocationType loc) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz, size: 20, color: Colors.blueGrey),
                  ],
                );
              }).toList();
            },
            items: LocationType.values.map((LocationType loc) {
              return DropdownMenuItem(
                value: loc,
                child: Row(
                  children: [
                    Text(loc.label),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                  ],
                ),
              );
            }).toList(),
            onChanged: (LocationType? value) {
              if (value != null) setState(() => _selectedLocation = value);
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: "Info"),
              Tab(icon: Icon(Icons.settings_input_antenna), text: "Provision"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UsrWiFiInfoListPage(selectedLocation: _selectedLocation),
            UsrProvisionPage(selectedLocation: _selectedLocation),
          ],
        ),
      ),
    );
  }
}