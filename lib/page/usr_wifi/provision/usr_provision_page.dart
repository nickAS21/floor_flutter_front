import 'package:floor_front/page/usr_wifi/provision/usr_provision_udp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'usr_provision_web_page.dart';
import '../../data_home/data_location_type.dart';

// lib/page/usr_wifi/provision/usr_provision_page.dart

class UsrProvisionPage extends StatelessWidget {
  final LocationType selectedLocation; // [1] Додаємо поле

  const UsrProvisionPage({
    super.key,
    required this.selectedLocation // [2] Обов'язковий конструктор
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return UsrProvisionWebPage(selectedLocation: selectedLocation); // [3] Передаємо далі
    } else {
      return UsrProvisionUdpPage(selectedLocation: selectedLocation); // [3] Передаємо далі
    }
  }
}