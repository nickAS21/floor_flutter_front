import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../page/usr_wifi/provision/client/usr_client.dart';
import '../../page/usr_wifi/provision/usr_provision_base.dart';
import 'ble_client_node.dart';
import 'ble_helper_bl602.dart';

class BleProvisionLinux extends UsrProvisionBase {

  BleProvisionLinux();

  @override
  Future<String?> getActiveSsid() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('iwgetid', ['-r']);
        if (result.exitCode == 0) {
          final ssid = result.stdout.toString().trim();
          return ssid.isNotEmpty ? ssid : null;
        }
      }
    } catch (e) {
      debugPrint("Помилка отримання активного SSID (Linux): $e");
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> scanNetworks(String? ssid, UsrClient usrClient,) async {
    final macAddress = usrClient.mac;

    if (macAddress == null || macAddress.isEmpty) {
      debugPrint('[BLE][WIFI][ERROR] MAC-адреса відсутня в ${usrClient.runtimeType}.');
      return [];
    }

    try {
      debugPrint('[BLE][WIFI] Отримання результатів для MAC=$macAddress');

      // final results = await usrClient.getScanResults();
      final results = await usrClient.getScanResults();

      debugPrint(
        '[BLE][WIFI] MAC=$macAddress, отримано записів: ${results.length}',
      );

      return results;
    } catch (e, stackTrace) {
      debugPrint('[BLE][WIFI][ERROR] MAC=$macAddress, error=$e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> rebootDevice(UsrClient usrClient) async {
    try {
      final res = await usrClient.postRestart();

      if (res != "ok") {
        debugPrint(
          '[BLE][REBOOT][ERROR] '
              'MAC=${usrClient.mac}, result=$res',
        );
        return false;
      }

      debugPrint('[BLE][REBOOT][OK] MAC=${usrClient.mac}');
      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[BLE][REBOOT][ERROR] MAC=${usrClient.mac}, error=$e',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}