import 'ble_helper_bl602.dart';

/// Модель даних мережі / стану Wi-Fi для BL602
class Bl602WifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi;
  final int channel;
  final int auth;
  final Bl602BleWifiState state;
  final String ip;
  final String gw;
  final String mask;

  const Bl602WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.channel,
    required this.auth,
    required this.state,
    this.ip = '',
    this.gw = '',
    this.mask = '',
  });

  int get level => rssi;

  factory Bl602WifiNetwork.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'] as int? ?? 0;

    return Bl602WifiNetwork(
      ssid: json['ssid'] as String? ?? '',
      bssid: json['bssid'] as String? ?? '',
      rssi: json['rssi'] as int? ?? -100,
      // Підтримуємо і 'chan' з сканування, і 'channel' якщо десь зміниться
      channel: (json['chan'] ?? json['channel']) as int? ?? 0,
      auth: json['auth'] as int? ?? 255,
      state: Bl602BleWifiState.fromRaw(rawState),
      // Додаткові поля, які повертає CMD_WIFI_STATE_GET
      ip: json['ip'] as String? ?? '',
      gw: json['gw'] as String? ?? '',
      mask: json['mask'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ssid': ssid,
    'bssid': bssid,
    'rssi': rssi,
    'level': level,
    'channel': channel,
    'auth': auth,
    'state': state.rawValue,
    if (ip.isNotEmpty) 'ip': ip,
    if (gw.isNotEmpty) 'gw': gw,
    if (mask.isNotEmpty) 'mask': mask,
  };
}