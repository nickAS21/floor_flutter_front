import 'dart:async';
import '../../page/usr_wifi/provision/client/usr_client_device_type.dart';
import 'package:flutter/foundation.dart';

/// Клас для представлення знайденого BLE пристрою
class BleDiscoveredDevice {
  final String id; // MAC-адреса або UUID
  final String name; // Назва пристрою (наприклад, BL602-1A2B)
  final int rssi; // Рівень сигналу
  final UsrClientDeviceType deviceType;

  BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.deviceType,
  });
}

/// Сервіс сканування BLE-ефіру для пошуку ESP32 / BL602
class BleClientScanner {
  final _scanController = StreamController<List<BleDiscoveredDevice>>.broadcast();
  final List<BleDiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;

  Stream<List<BleDiscoveredDevice>> get scanResults => _scanController.stream;
  bool get isScanning => _isScanning;

  /// Запуск сканування BLE-ефіру
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();
    _scanController.add([]);

    try {
      debugPrint("Запуск BLE сканування...");

      // TODO: Інтеграція з нативним/кросплатформеним BLE-сканером (наприклад, flutter_reactive_ble)
      // Під час сканування фільтруємо пристрої за префіксами (ESP-, BL602-)

      // Зупинка сканування по таймауту
      Timer(timeout, stopScan);
    } catch (e) {
      debugPrint("Помилка BLE сканування: $e");
      stopScan();
    }
  }

  /// Зупинка сканування
  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;
    debugPrint("Зупинка BLE сканування.");
  }

  /// Обробка знайденого пристрою (викликається під час BLE-подій)
  void handleDiscoveredDevice({
    required String id,
    required String name,
    required int rssi,
  }) {
    // Перевіряємо, чи належить пристрій до підтримуваних типів (ESP- / BL602-)
    final isEsp = name.startsWith(UsrClientDeviceType.esp.prefix);
    final isBl602 = name.startsWith(UsrClientDeviceType.bl602.prefix);

    if (!isEsp && !isBl602) return;

    final deviceType = isEsp ? UsrClientDeviceType.esp : UsrClientDeviceType.bl602;

    final existingIndex = _discoveredDevices.indexWhere((d) => d.id == id);
    final device = BleDiscoveredDevice(
      id: id,
      name: name,
      rssi: rssi,
      deviceType: deviceType,
    );

    if (existingIndex >= 0) {
      _discoveredDevices[existingIndex] = device;
    } else {
      _discoveredDevices.add(device);
    }

    _scanController.add(List.from(_discoveredDevices));
  }

  void dispose() {
    _scanController.close();
  }
}