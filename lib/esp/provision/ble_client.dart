import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../page/usr_wifi/provision/client/usr_client.dart';
import '../../page/usr_wifi/provision/client/usr_client_device_type.dart';
import 'ble_helper_bl602.dart';
import 'ble_helper_esp.dart';

class BleClient implements UsrClient {
  final UsrClientDeviceType deviceType;

  BleClient({this.deviceType = UsrClientDeviceType.bl602});

  @override
  String? mac;

  @override
  String? ssidName;

  /// Підключення до GATT характеристики та отримання MAC/UUID
  @override
  Future<String?> getMacAddress() async {
    try {
      // TODO: Зчитування MAC через BLE характеристику
      return mac;
    } catch (e) {
      debugPrint("BLE getMacAddress Error: $e");
      return null;
    }
  }

  /// Сканування Wi-Fi мереж через BLE
  @override
  Future<List<Map<String, dynamic>>> getScanResults() async {
    try {
      final Uint8List command = deviceType == UsrClientDeviceType.esp
          ? BleHelperEsp.buildWifiScanCommand()
          : BleHelperBl602.buildWifiScanCommand();

      // TODO: Відправка команди в BLE характеристику і очікування responseBytes
      final Uint8List responseBytes = Uint8List(0); // Отримані байти від BLE

      if (deviceType == UsrClientDeviceType.esp) {
        return [];
      } else {
        return BleHelperBl602.parseWifiScanResults(responseBytes);
      }
    } catch (e) {
      debugPrint("BLE getScanResults Error: $e");
      return [];
    }
  }

  /// Збереження Wi-Fi credentials та системних налаштувань (Settings)
  @override
  Future<void> onSaveUpdate({
    required String targetSsid,
    required String targetPass,
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
    bool isRs485Enabled = true,
  }) async {
    // 1. Формування та відправка Wi-Fi реквізитів
    final Uint8List wifiPayload = deviceType == UsrClientDeviceType.esp
        ? BleHelperEsp.buildWifiCredentialsPayload(targetSsid, targetPass)
        : BleHelperBl602.buildWifiCredentialsPayload(targetSsid, targetPass);

    await _writeToBleCharacteristic(wifiPayload);

    // 2. Формування та відправка системних налаштувань (Settings)
    final Uint8List settingsPayload = deviceType == UsrClientDeviceType.esp
        ? BleHelperEsp.buildSettingsPayload(
      moduleSsid: moduleSsid,
      ipA: ipA,
      portA: portA,
      ipB: ipB,
      portB: portB,
      bitrate: bitrate,
    )
        : BleHelperBl602.buildSettingsPayload(
      moduleSsid: moduleSsid,
      ipA: ipA,
      portA: portA,
      ipB: ipB,
      portB: portB,
      bitrate: bitrate,
    );

    await _writeToBleCharacteristic(settingsPayload);

    // 3. Перезавантаження пристрою
    await postRestart();
  }

  @override
  Future<String> postRestart() async {
    try {
      final Uint8List rebootCmd = deviceType == UsrClientDeviceType.esp
          ? BleHelperEsp.buildRebootCommand()
          : BleHelperBl602.buildRebootCommand();

      await _writeToBleCharacteristic(rebootCmd);
      return "ok";
    } catch (e) {
      return "Restart Error: $e";
    }
  }

  /// Приватний метод запису байтів у BLE GATT-характеристику
  Future<void> _writeToBleCharacteristic(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    // TODO: Запис у BLE характеристику через підключений пристрій
  }
}