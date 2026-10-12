import '../config/ble_uuid_config.dart';
import '../models_tmp/esp_device.dart';

/// Сервіс для пошуку ESP/BL602 шлюзів у BLE-ефірі
abstract class BleScanner {
  /// Потік відсканованих пристроїв
  Stream<List<EspDevice>> get scanResults;

  /// Запуск сканування за конфігурацією UUID
  Future<void> startScan(BleUuidConfig config);

  /// Зупинка сканування
  Future<void> stopScan();
}