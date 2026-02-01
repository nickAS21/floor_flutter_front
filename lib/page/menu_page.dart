import 'package:floor_front/page/usr_wifi/connection_server/usr_wifi_info_lists_page.dart';
import 'package:flutter/material.dart';
import 'data_home/data_location_type.dart';
import 'data_home/data_home_page.dart';
import 'logs/logs_page.dart';
import 'settings/settings_page.dart';
import 'unit/unit_page.dart';
import 'history/history_page.dart';
import 'analytics/analytics_page.dart';
import 'alarm/alarm_page.dart';
import 'login/login_page.dart';
import 'usr_wifi/info/usr_wifi_info_list_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  LocationType _selectedLocation = LocationType.dacha;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      HomePage(location: _selectedLocation),
      SettingsPage(location: _selectedLocation),
      UnitPage(location: _selectedLocation),
      UsrWiFiInfoListsPage(selectedLocation: _selectedLocation),
      HistoryPage(location: _selectedLocation),
      AnalyticsPage(location: _selectedLocation),
      AlarmPage(location: _selectedLocation),
      LogsPage(location: _selectedLocation),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Вибір локації, який оновлює всі сторінки
  void _onLocationChanged(LocationType? value) {
    if (value == null) return;
    setState(() {
      _selectedLocation = value;
      _buildPages(); // Перебудовуємо сторінки з новою локацією
    });
  }

  void _signOut() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // ВАШ СТИЛЬ ВИБОРУ ЛОКАЦІЇ
        title: DropdownButton<LocationType>(
          value: _selectedLocation,
          underline: const SizedBox(),
          icon: const SizedBox.shrink(),
          dropdownColor: Colors.white,
          selectedItemBuilder: (BuildContext context) {
            return LocationType.values.map((LocationType loc) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
          onChanged: _onLocationChanged,
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedFontSize: 11,
        unselectedFontSize: 9,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _selectedLocation.label,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.developer_board),
            label: "Unit",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: "UsrInfos",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analytics",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notification_important),
            label: "Alarm",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Logs",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _signOut,
        mini: true,
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }
}