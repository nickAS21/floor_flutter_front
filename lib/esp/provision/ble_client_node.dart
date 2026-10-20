import 'dart:async';
import 'dart:typed_data';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../../page/usr_wifi/provision/client/usr_client.dart';
import '../../page/usr_wifi/provision/client/usr_client_node_type.dart';
import '../info/data_esp_bms_info.dart';
import 'ble_helper_bl602.dart';
import 'ble_helper_esp.dart';

class BleClientNode implements UsrClient {
  UsrClientNodeType deviceType;

  Future<List<DataEspBmsInfo>> _scanBleTargetDevices() async => [];
  Future<List<DataEspBmsInfo>> _scanRs485TargetDevices() async => [];

  DBusClient? _notifyClient;
  StreamSubscription<DBusSignal>? _notifySubscription;
  Completer<Uint8List>? _notifyCompleter;
  String? _notifyCharPath;

  BleClientNode({this.deviceType = UsrClientNodeType.bl602});

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
      return mac;
    } catch (e) {
      debugPrint("BLE getMacAddress Error: $e");
      return null;
    }
  }

  /// Сканування Wi-Fi мереж через BLE D-Bus
  Future<List<Map<String, dynamic>>> getScanResults() async {
    try {
      final scanCommand = BleHelperBl602.buildWifiScanCommand();

      debugPrint('КРОК 5.: [BLE][WIFI_SCAN][TX] CMD_WIFI_SCAN (9) - START');

      if (!await _writeToBleCharacteristic(scanCommand)) {
        throw StateError('Не вдалося надіслати CMD_WIFI_SCAN.');
      }

      final networks = <Map<String, dynamic>>[];
      final seenBssids = <String>{};

      const maxRequests = 50;

      for (var i = 0; i < maxRequests; i++) {
        final command = BleHelperBl602.buildWifiDataGetCommand();

        if (!await _writeToBleCharacteristic(command)) {
          debugPrint('[BLE][WIFI_SCAN][ABORT] Запис не удався. Зупинка циклу.');
          break; // ЗУПИНЯЄМО ЦИКЛ ОДРАЗУ, НЕ КРУТИМО 50 РАЗІВ!
        }

        final response = await _readBleCharacteristic();

        debugPrint(
          '[BLE][WIFI_SCAN][RX] '
              'request=${i + 1}, bytes=${response.length}',
        );

        final network = BleHelperBl602.parseWifiDataResponse(response);

        if (network == null) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        final ssid = network['ssid'] as String? ?? '';
        final bssid = network['bssid'] as String? ?? '';

        if (ssid.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        final key = bssid.isNotEmpty ? bssid : ssid;

        if (seenBssids.add(key)) {
          networks.add(network);

          debugPrint(
            '[BLE][WIFI_SCAN][NETWORK] '
                'SSID=$ssid, BSSID=$bssid, '
                'RSSI=${network['rssi']}, '
                'channel=${network['channel']}',
          );
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }

      debugPrint(
        '[BLE][WIFI_SCAN][RESULT], networks=${networks.length}',
      );

      return networks;
    } catch (e, stackTrace) {
      debugPrint('[BLE][WIFI_SCAN][ERROR], error=$e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  /// Підключення до BLE Node та пошук GATT-характеристики за UUID
  Future<String?> _findCharacteristicPath(
      DBusClient client,
      String devicePath, {
        bool forWrite = true,
      }) async {
    const deviceInterface = 'org.bluez.Device1';
    const propertiesInterface = 'org.freedesktop.DBus.Properties';
    const characteristicInterface = 'org.bluez.GattCharacteristic1';

    final targetUuid = forWrite
        ? BleHelperBl602.BASE_UUID_HOST_WRITE
        : BleHelperBl602.BASE_UUID_HOST_READ;

    final deviceMac = devicePath.split('dev_').last.replaceAll('_', ':');

    final deviceObject = DBusRemoteObject(
      client,
      name: 'org.bluez',
      path: DBusObjectPath(devicePath),
    );

    final objectManager = DBusRemoteObject(
      client,
      name: 'org.bluez',
      path: DBusObjectPath('/'),
    );

    Future<bool?> getConnected() async {
      try {
        final result = await deviceObject.callMethod(
          propertiesInterface,
          'Get',
          [
            const DBusString(deviceInterface),
            const DBusString('Connected'),
          ],
        );

        if (result.returnValues.isEmpty) {
          return null;
        }

        final variant = result.returnValues.first;
        if (variant is DBusVariant && variant.value is DBusBoolean) {
          return (variant.value as DBusBoolean).value;
        }
      } catch (e) {
        if (e.toString().contains('UnknownObject')) {
          return false;
        }
        debugPrint('[BLE][PROPERTY][ERROR] MAC=$deviceMac, property=Connected, error=$e');
      }

      return null;
    }

    try {
      var connected = await getConnected() ?? false;

      if (!connected) {
        debugPrint('[BLE][CONNECT] MAC=$deviceMac: підключення...');

        try {
          await deviceObject.callMethod(
            deviceInterface,
            'Connect',
            [],
          );
        } catch (e) {
          debugPrint(
            '[BLE][CONNECT][INFO] MAC=$deviceMac, result=$e',
          );
        }
      }

      final connectDeadline =
      DateTime.now().add(const Duration(seconds: 15));

      while (DateTime.now().isBefore(connectDeadline)) {
        connected = await getConnected() ?? false;

        if (connected) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!connected) {
        debugPrint(
          '[BLE][CONNECT][ERROR] MAC=$deviceMac: тайм-аут підключення.',
        );
        return null;
      }

      debugPrint('[BLE][CONNECT][OK] MAC=$deviceMac');

      final discoveryDeadline =
      DateTime.now().add(const Duration(seconds: 15));

      while (DateTime.now().isBefore(discoveryDeadline)) {
        connected = await getConnected() ?? false;

        if (!connected) {
          debugPrint(
            '[BLE][GATT][ERROR] MAC=$deviceMac: '
                'з`єднання втрачено під час пошуку характеристики.',
          );
          return null;
        }

        try {
          final managedObjects = await objectManager.callMethod(
            'org.freedesktop.DBus.ObjectManager',
            'GetManagedObjects',
            [],
          );

          if (managedObjects.returnValues.isNotEmpty) {
            final objectsMap =
            managedObjects.returnValues.first as DBusDict;

            for (final entry in objectsMap.children.entries) {
              final objectPath = (entry.key as DBusObjectPath).value;

              if (!objectPath.startsWith('$devicePath/')) {
                continue;
              }

              final interfaces = entry.value as DBusDict;

              final characteristicValue =
              interfaces.children[const DBusString(characteristicInterface)];

              if (characteristicValue is! DBusDict) {
                continue;
              }

              final uuidValue = characteristicValue.children[const DBusString('UUID')];

              if (uuidValue is! DBusVariant || uuidValue.value is! DBusString) {
                continue;
              }

              final uuid = (uuidValue.value as DBusString).value.toLowerCase();

              if (uuid == targetUuid) {
                return objectPath;
              }
            }
          }
        } catch (e, stackTrace) {
          debugPrint(
            '[BLE][GATT][DISCOVERY][ERROR] MAC=$deviceMac, '
                'UUID=$targetUuid, error=$e',
          );
          debugPrintStack(stackTrace: stackTrace);
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      debugPrint(
        '[BLE][GATT][ERROR] MAC=$deviceMac: '
            'характеристику $targetUuid не знайдено за 15 секунд.',
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint(
        '[BLE][GATT][ERROR] MAC=$deviceMac, error=$e',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Запис байтів у BLE GATT-характеристику FF01 через D-Bus
  Future<bool> _writeToBleCharacteristic(Uint8List bytes) async {
    if (bytes.isEmpty) {
      debugPrint('[BLE][WRITE][ERROR] Дані для запису порожні.');
      return false;
    }

    final deviceMac = mac;
    if (deviceMac == null || deviceMac.isEmpty) {
      debugPrint('[BLE][WRITE][ERROR] MAC-адреса пристрою не задана.');
      return false;
    }

    final devicePath =
        '/org/bluez/hci0/dev_${deviceMac.replaceAll(':', '_').toUpperCase()}';

    DBusClient? client;

    try {
      client = DBusClient.system();

      final characteristicPath = await _findCharacteristicPath(
        client,
        devicePath,
        forWrite: true,
      );

      if (characteristicPath == null) {
        debugPrint(
          '[BLE][WRITE][ERROR] MAC=$deviceMac: Характеристику не знайдено / пристрій відключився.',
        );
        return false;
      }

      final object = DBusRemoteObject(
        client,
        name: 'org.bluez',
        path: DBusObjectPath(characteristicPath),
      );

      debugPrint(
        '[BLE][WRITE][TX] length=${bytes.length}, '
            'hex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      await object.callMethod(
        'org.bluez.GattCharacteristic1',
        'WriteValue',
        [
          DBusArray.byte(bytes),
          DBusDict.stringVariant({}),
        ],
      );

      debugPrint('[BLE][WRITE][OK] length=${bytes.length}');

      return true;
    } catch (e) {
      debugPrint('[BLE][WRITE][ERROR] MAC=$deviceMac, error=$e');
      return false;
    } finally {
      await client?.close();
    }
  }

  /// Очікування байтів із BLE GATT-характеристики FF02 через Notifications
  Future<Uint8List> _readFromBleCharacteristic() async {
    final deviceMac = mac;

    if (deviceMac == null || deviceMac.isEmpty) {
      debugPrint('[BLE][READ][ERROR] MAC-адреса пристрою не задана.');
      return Uint8List(0);
    }

    final completer = _notifyCompleter;

    if (completer == null) {
      debugPrint(
        '[BLE][READ][ERROR] MAC=$deviceMac, UUID=${BleHelperBl602.BASE_UUID_HOST_READ}: '
            'Notifications не запущені.',
      );
      return Uint8List(0);
    }

    try {
      final bytes = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint(
            '[BLE][NOTIFY][TIMEOUT] '
                'MAC=$deviceMac, UUID=${BleHelperBl602.BASE_UUID_HOST_READ}: '
                'відповідь не отримано за 20 секунд.',
          );
          return Uint8List(0);
        },
      );

      debugPrint(
        '[BLE][READ][OK] MAC=$deviceMac, UUID=${BleHelperBl602.BASE_UUID_HOST_READ}, '
            'bytes=${bytes.length}, '
            'hex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      return bytes;
    } catch (e, stackTrace) {
      debugPrint(
        '[BLE][READ][ERROR] MAC=$deviceMac, UUID=${BleHelperBl602.BASE_UUID_HOST_READ}, error=$e',
      );
      debugPrintStack(stackTrace: stackTrace);
      return Uint8List(0);
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
    if (deviceType == UsrClientNodeType.esp) {
      // TODO: Реалізувати для ESP32
      return;
    }

    // 1. Увімкнути сповіщення FF02
    if (!await _startBleNotifications()) {
      throw Exception('Не вдалося запустити BLE Notifications (FF02).');
    }

    // 2. Передати SSID
    final ssidSent = await _writeToBleCharacteristic(
      BleHelperBl602.buildWifiSsidPacket(targetSsid),
    );

    if (!ssidSent) {
      throw Exception('Не вдалося передати SSID через BLE.');
    }

    // 3. Передати пароль
    final passwordSent = await _writeToBleCharacteristic(
      BleHelperBl602.buildWifiPasswordPacket(targetPass),
    );

    if (!passwordSent) {
      throw Exception('Не вдалося передати пароль через BLE.');
    }

    // 4. Запустити підключення до Wi-Fi
    final connectSent = await _writeToBleCharacteristic(
      BleHelperBl602.buildWifiConnectSetCommand(),
    );

    if (!connectSent) {
      throw Exception('Не вдалося надіслати CMD_CONNECT_WIFI.');
    }

    debugPrint(
      '[BLE][WIFI_CONNECT] SSID і пароль передані, '
          'CMD_CONNECT_WIFI надіслано.',
    );
  }

  @override
  Future<String> postRestart() async {
    try {
      final Uint8List rebootCmd = deviceType == UsrClientNodeType.esp
          ? BleHelperEsp.buildRebootCommand()
          : BleHelperBl602.buildRebootCommand();

      final success = await _writeToBleCharacteristic(rebootCmd);
      return success ? "ok" : "Restart Error: Write failed";
    } catch (e) {
      return "Restart Error: $e";
    }
  }

  Future<List<DataEspBmsInfo>> scanTargetDevices() async {
    bmsList.clear();
    final bleBmsItems = await _scanBleTargetDevices();
    bmsList.addAll(bleBmsItems);
    final rs485BmsItems = await _scanRs485TargetDevices();
    bmsList.addAll(rs485BmsItems);
    return bmsList;
  }

  /// Надсилає лише Wi-Fi credentials через BLE
  Future<bool> sendWifiCredentialsPayload(Uint8List payload) {
    return _writeToBleCharacteristic(payload);
  }

  Future<bool> _startBleNotifications() async {
    final deviceMac = mac;
    if (deviceMac == null || deviceMac.isEmpty) {
      debugPrint('[BLE][NOTIFY][ERROR] MAC не задано.');
      return false;
    }

    final devicePath =
        '/org/bluez/hci0/dev_${deviceMac.replaceAll(':', '_').toUpperCase()}';

    try {
      await _stopBleNotifications();

      final client = DBusClient.system();
      _notifyClient = client;

      final charPath = await _findCharacteristicPath(
        client,
        devicePath,
        forWrite: false,
      );

      if (charPath == null) {
        debugPrint(
          '[BLE][NOTIFY][ERROR] '
              'MAC=$deviceMac, UUID=${BleHelperBl602.BASE_UUID_HOST_READ}: характеристику не знайдено.',
        );
        await _stopBleNotifications();
        return false;
      }

      _notifyCharPath = charPath;
      _notifyCompleter = Completer<Uint8List>();

      final stream = DBusSignalStream(
        client,
        sender: 'org.bluez',
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
        path: DBusObjectPath(charPath),
      );

      _notifySubscription = stream.listen(
            (signal) {
          if (signal.values.length < 2) return;

          final interfaceValue = signal.values[0];
          final propertiesValue = signal.values[1];

          if (interfaceValue is! DBusString ||
              interfaceValue.value != 'org.bluez.GattCharacteristic1' ||
              propertiesValue is! DBusDict) {
            return;
          }

          final properties = propertiesValue.mapStringVariant();
          final value = properties['Value'];

          if (value == null) return;

          final rawValue = value is DBusVariant ? value.value : value;

          if (rawValue is! DBusArray) return;

          final bytes = <int>[];

          for (final item in rawValue.children) {
            if (item is! DBusByte) return;
            bytes.add(item.value);
          }

          if (bytes.isEmpty) return;

          debugPrint(
            '[BLE][NOTIFY][RX] MAC=$deviceMac, '
                'bytes=${bytes.length}, '
                'hex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          );

          final completer = _notifyCompleter;

          if (completer != null && !completer.isCompleted) {
            completer.complete(Uint8List.fromList(bytes));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[BLE][NOTIFY][STREAM][ERROR] $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );

      final charObject = DBusRemoteObject(
        client,
        name: 'org.bluez',
        path: DBusObjectPath(charPath),
      );

      await charObject.callMethod(
        'org.bluez.GattCharacteristic1',
        'StartNotify',
        [],
      );

      debugPrint(
        '[BLE][NOTIFY][OK] MAC=$deviceMac, '
            'UUID=${BleHelperBl602.BASE_UUID_HOST_READ}, path=$charPath',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('[BLE][NOTIFY][ERROR] MAC=$deviceMac, error=$e');
      debugPrintStack(stackTrace: stackTrace);

      await _stopBleNotifications();
      return false;
    }
  }

  Future<void> _stopBleNotifications() async {
    final client = _notifyClient;
    final charPath = _notifyCharPath;
    final subscription = _notifySubscription;

    _notifyClient = null;
    _notifyCharPath = null;
    _notifySubscription = null;
    _notifyCompleter = null;

    try {
      await subscription?.cancel();
    } catch (e) {
      debugPrint('[BLE][NOTIFY][CANCEL][ERROR] $e');
    }

    if (client != null && charPath != null) {
      try {
        final charObject = DBusRemoteObject(
          client,
          name: 'org.bluez',
          path: DBusObjectPath(charPath),
        );

        await charObject.callMethod(
          'org.bluez.GattCharacteristic1',
          'StopNotify',
          [],
        );
      } catch (e) {
        debugPrint('[BLE][NOTIFY][STOP][ERROR] $e');
      }
    }

    try {
      await client?.close();
    } catch (e) {
      debugPrint('[BLE][DBUS][CLOSE][ERROR] $e');
    }
  }

  /// Читає відповідь із FF02 через GATT ReadValue.
  Future<Uint8List> _readBleCharacteristic() async {
    final deviceMac = mac;
    if (deviceMac == null || deviceMac.isEmpty) {
      throw StateError('BLE MAC-адреса не задана.');
    }

    final devicePath =
        '/org/bluez/hci0/dev_${deviceMac.replaceAll(':', '_').toUpperCase()}';

    final client = DBusClient.system();

    try {
      final characteristicPath = await _findCharacteristicPath(
        client,
        devicePath,
        forWrite: false,
      );

      if (characteristicPath == null) {
        throw StateError(
          'BLE characteristic ${BleHelperBl602.BASE_UUID_HOST_READ} не знайдена.',
        );
      }

      final object = DBusRemoteObject(
        client,
        name: 'org.bluez',
        path: DBusObjectPath(characteristicPath),
      );

      final result = await object.callMethod(
        'org.bluez.GattCharacteristic1',
        'ReadValue',
        [DBusDict.stringVariant({})],
      );

      if (result.returnValues.isEmpty ||
          result.returnValues.first is! DBusArray) {
        return Uint8List(0);
      }

      final array = result.returnValues.first as DBusArray;
      final bytes = <int>[];

      for (final item in array.children) {
        if (item is DBusByte) {
          bytes.add(item.value);
        }
      }

      return Uint8List.fromList(bytes);
    } finally {
      await client.close();
    }
  }

  void _resetNotifyCompleter() {
    _notifyCompleter = Completer<Uint8List>();
  }

  Future<bool> connectWifiViaBle({
    required String ssid,
    required String password,
  }) async {
    final command = 'wifi_sta_connect $ssid $password\r\n';
    final bytes = Uint8List.fromList(command.codeUnits);

    debugPrint('[BLE][WIFI_CONNECT][TX] $command');

    final result = await _writeToBleCharacteristic(bytes);

    debugPrint('[BLE][WIFI_CONNECT][RESULT] success=$result');

    return result;
  }

  /// Очікує підключення BL602 до Wi-Fi (стан state = 4 / wifiConnected_IPOK)
  Future<bool> _waitForWifiConnected({int timeoutSeconds = 15}) async {
    final stateCommand = BleHelperBl602.buildWifiStateGetCommand();

    for (var attempt = 1; attempt <= timeoutSeconds; attempt++) {
      await Future.delayed(const Duration(seconds: 1));

      _resetNotifyCompleter();

      final reqSent = await _writeToBleCharacteristic(stateCommand);
      if (!reqSent) continue;

      final response = await _readFromBleCharacteristic();
      if (response.isEmpty) continue;

      final info = BleHelperBl602.parseWifiDataResponse(response);
      final state = info?['state'] ?? -1;

      debugPrint('[BLE][WIFI_STATE] Спроба $attempt/$timeoutSeconds, state=$state');

      if (state == 4) {
        return true;
      }
    }

    return false;
  }
}