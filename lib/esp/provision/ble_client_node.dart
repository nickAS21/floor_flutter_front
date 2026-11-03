import 'dart:async';
import 'dart:typed_data';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../../page/usr_wifi/info/data_usr_wifi_info.dart';
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

      debugPrint('КРОК 5.3: [BLE][CMD_WIFI_SCAN] -> (9) - START');

      if (!await _writeToBleCharacteristic(scanCommand)) {
        throw StateError('Не вдалося надіслати CMD_WIFI_SCAN.');
      }

      // Даємо прошивці час на фізичне сканування ефіру
      await Future.delayed(const Duration(milliseconds: 2500));

      final networks = <Map<String, dynamic>>[];
      final seenBssids = <String>{};

      for (var i = 0; i < BleHelperBl602.WIFI_SCAN_ITEMS_MAX; i++) {
        final command = BleHelperBl602.buildWifiDataGetCommand();

        if (!await _writeToBleCharacteristic(command)) {
          debugPrint('[BLE][WIFI_SCAN][ABORT] Запис не вдався. Зупинка циклу.');
          break; // Зупиняємо цикл одразу
        }

        final response = await _readBleCharacteristic();

        // Парсимо строговою моделлю всередині
        final networkModel = BleHelperBl602.parseWifiDataResponse(response);

        if (networkModel == null || networkModel.ssid.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        final key = networkModel.bssid.isNotEmpty ? networkModel.bssid : networkModel.ssid;

        if (seenBssids.add(key)) {
          // Конвертуємо модель у Map для збереження сумісності з UsrClient та UI
          networks.add(networkModel.toJson());
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }

      debugPrint('КРОК 5.4: [BLE][CMD_WIFI_SCAN] -> (9) - RESULT, networks=${networks.length}');

      return networks;
    } catch (e, stackTrace) {
      debugPrint('[BLE][WIFI_SCAN][ERROR], error=$e');
      debugPrintStack(stackTrace: stackTrace);
      throw StateError('Не вдалося надіслати для Ble Node -> CMD_WIFI_SCAN, error=$e');;
    }
  }

  /// Підключення до BLE Node та пошук GATT-характеристики за UUID
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
        // Якщо об'єкт пристрою зник з D-Bus (наприклад, знеструмлений)
        if (e.toString().contains('UnknownObject')) {
          throw StateError('Пристрій $deviceMac зник з Bluetooth-ефіру (UnknownObject).');
        }
        debugPrint('[BLE][PROPERTY][ERROR] MAC=$deviceMac, property=Connected, error=$e');
      }

      return null;
    }

    // 1. ПЕРЕВІРКА ТА ВСТАНОВЛЕННЯ З'ЄДНАННЯ
    var connected = await getConnected() ?? false;

    if (!connected) {
      debugPrint('КРОК 5.3.1 [BLE][CONNECT] MAC=$deviceMac: підключення...');

      try {
        await deviceObject.callMethod(
          deviceInterface,
          'Connect',
          [],
        );
      } catch (e) {
        final errStr = e.toString();
        debugPrint('[BLE][CONNECT][ERROR] MAC=$deviceMac, result=$errStr');

        // Якщо девайс уже підключається, не перериваємо — даємо цикл очікування
        if (!errStr.contains('InProgress')) {
          // Якщо це фатальна помилка (нет пристрою, disconnect local тощо) — рвемо ланцюжок!
          throw Exception('Не вдалося ініціювати BLE-з`єднання ($deviceMac): $e');
        }
      }
    }

    // Чекаємо фактичного підтвердження прапорця Connected від BlueZ
    final connectDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(connectDeadline)) {
      connected = await getConnected() ?? false;
      if (connected) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // ЯКЩО НЕМАЄ КОННЕКТУ — ЗУПИНЯЄМО ВСЕ І КИДАЄМО EXCEPTION
    if (!connected) {
      debugPrint('[BLE][CONNECT][ERROR] MAC=$deviceMac: тайм-аут підключення.');
      throw TimeoutException('Тайм-аут підключення до BLE Node ($deviceMac). Пристрій вимкнено або поза зоною.');
    }

    // 2. ПОШУК GATT-ХАРАКТЕРИСТИКИ
    final discoveryDeadline = DateTime.now().add(const Duration(seconds: 10));

    while (DateTime.now().isBefore(discoveryDeadline)) {
      connected = await getConnected() ?? false;

      if (!connected) {
        // Якщо зв'язок обірвався прямо під час пошуку
        throw StateError('BLE-з`єднання з $deviceMac раптово втрачено під час пошуку характеристики.');
      }

      try {
        final managedObjects = await objectManager.callMethod(
          'org.freedesktop.DBus.ObjectManager',
          'GetManagedObjects',
          [],
        );

        if (managedObjects.returnValues.isNotEmpty) {
          final objectsMap = managedObjects.returnValues.first as DBusDict;

          for (final entry in objectsMap.children.entries) {
            final objectPath = (entry.key as DBusObjectPath).value;

            if (!objectPath.startsWith('$devicePath/')) {
              continue;
            }

            final interfaces = entry.value as DBusDict;
            final characteristicValue = interfaces.children[const DBusString(characteristicInterface)];

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
        debugPrint('[BLE][GATT][DISCOVERY][ERROR] MAC=$deviceMac, UUID=$targetUuid, error=$e');
        debugPrintStack(stackTrace: stackTrace);
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    throw StateError('Характеристику $targetUuid не знайдено на пристрої $deviceMac.');
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
    required String targetBssid,
    required String targetPass,
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
    bool isRs485Enabled = true,
  }) async {
    // 1. Запуск сповіщень FF02 (строго по mac)
    if (!await _startBleNotifications()) {
      throw Exception('Не вдалося запустити BLE Notifications (FF02).');
    }

    // 2. Передача Target Wi-Fi SSID
    final ssidSent = await _writeToBleCharacteristic(
      deviceType == UsrClientNodeType.esp
          ? BleHelperEsp.buildWifiCredentialsPayload(targetSsid, "")
          : BleHelperBl602.buildWifiSsidPacket(targetSsid),
    );
    if (!ssidSent) throw Exception('Не вдалося передати SSID через BLE.');

    // 3. Передача Target Wi-Fi Password
    final passwordSent = await _writeToBleCharacteristic(
      deviceType == UsrClientNodeType.esp
          ? BleHelperEsp.buildWifiCredentialsPayload("", targetPass)
          : BleHelperBl602.buildWifiPasswordPacket(targetPass),
    );
    if (!passwordSent) throw Exception('Не вдалося передати пароль через BLE.');

    // 4. Формування та відправка JSON-конфігурації ноди (Settings Provisioning)
    final nodeInfo = DataUsrWiFiInfo(
      bssidMac: mac ?? '',
      ssidWifiBms: moduleSsid,
      netIpA: ipA,
      netAPort: portA,
      netIpB: ipB,
      netBPort: portB,
      bitrate: bitrate,
      bmsList: bmsList,
    );

    final jsonPayload = nodeInfo.toNodeConfigJson();
    final settingsPacket = deviceType == UsrClientNodeType.esp
        ? BleHelperEsp.buildSettingsPayload(jsonPayload)
        : BleHelperBl602.buildSettingsPayload(jsonPayload);

    final settingsSent = await _writeToBleCharacteristic(settingsPacket);
    if (!settingsSent) {
      throw Exception('Не вдалося записати налаштування ноди (${deviceType.name}).');
    }
    debugPrint('[BLE][SETTINGS] Конфігурацію успішно передано: $jsonPayload');

    // 5. Запуск підключення до Wi-Fi
    final connectSent = await _writeToBleCharacteristic(
      deviceType == UsrClientNodeType.esp
          ? BleHelperEsp.buildWifiScanCommand() // або відповідна команда ESP
          : BleHelperBl602.buildWifiConnectSetCommand(),
    );
    if (!connectSent) throw Exception('Не вдалося надіслати команду підключення до Wi-Fi.');

    // 6. Очікування статусу підключення
    final connectedSsid = await _waitForWifiConnected(targetSsid, targetPass, targetBssid);
    debugPrint('Підключено до SSID=$connectedSsid');
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
          // TODO Debug
          // debugPrint(
          //   '[BLE][NOTIFY][RX] MAC=$deviceMac, '
          //       'bytes=${bytes.length}, '
          //       'hex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          // );

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
      // TODO Debug
      // debugPrint(
      //   '[BLE][NOTIFY][OK] MAC=$deviceMac, '
      //       'UUID=${BleHelperBl602.BASE_UUID_HOST_READ}, path=$charPath',
      // );

      return true;
    } catch (e, stackTrace) {
      debugPrint('[BLE][NOTIFY][ERROR] MAC=$deviceMac, error=$e');
      debugPrintStack(stackTrace: stackTrace);

      await _stopBleNotifications();
      return false;
    }
  }

  Future<bool> _writeToBleCharacteristic(Uint8List bytes) async {
    if (bytes.isEmpty) return false;

    final deviceMac = mac;
    if (deviceMac == null || deviceMac.isEmpty) {
      throw StateError('BLE MAC-адреса не задана.');
    }

    final devicePath = '/org/bluez/hci0/dev_${deviceMac.replaceAll(':', '_').toUpperCase()}';
    DBusClient? client;

    try {
      client = DBusClient.system();

      // Якщо тут немає коннекту — метод одразу викине exception і не піде далі
      final characteristicPath = await _findCharacteristicPath(
        client,
        devicePath,
        forWrite: true,
      );

      if (characteristicPath == null) return false;

      final object = DBusRemoteObject(
        client,
        name: 'org.bluez',
        path: DBusObjectPath(characteristicPath),
      );

      await object.callMethod(
        'org.bluez.GattCharacteristic1',
        'WriteValue',
        [
          DBusArray.byte(bytes),
          DBusDict.stringVariant({}),
        ],
      );

      return true;
    } catch (e) {
      debugPrint('[BLE][WRITE][ERROR] MAC=$deviceMac, error=$e');
      rethrow; // <-- Обов'язково прокидаємо далі, щоб перервати ретраї на верхньому рівні!
    } finally {
      await client?.close();
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

  Future<String> _waitForWifiConnected(String targetSsid, String targetPass, String targetBssid, {
    Duration timeout = const Duration(seconds: 60),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      // 1. Запит фактичного стану Wi-Fi
      final command = BleHelperBl602.buildWifiStateGetCommand();

      if (!await _writeToBleCharacteristic(command)) {
        throw Exception('Не вдалося надіслати CMD_WIFI_STATE_GET.');
      }

      // 2. Отримати відповідь через FF02
      final response = await _readBleCharacteristic();

      if (response.isNotEmpty) {
        final wifiNetwork = BleHelperBl602.parseWifiStateResponse(response);

        if (wifiNetwork != null) {
          // 3. Перевірки через геттери моделі та enum
          if (wifiNetwork.bssid.toUpperCase() == targetBssid.toUpperCase()) {
            switch (wifiNetwork.state) {
            // 1. Успіх
              case Bl602BleWifiState.WIFI_STATE_CONNECTED_IP_GOT:
              case Bl602BleWifiState.WIFI_STATE_WITH_AP_CONNECTED_IP_GOT:
                return wifiNetwork.ssid;

            // 2. Явна помилка пароля
              case Bl602BleWifiState.WIFI_STATE_PSK_ERROR:
                throw Exception('Невірний пароль Wi-Fi (PSK_ERROR).');

            // 3. Явна відсутність AP
              case Bl602BleWifiState.WIFI_STATE_NO_AP_FOUND:
                throw Exception('Точку доступу не знайдено в ефірі.');

            // 4. Відмова роутера (Deauth by AP -> повернення в IDLE або DISCONNECT)
              case Bl602BleWifiState.WIFI_STATE_IDLE:
              case Bl602BleWifiState.WIFI_STATE_DISCONNECT:
              case Bl602BleWifiState.WIFI_STATE_WITH_AP_DISCONNECT:
                throw Exception('Роутер відхилив підключення \n- !!!Деавтентифікація з боку Мережі: Перевір Назву та Пароль [$targetPass].');

            // 5. Проміжні стани підключення (CONNECTING 0x02, GETTING_IP 0x03)
              default:
              // Чекаємо наступної ітерації циклу
                break;
            }
          }
        }
      }
      await Future.delayed(interval);
    }

    throw TimeoutException(
      'Таймаут [${timeout.inSeconds} сек] очікування підключення до Мережі [$targetSsid].',
    );
  }
}