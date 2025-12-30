import 'package:flutter/material.dart';
import 'data_home/data_location_type.dart';
import 'data_home/data_home_page.dart';
import 'logs/logs_page.dart';
import 'settings/settings_page.dart';
import 'unit/unit_page.dart'; // Новий імпорт
import 'login/login_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() =>  _MenuPageState();
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
      UnitPage(location: _selectedLocation), // Додано UnitPage
      LogsPage(location: _selectedLocation),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onLocationChanged(LocationType? value) {
    if (value == null) return;
    setState(() {
      _selectedLocation = value;
      _buildPages();
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
        title: DropdownButton<LocationType>(
          value: _selectedLocation,
          underline: const SizedBox(),
          icon: const SizedBox.shrink(),
          dropdownColor: Colors.white,
          selectedItemBuilder: (BuildContext context) {
            return [LocationType.dacha, LocationType.golego].map((LocationType loc) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc == LocationType.dacha ? "Dacha" : "Golego",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.swap_horiz, size: 20, color: Colors.blueGrey),
                ],
              );
            }).toList();
          },
          items: const [
            DropdownMenuItem(
              value: LocationType.dacha,
              child: Row(
                children: [
                  Text("Dacha"),
                  SizedBox(width: 8),
                  Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                ],
              ),
            ),
            DropdownMenuItem(
              value: LocationType.golego,
              child: Row(
                children: [
                  Text("Golego"),
                  SizedBox(width: 8),
                  Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ],
          onChanged: _onLocationChanged,
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Щоб вмістити 4 іконки
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _selectedLocation == LocationType.dacha ? "Dacha" : "Golego",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.developer_board), // Іконка плати/юніта
            label: "Control Unit",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Logs",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _signOut,
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }
}