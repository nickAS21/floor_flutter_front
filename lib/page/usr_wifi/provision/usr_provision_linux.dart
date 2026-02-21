import 'dart:async';
import 'dart:io';
import 'package:floor_front/helpers/app_helper.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:flutter/cupertino.dart';

import 'client/usr_client.dart';

class UsrProvisionLinux extends UsrProvisionBase {

  @override
  Future<List<Map<String, dynamic>>> scanNetworks(String? ssid, UsrClient usrClient) async {
    List<Map<String, dynamic>> found = [];
    try {
      if (ssid.isBlank &&  usrClient.mac.isBlank) { // start without device wifi All linux
        return getLinuxWifi();
      } else if (ssid.isNotBlank) {     // start connect device
        return connectDeviceApWiFiToLinux(ssid!);
      } else {                          // start wifi device
        int attempts = 0;
        while (attempts < 3) {
          try {
            if (attempts > 0) {
              debugPrint("Ретрай №${attempts + 1}. SSID: ${usrClient.ssidName}");
              await connectDeviceApWiFiToLinux(usrClient.ssidName!);
              await Future.delayed(const Duration(seconds: 2));
            }

            // КЛЮЧОВИЙ МОМЕНТ: додаємо timeout прямо тут
            // Якщо getScanResults не відповість за 5 секунд, вилетить TimeoutException
            // і ми нарешті потрапимо в блок catch, а потім на наступне коло while
            return await usrClient.getScanResults().timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException("USR module not responding"),
            );

          } catch (e) {
            attempts++;
            debugPrint("Спроба $attempts невдала: $e");
            if (attempts >= 3) return [];
          }
        }
        return [];
      }
    } catch (e) {
      print("Linux scan error: $e");
    }
    return found;
  }

  // String _formatBssid(String raw) {
  //   if (raw.length != 12) return raw.toUpperCase();
  //   return raw
  //       .replaceAllMapped(RegExp(r".{2}"), (match) => "${match.group(0)}:")
  //       .substring(0, 17)
  //       .toUpperCase();
  // }

  Future<List<Map<String, dynamic>>> getLinuxWifi() async {
    List<Map<String, dynamic>> found = [];
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
    }
    return found;
  }
  
  Future<List<Map<String, dynamic>>> connectDeviceApWiFiToLinux(String ssid) async {
    List<Map<String, dynamic>> found = [];
    try {
      final result = await Process.run('nmcli', [
        'device', 'wifi', 'connect', ssid
      ]);

      if (result.exitCode == 0) {
        // Чекаємо DHCP, щоб наступний initDevice спрацював
        await Future.delayed(const Duration(seconds: 4));
          debugPrint("Підключено успішно до $ssid.");
          // Даємо 1 секунду на те, щоб Linux-стек (DHCP) видав IP
          await Future.delayed(const Duration(seconds: 1));
          found = [
            {'connected': ssid}
          ];
      } else {
        debugPrint("Не вдалося підключитися до $ssid.");
      }
      return found;
    } catch (e) {
      print("Linux Connect Exception: $e");
      return found;
    }
  }

  @override
  Future<String?> getActiveSsid() async {
    try {
      // Команда повертає тільки SSID активного з'єднання
      final result = await Process.run('nmcli', [
        '-t',
        '-f', 'active,ssid',
        'dev', 'wifi'
      ]);

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          // nmcli -t повертає рядки типу "yes:MyWiFiName"
          if (line.startsWith('yes:')) {
            return line.replaceFirst('yes:', '').trim();
          }
        }
      }
    } catch (e) {
      print("Помилка при визначенні SSID: $e");
    }
    return null;
  }
}