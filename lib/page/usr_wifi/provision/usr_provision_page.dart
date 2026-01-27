import 'package:floor_front/page/usr_wifi/provision/usr_provision_udp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'usr_provision_web_page.dart';

class UsrProvisionPage extends StatelessWidget {
  const UsrProvisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return const UsrProvisionWebPage();
    } else {
      return const UsrProvisionUdpPage();
    }
  }
}