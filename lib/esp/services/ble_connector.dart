import '../models_tmp/esp_device.dart';
import '../models_tmp/esp_status.dart';

/// Сервіс підключення та обміну даними з ESP/BL602 по BLE
abstract class BleConnector {
  /// Потік поточного стану з'єднання з пристроєм
  Stream<EspState> get connectionState;

  /// Підключення до пристрою
  Future<void> connect(EspDevice device);

  /// Відключення від пристрою
  Future<void> disconnect();

  /// Відправка сирих байтів у характеристику
  Future<void> writeCharacteristic(String charUuid, List<int> bytes);

  /// Читання сирих байтів з характеристики
  Future<List<int>> readCharacteristic(String charUuid);

  /// Підписка на сповіщення (Notifications/Indication) з характеристики
  Stream<List<int>> subscribeCharacteristic(String charUuid);
}