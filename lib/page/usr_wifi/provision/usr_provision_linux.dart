import 'dart:io';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';

class UsrProvisionLinux extends UsrProvisionBase {

  @override
  Future<List<Map<String, dynamic>>> scanNetworks(String? mac) async {
    List<Map<String, dynamic>> found = [];

    try {
      // Повертаємося до стандартного виклику без додаткових сепараторів
      final result = await Process.run('nmcli', [
        '-t',
        '-f', 'SSID,SIGNAL,BSSID',
        'dev', 'wifi', 'list'
      ]);

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final Map<String, Map<String, dynamic>> uniqueNetworks = {};

        for (var line in lines) {
          if (line.isEmpty) continue;

          final parts = line.split(':');
          // Оскільки в MAC-адресі 5 двокрапок (напр. AA:BB:CC:DD:EE:FF),
          // nmcli -t розіб'є її на 6 частин.
          // Структура рядка буде: [SSID, SIGNAL, MAC1, MAC2, MAC3, MAC4, MAC5, MAC6]
          if (parts.length >= 8) {
            final String ssid = parts[0].trim();
            final int signal = int.tryParse(parts[1]) ?? 0;

            // Збираємо MAC назад, об'єднуючи елементи з 2-го до кінця
            final String bssid = parts
                .sublist(2)
                .join(':')
                .trim()
                .toUpperCase();

            if (ssid.isNotEmpty && ssid != "--") {
              if (!uniqueNetworks.containsKey(ssid) ||
                  signal > (uniqueNetworks[ssid]!['level'] ?? 0)) {
                uniqueNetworks[ssid] = {
                  'ssid': ssid,
                  'level': signal,
                  'bssid': bssid,
                };
              }
            }
          }
        }

        found = uniqueNetworks.values.toList();

        if (mac != null && mac.isNotEmpty) {
          // Очищаємо вхідний MAC так само жорстко
          final String searchMac = mac
              .replaceAll('\\', '')
              .replaceAll(':', '')
              .toUpperCase();
          found = found.where((net) {
            final String searchNet = net['bssid'].toString().replaceAll(
                '\\', '').replaceAll(':', '').toUpperCase();
            return  searchNet != searchMac;
          }).toList();
        }
      }
    } catch (e) {
      print("Linux scan error: $e");
    }
    return found;
  }
}