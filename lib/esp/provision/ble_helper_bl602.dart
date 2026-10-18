import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class BleHelperBl602 {
  // === CLI КОМАНДИ BL602 ===
  static const String cmdWifiScan = "wifi_scan\r\n";
  static const String cmdReboot = "reboot\r\n";
  static const String cmdReset = "reset\r\n";
  static const String cmdStaInfo = "wifi_sta_info\r\n";
  static const String cmdStaState = "wifi_sta_get_state\r\n";
  static const int CMD_WIFI_SCAN = 9;
  static const int CMD_WIFI_DATA_GET = 11;

  /// 1. Виправлено: додано пробіл між ssid і pass
  static String cmdWifiConnect(String ssid, String pass) =>
      "wifi_sta_connect $ssid $pass\r\n";

  static String cmdSetDeviceName(String name) =>
      "ble_set_device_name ${name.length}$name\r\n";

  static Uint8List buildWifiCredentialsPayload(String ssid, String pass) {
    return Uint8List.fromList(utf8.encode(cmdWifiConnect(ssid, pass)));
  }

  /// 2. Виправлено: формуємо рядки з чистими \r\n без дублювання через writeln
  static Uint8List buildSettingsPayload({
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
  }) {
    final buffer = StringBuffer()
      ..write(cmdSetDeviceName(moduleSsid))
      ..write("wifi_sta_ip_set $ipA 255.255.255.0 192.168.1.1 8.8.8.8 8.8.4.4\r\n")
      ..write("set_bitrate $bitrate\r\n");
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static Uint8List buildRebootCommand() {
    return Uint8List.fromList(utf8.encode(cmdReboot));
  }

  /// Формує команду протоколу blsync_ble.
  ///
  /// Пакет CMD:
  /// - заголовок протоколу: 7 байтів;
  /// - заголовок encrypt layer: 9 байтів;
  /// - ID команди + 4 байти даних.
  static Uint8List buildCommandPacket(int commandId) {
    final packet = Uint8List(21);

    // General header: CMD, seq=0.
    packet[0] = 0x00;
    packet[1] = 0x00;

    // Fragment control = 0.
    packet[2] = 0x00;
    packet[3] = 0x00;

    // Довжина декодованих даних CMD — 4 байти.
    packet[4] = 0x04;
    packet[5] = 0x00;

    // Encrypt header + payload: 9 + 5 байтів.
    packet[6] = 0x0E;

    // Encrypt control, counter і MAC залишаються нульовими.
    // ID команди.
    packet[16] = commandId & 0xFF;

    // Чотири байти даних команди вже нульові.
    return packet;
  }

  static Uint8List buildWifiScanCommand() {
    return buildCommandPacket (CMD_WIFI_SCAN);
  }

  static Uint8List buildWifiDataGetCommand() {
    return buildCommandPacket(CMD_WIFI_DATA_GET);
  }

  /// Декодує одну відповідь blsync_ble.
  ///
  /// Для DATA-відповіді JSON починається з байта 18.
  static Map<String, dynamic>? parseWifiDataResponse(
      Uint8List data,
      ) {
    if (data.length < 18) {
      return null;
    }

    final payloadLength = data[4] | (data[5] << 8);

    // Порожня відповідь означає, що запису немає.
    if (payloadLength == 0) {
      return null;
    }

    if (data.length < 18 + payloadLength) {
      debugPrint(
        '[BL602][WIFI_SCAN][PARSE] '
            'Неповний пакет: packet=${data.length}, '
            'payload=$payloadLength',
      );
      return null;
    }

    try {
      final jsonText = utf8.decode(
        data.sublist(18, 18 + payloadLength),
      );

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return {
        'ssid': decoded['ssid'] ?? '',
        'bssid': decoded['bssid'] ?? '',
        'level': decoded['rssi'] ?? -100,
        'rssi': decoded['rssi'] ?? -100,
        'channel': decoded['chan'] ?? 0,
        'auth': decoded['auth'] ?? 255,
      };
    } catch (e) {
      debugPrint('[BL602][WIFI_SCAN][PARSE][ERROR] $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> parseWifiScanResults(
      Uint8List data,
      ) {
    final item = parseWifiDataResponse(data);
    return item == null ? [] : [item];
  }
}