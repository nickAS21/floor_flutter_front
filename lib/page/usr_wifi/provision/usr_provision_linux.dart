import 'dart:async';
import 'dart:io';
import 'package:floor_front/helpers/app_helper.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:flutter/cupertino.dart';

import '../../../esp/provision/bl602_wifi_network.dart';
import '../../../esp/provision/ble_client_node.dart';
import '../../../esp/provision/ble_helper_bl602.dart';
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
              const Duration(seconds: 30),
              onTimeout: () {
                final isBle = usrClient is BleClientNode;
                final errorMsg = isBle
                    ? "BLE Node module not responding"
                    : "USR module not responding";
                throw TimeoutException(errorMsg);
              },
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

  Future<List<Map<String, dynamic>>> getLinuxWifi() async {
    final List<Bl602WifiNetwork> foundModels = [];
    final result = await Process.run('nmcli', [
      '-t',
      '-f', 'SSID,SIGNAL,BSSID',
      'dev', 'wifi', 'list'
    ]);

    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split('\n');
      final Map<String, Bl602WifiNetwork> uniqueNetworks = {};

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // MAC-адреса BSSID завжди займає останні 17 символів (XX:XX:XX:XX:XX:XX)
        // Використання розділення з кінця захищає від двокрапок усередині SSID
        final parts = line.split(':');
        if (parts.length >= 8) {
          // BSSID складається з останніх 6 сегментів
          final bssid = parts.sublist(parts.length - 6).join(':').trim().toUpperCase();

          // SIGNAL — це передостанній елемент перед BSSID (індекс length - 7)
          final signal = int.tryParse(parts[parts.length - 7]) ?? -100;

          // SSID — все, що йде до SIGNAL
          final ssid = parts.sublist(0, parts.length - 7).join(':').trim();

          if (ssid.isNotEmpty && ssid != "--") {
            final network = Bl602WifiNetwork(
              ssid: ssid,
              bssid: bssid,
              rssi: signal,
              channel: 0,
              auth: 0,
              state: Bl602BleWifiState.WIFI_STATE_UNKNOWN,
            );

            // Фільтрація дублікатів за найсильнішим сигналом
            if (!uniqueNetworks.containsKey(ssid) ||
                signal > uniqueNetworks[ssid]!.rssi) {
              uniqueNetworks[ssid] = network;
            }
          }
        }
      }
      foundModels.addAll(uniqueNetworks.values);
    }

    // Конвертуємо в Map для сумісності з UsrClient
    return foundModels.map((network) => network.toJson()).toList();
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