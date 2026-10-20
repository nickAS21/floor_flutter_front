import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';

/// Повний список типів даних/полів BLE-протоколу BL602 (1:1 з C-enum у прошивці)
enum Bl602BleData {
  DATA_ACK(0x00),
  DATA_STA_WIFI_BSSID(0x01),
  DATA_STA_WIFI_SSID(0x02),
  DATA_STA_WIFI_PASSWORD(0x03),
  DATA_SOFTAP_WIFI_SSID(0x04),
  DATA_SOFTAP_WIFI_PASSWORD(0x05),
  DATA_SOFTAP_MAX_CONNECTION_COUNT(0x06),
  DATA_SOFTAP_AUTH_MODE(0x07),
  DATA_SOFTAP_CHANNEL(0x08),
  DATA_USERNAME(0x09),
  DATA_CA_CERTIFICATION(0x0A),
  DATA_CLIENT_CERTIFICATION(0x0B),
  DATA_SERVER_CERTIFICATION(0x0C),
  DATA_CLIENT_PRIVATE_KEY(0x0D),
  DATA_SERVER_PRIVATE_KEY(0x0E),
  DATA_WIFI_CONNECTION_STATE(0x0F),
  DATA_VERSION(0x10),
  DATA_WIFI_LIST(0x11),
  DATA_ERROR(0x12),
  DATA_CUSTOM_DATA(0x13);

  final int rawValue;
  const Bl602BleData(this.rawValue);
}

/// Команди BLE-протоколу BL602 (1:1 з C-enum у прошивці)
enum Bl602BleCmd {
  CMD_ACK(0),
  CMD_SET_SEC_MODE(1),
  CMD_SET_OP_MODE(2),
  CMD_CONNECT_WIFI(3),
  CMD_DISCONNECT_WIFI(4),
  CMD_GET_WIFI_STATUS(5),
  CMD_DEAUTHENTICATE(6),
  CMD_GET_VERSION(7),
  CMD_CLOSE_CONNECTION(8),
  CMD_WIFI_SCAN(9),
  CMD_DATA_GET_PREPARE(10),
  CMD_WIFI_DATA_GET(11),
  CMD_PROV_STOP(12),
  CMD_WIFI_STATE_GET(13);

  final int rawValue;
  const Bl602BleCmd(this.rawValue);
}

class BleHelperBl602 {
  static const int PROTOCOL_TYPE_CMD = 0x00;
  static const int PROTOCOL_TYPE_DATA = 0x01;
  static const int PRO_CTRL_TYPE_BIT = 4;
  static const int PRO_CTRL_TYPE_MASK = 0x30;
  static const String BASE_UUID_HOST_SERVER = "0000ffff-0000-1000-8000-00805f9b34fb";
  static const String BASE_UUID_HOST_READ = "0000ff02-0000-1000-8000-00805f9b34fb";
  static const String BASE_UUID_HOST_WRITE = "0000ff01-0000-1000-8000-00805f9b34fb";

  // === CLI КОМАНДИ BL602 ===
  static const String cmdWifiScan = "wifi_scan\r\n";
  static const String cmdReboot = "reboot\r\n";
  static const String cmdReset = "reset\r\n";
  static const String cmdStaInfo = "wifi_sta_info\r\n";
  static const String cmdStaState = "wifi_sta_get_state\r\n";

  static int buildProtocolCtrl(int type) =>
      (type << PRO_CTRL_TYPE_BIT) & PRO_CTRL_TYPE_MASK;

  static String cmdWifiConnect(String ssid, String pass) =>
      "wifi_sta_connect $ssid $pass\r\n";

  static String cmdSetDeviceName(String name) =>
      "ble_set_device_name ${name.length}$name\r\n";

  static Uint8List buildWifiCredentialsPayload(String ssid, String pass) {
    return Uint8List.fromList(utf8.encode(cmdWifiConnect(ssid, pass)));
  }

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

  /// Універсальний конструктор DATA-пакетів (PROTOCOL_EVENT_DATA = 0x01)
  static Uint8List buildDataPacket(Bl602BleData dataType, String value) {
    // Додаємо null-terminator (\0) для C-рядка
    final bytes = utf8.encode('$value\x00');

    // Довжина payload: 1 байт (dataType) + байти рядка з \0
    final payloadLen = 1 + bytes.length;
    final packet = Uint8List(18 + bytes.length);

    packet[0] = buildProtocolCtrl(PROTOCOL_TYPE_DATA); // PRO_CTRL_TYPE = PRO_TYPE_DATA
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;

    // Довжина вказується для всього payload (data_type + string)
    packet[4] = bytes.length & 0xFF;
    packet[5] = (bytes.length >> 8) & 0xFF;
    packet[6] = 11 + bytes.length;

    // Байтові заповнення 7..15 залишаються 0x00
    packet[16] = bytes.length;
    packet[17] = dataType.rawValue;
    packet.setRange(18, 18 + bytes.length, bytes);
    debugPrint(
      '[BLE][DATA][TX] type=${dataType.rawValue}, '
          'length=${packet.length}, '
          'hex=${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
    return packet;
  }

  /// Універсальний конструктор CMD-пакетів (PROTOCOL_EVENT_CMD = 0x00)
  static Uint8List buildCommandPacket(int commandId) {
    final packet = Uint8List(21);

    packet[0] = buildProtocolCtrl(PROTOCOL_TYPE_CMD);; // PROTOCOL_EVENT_CMD
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = 0x04;
    packet[5] = 0x00;
    packet[6] = 0x0E;
    packet[16] = commandId & 0xFF;

    return packet;
  }

  // === ХЕЛПЕРИ СТВОРЕННЯ DATA-ПАКЕТІВ ===
  static Uint8List buildWifiSsidPacket(String ssid) =>
      buildDataPacket(Bl602BleData.DATA_STA_WIFI_SSID, ssid);

  static Uint8List buildWifiPasswordPacket(String password) =>
      buildDataPacket(Bl602BleData.DATA_STA_WIFI_PASSWORD, password);

  // === ХЕЛПЕРИ СТВОРЕННЯ CMD-ПАКЕТІВ ===
  static Uint8List buildWifiScanCommand() {
    return buildCommandPacket(Bl602BleCmd.CMD_WIFI_SCAN.rawValue);
  }

  static Uint8List buildWifiDataGetCommand() {
    return buildCommandPacket(Bl602BleCmd.CMD_WIFI_DATA_GET.rawValue);
  }

  static Uint8List buildWifiConnectSetCommand() {
    return buildCommandPacket(Bl602BleCmd.CMD_CONNECT_WIFI.rawValue);
  }

  static Uint8List buildWifiStateGetCommand() {
    return buildCommandPacket(Bl602BleCmd.CMD_WIFI_STATE_GET.rawValue);
  }

  // === ПАРСИНГ ВІДПОВІДЕЙ ===
  // === ПАРСИНГ ВІДПОВІДЕЙ ===
  static Map<String, dynamic>? parseWifiDataResponse(Uint8List data) {
    if (data.length < 18) return null;

    final payloadLength = data[4] | (data[5] << 8);
    if (payloadLength == 0 || data.length < 18 + payloadLength) return null;

    try {
      final jsonText = utf8.decode(data.sublist(18, 18 + payloadLength));
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;

      return {
        'state': decoded['state'] ?? -1, // <--- Додано стан
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

  static List<Map<String, dynamic>> parseWifiScanResults(Uint8List data) {
    final item = parseWifiDataResponse(data);
    return item == null ? [] : [item];
  }

}