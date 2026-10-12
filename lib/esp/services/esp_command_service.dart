import '../config/ble_uuid_config.dart';
import '../config/esp_ble_commands.dart';
import '../models/bms_device.dart';
import '../models/wifi_config.dart';
import 'ble_connector.dart';

/// Високорівневий сервіс для виконання бізнес-команд на ESP/BL602
class EspCommandService {
  final BleConnector connector;
  final BleUuidConfig uuidConfig;
  final EspBleCommands commands;

  EspCommandService({
    required this.connector,
    required this.uuidConfig,
    required this.commands,
  });

  /// Запит до шлюзу на сканування доступних Wi-Fi мереж
  Future<List<WifiAccessPoint>> scanWifiNetworks() async {
    return [];
  }

  /// Відправка конфігурації Wi-Fi (SSID + Pass) на шлюз
  Future<bool> sendWifiConfig(WifiConfig config) async {
    return false;
  }

  /// Запит до шлюзу на сканування всіх BLE-пристроїв у його радіусі
  Future<List<BmsDevice>> scanBleBmsDevices() async {
    return [];
  }

  /// Запит на підключення шлюзу до списку BLE BMS-пристроїв (одним пакетом)
  Future<bool> connectToBmsList(List<String> macAddresses) async {
    return false;
  }

  /// Зручна обгортка для підключення до однієї BLE BMS
  Future<bool> connectToBms(String macAddress) async {
    return connectToBmsList([macAddress]);
  }
}