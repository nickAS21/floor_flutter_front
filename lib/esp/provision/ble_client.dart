import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../page/usr_wifi/provision/client/connect_interface_type.dart';
import '../../page/usr_wifi/provision/client/usr_client.dart';
import '../../page/usr_wifi/provision/client/usr_client_device_type.dart';
import '../info/data_esp_bms_info.dart';
import 'ble_helper_bl602.dart';
import 'ble_helper_esp.dart';

class BleClient implements UsrClient {
  final UsrClientDeviceType deviceType;

  BleClient({this.deviceType = UsrClientDeviceType.bl602});

  @override
  String? mac;

  @override
  String? ssidName;

  /// Список знайдених кінцевих девайсів (BMS по BLE та RS485)
  List<DataEspBmsInfo> bmsList = [];

  /// Вибраний кінцевий пристрій з списку bmsList
  DataEspBmsInfo? selectedBms;

  @override
  Future<String?> getMacAddress() async {
    try {
      // Зчитування MAC через BLE характеристику
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

      final Uint8List responseBytes = Uint8List(0); // Відповідь від BLE

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

  /// Послідовне сканування кінцевих девайсів: спочатку BLE, потім RS485
  Future<List<DataEspBmsInfo>> scanTargetDevices() async {
    bmsList.clear();

    // 1. Спочатку BLE сканування
    final bleBmsItems = await _scanBleTargetDevices();
    bmsList.addAll(bleBmsItems);

    // 2. Потім RS485 опитування
    final rs485BmsItems = await _scanRs485TargetDevices();
    bmsList.addAll(rs485BmsItems);

    return bmsList;
  }

  /// Сканування кінцевих BLE BMS пристроїв довкола шлюзу
  Future<List<DataEspBmsInfo>> _scanBleTargetDevices() async {
    try {
      debugPrint("Сканування BLE-девайсів (BMS)...");
      // TODO: Відправка команди на шлюз для BLE-сканування BMS та парсинг результатів
      return [];
    } catch (e) {
      debugPrint("Помилка сканування BLE BMS: $e");
      return [];
    }
  }

  /// Опитування девайсів на шині RS485
  Future<List<DataEspBmsInfo>> _scanRs485TargetDevices() async {
    try {
      debugPrint("Опитування RS485-девайсів (BMS)...");
      // TODO: Відправка команди на шлюз для RS485-опитування BMS та парсинг результатів
      return [];
    } catch (e) {
      debugPrint("Помилка опитування RS485 BMS: $e");
      return [];
    }
  }

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
    // 1. Формування та відправка Wi-Fi credentials
    final Uint8List wifiPayload = deviceType == UsrClientDeviceType.esp
        ? BleHelperEsp.buildWifiCredentialsPayload(targetSsid, targetPass)
        : BleHelperBl602.buildWifiCredentialsPayload(targetSsid, targetPass);

    await _writeToBleCharacteristic(wifiPayload);

    // 2. Формування та відправка системних налаштувань
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

    // 3. Перезавантаження
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
  }
}