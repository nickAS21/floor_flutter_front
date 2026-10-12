/// Модель Wi-Fi мережі, знайденої шлюзом під час сканування
class WifiAccessPoint {
  final String ssid;
  final int rssi;
  final String? bssid;

  const WifiAccessPoint({
    required this.ssid,
    required this.rssi,
    this.bssid,
  });
}

/// Конфігурація Wi-Fi, яку користувач відправляє на шлюз
class WifiConfig {
  final String ssid;
  final String password;

  const WifiConfig({
    required this.ssid,
    required this.password,
  });
}