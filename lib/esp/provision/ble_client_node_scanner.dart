import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../page/usr_wifi/provision/client/usr_client_node_type.dart';

/// Клас для представлення знайденого BLE пристрою
class BleClientNodeDiscovered {
  final String id; // MAC-адреса
  final String name; // Назва пристрою
  final int rssi; // Рівень сигналу
  final UsrClientNodeType clientNodeType;

  BleClientNodeDiscovered({
    required this.id,
    required this.name,
    required this.rssi,
    required this.clientNodeType,
  });
}

/// Сервіс сканування та підключення BLE-ефіру для пошуку ESP32 / BL602
class BleClientNodeScanner {
  final _scanController = StreamController<List<BleClientNodeDiscovered>>.broadcast();
  final List<BleClientNodeDiscovered> _discoveredDevices = [];
  bool _isScanning = false;

  Stream<List<BleClientNodeDiscovered>> get scanResults => _scanController.stream;
  List<BleClientNodeDiscovered> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  bool get isScanning => _isScanning;

  /// Надійне сканування BLE через читання реального stdout потоку bluetoothctl
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();
    _scanController.add([]);

    try {
      debugPrint("Запуск BLE сканування...");

      if (Platform.isLinux) {
        // 1. Спочатку читаємо вже відомі пристрої з системи
        final devicesResult = await Process.run('bluetoothctl', ['devices']);
        if (devicesResult.exitCode == 0) {
          _parseDevicesOutput(devicesResult.stdout.toString());
        }

        // 2. Запускаємо фоновий процес сканування і перехоплюємо live-stdout
        final process = await Process.start('bluetoothctl', ['scan', 'on']);

        final subscription = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          _parseScanLine(line);
        });

        // Чекаємо заданий таймаут сканування
        await Future.delayed(timeout);

        // Зупиняємо фоновий процес сканування
        await subscription.cancel();
        process.kill();
        await Process.run('bluetoothctl', ['scan', 'off']);
      }
    } catch (e) {
      debugPrint("Помилка BLE сканування: $e");
    } finally {
      _isScanning = false;
      _scanController.add(List.from(_discoveredDevices));
      debugPrint("КРОК 5.1: Зупинка BLE сканування. Знайдено: ${_discoveredDevices.length}");
    }
  }

  /// Парсинг рядків виводу bluetoothctl (наприклад, [NEW] Device 80:65:99:XX:XX:XX ESP-1A2B)
  void _parseScanLine(String line) {
    final regExp = RegExp(r'(?:Device|\[NEW\]\s+Device)\s+([0-9A-Fa-f:]{17})\s+(.+)');
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

  /// Парсинг статичного списку 'bluetoothctl devices'
  void _parseDevicesOutput(String output) {
    final lines = output.split('\n');
    for (var line in lines) {
      _parseScanLine(line);
    }
  }

  /// Зупинка сканування
  Future<void> stopScan() async {
    if (!_isScanning) return;
    _isScanning = false;
    _scanController.add(List.from(_discoveredDevices));
    debugPrint("Зупинка BLE сканування.");
  }

  /// Обробка знайденого пристрою
  void handleDiscoveredDevice({
    required String id,
    required String name,
    required int rssi,
  }) {
    if (name.isEmpty || name == "[unknown]") return;

    final nameUpper = name.toUpperCase();
    final isEsp = nameUpper.startsWith(UsrClientNodeType.esp.prefix.toUpperCase());
    final isBl602 = nameUpper.startsWith(UsrClientNodeType.bl602.prefix.toUpperCase());

    if (!isEsp && !isBl602) return;

    final deviceType = isEsp ? UsrClientNodeType.esp : UsrClientNodeType.bl602;

    final existingIndex = _discoveredDevices.indexWhere((d) => d.id == id);
    final device = BleClientNodeDiscovered(
      id: id,
      name: name,
      rssi: rssi,
      clientNodeType: deviceType,
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