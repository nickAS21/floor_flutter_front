import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../page/usr_wifi/provision/client/usr_client_device_type.dart';

/// Клас для представлення знайденого BLE пристрою
class BleDiscoveredDevice {
  final String id; // MAC-адреса або UUID
  final String name; // Назва пристрою (наприклад, ESP-1A2B)
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
  List<BleDiscoveredDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  bool get isScanning => _isScanning;

  /// Запуск сканування BLE-ефіру у Linux через bluetoothctl
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();
    _scanController.add([]);

    try {
      debugPrint("Запуск BLE сканування...");

      if (Platform.isLinux) {
        // 1. Запускаємо сканування BLE на вказаний час
        await Process.run('bluetoothctl', ['--', 'timeout', '${timeout.inSeconds}', 'scan', 'on']);

        // 2. Отримуємо накопичений перелік пристроїв
        final devicesResult = await Process.run('bluetoothctl', ['devices']);
        if (devicesResult.exitCode == 0) {
          _parseDevicesOutput(devicesResult.stdout.toString());
        }
      }
    } catch (e) {
      debugPrint("Помилка BLE сканування: $e");
    } finally {
      _isScanning = false;
      _scanController.add(List.from(_discoveredDevices));
      debugPrint("Зупинка BLE сканування. Знайдено: ${_discoveredDevices.length}");
    }
  }

  /// Парсинг виводу 'bluetoothctl devices'
  void _parseDevicesOutput(String output) {
    final lines = output.split('\n');
    final regExp = RegExp(r'^Device\s+([0-9A-Fa-f:]{17})\s+(.+)');

    for (var line in lines) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final mac = match.group(1) ?? '';
        final name = (match.group(2) ?? '').trim();

        handleDiscoveredDevice(
          id: mac,
          name: name,
          rssi: -60,
        );
      }
    }
  }

  /// Зупинка сканування
  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;
    _scanController.add(List.from(_discoveredDevices));
    debugPrint("Зупинка BLE сканування.");
  }

  /// Обробка знайденого пристрою (викликається під час BLE-подій)
  void handleDiscoveredDevice({
    required String id,
    required String name,
    required int rssi,
  }) {
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