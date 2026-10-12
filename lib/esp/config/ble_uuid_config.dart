/// Контракт для UUIDs конкретної прошивки
abstract class BleUuidConfig {
  String get mainServiceUuid;
}

/// Конфігурація для BL602 (UUIDs передаються при ініціалізації)
class Bl602UuidConfig implements BleUuidConfig {
  @override
  final String mainServiceUuid;

  const Bl602UuidConfig({
    required this.mainServiceUuid,
  });
}