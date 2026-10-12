enum BmsConnectionState {
  disconnected,
  connecting,
  connected,
  standby, // Тимчасова затримка/втрата даних, очікуємо оновлення
  failed,
}

/// Модель BMS-пристрою, знайденого шлюзом
class BmsDevice {
  final String macAddress;
  final String name;
  final int rssi;
  final BmsConnectionState state;

  const BmsDevice({
    required this.macAddress,
    required this.name,
    required this.rssi,
    this.state = BmsConnectionState.disconnected,
  });
}