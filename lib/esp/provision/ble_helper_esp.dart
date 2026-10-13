import 'dart:typed_data';

class BleHelperEsp {
  static Uint8List buildWifiScanCommand() {
    return Uint8List.fromList([0x01]);
  }

  static Uint8List buildWifiCredentialsPayload(String ssid, String pass) {
    return Uint8List.fromList([]);
  }

  static Uint8List buildSettingsPayload({
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
  }) {
    return Uint8List.fromList([]);
  }

  static Uint8List buildRebootCommand() {
    return Uint8List.fromList([0xFF]);
  }
}