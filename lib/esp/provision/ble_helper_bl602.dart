import 'dart:convert';
import 'dart:typed_data';

class BleHelperBl602 {
  /// Формування пакета запиту сканування Wi-Fi мереж для BL602
  static Uint8List buildWifiScanCommand() {
    // Приклад бінарного/текстового пакета для BL602 GATT
    return Uint8List.fromList([0x01, 0x00]);
  }

  /// Парсинг відповіді сканування Wi-Fi
  static List<Map<String, dynamic>> parseWifiScanResults(Uint8List data) {
    // Тут буде розпаршування байтів/JSON від BL602
    List<Map<String, dynamic>> networks = [];
    try {
      final str = utf8.decode(data);
      final json = jsonDecode(str);
      if (json is List) {
        for (var item in json) {
          networks.add({
            'ssid': item['ssid'] ?? '',
            'level': item['rssi'] ?? 0,
          });
        }
      }
    } catch (_) {}
    return networks;
  }

  /// Упаковка SSID та Password для BL602
  static Uint8List buildWifiCredentialsPayload(String ssid, String pass) {
    final payload = jsonEncode({'ssid': ssid, 'pass': pass});
    return Uint8List.fromList(utf8.encode(payload));
  }

  /// Упаковка налаштувань (Settings) для BL602
  static Uint8List buildSettingsPayload({
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
  }) {
    final payload = jsonEncode({
      'name': moduleSsid,
      'ip_a': ipA,
      'port_a': portA,
      'ip_b': ipB,
      'port_b': portB,
      'bitrate': bitrate,
    });
    return Uint8List.fromList(utf8.encode(payload));
  }

  /// Команда перезавантаження BL602
  static Uint8List buildRebootCommand() {
    return Uint8List.fromList(utf8.encode('REBOOT'));
  }
}