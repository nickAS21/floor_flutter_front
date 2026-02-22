import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../usr_client.dart';
import '../usr_client_helper.dart';

class UsrS100HttpClient implements UsrClient {
  static const String _baseUrl = UsrClientHelper.baseUrlHttpS100;



  @override
  Future<String?> getMacAddress() async {
    final http.Client client = http.Client();
    try {
    //   final response = await client.post(
    //     Uri.parse('$_baseUrl/api/nv/get'),
    //     headers: {
    //       'Content-Type': 'application/json', // Спробуй змінити на json
    //       'Accept': '*/*',
    //       'Connection': 'close',
    //     },
    //     body: jsonEncode({"sys.base_mac": ""}), // Спробуй формат JSON у body
    //   ).timeout(const Duration(seconds: 3));

      final response = await client.post(
        Uri.parse('$_baseUrl/api/nv/get'),
        headers: {
          'Content-Type': 'text/plain',
          'Connection': 'close', // ПРИМУСОВЕ ЗАКРИТТЯ: щоб сокет не висів
        },
        body: 'sys.base_mac',
      ).timeout(const Duration(seconds: 3)); // 2с мало для ESP32, ставимо 3с

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sys.base_mac']?.toString().toUpperCase();
      }
    } catch (e) {
      debugPrint("S100 Timeout or Error: $e");
      return null;
    } finally {
      client.close(); // ЗАКРИВАЄМО КЛІЄНТ: звільняємо порт для наступного запиту
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getScanResults() async {
    final http.Client httpClient = http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse('$_baseUrl/api/system/do_func'),
        body: 'do_get_wifi_ap_tablelist()',
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String htmlTable = data['result'] ?? "";
        List<Map<String, dynamic>> networks = [];

        final rows = htmlTable.split("<tr>");
        for (var row in rows) {
          if (!row.contains("selectedSSIDChange")) continue;

          final ssidMatch = RegExp(r"selectedSSIDChange\('(.+?)',").firstMatch(row);
          final ssid = ssidMatch?.group(1) ?? "";

          final rssiMatch = RegExp(r'<td class="tab_r tab_b">(-?\d+)</td>').firstMatch(row);
          final int rssi = int.tryParse(rssiMatch?.group(1) ?? "0") ?? 0;

          if (ssid.isNotEmpty) {
            int quality = 2 * (rssi + 100);
            networks.add({
              'ssid': ssid,
              'level': quality.clamp(0, 100),
            });
          }
        }
        networks.sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));
        return networks;
      }
    } catch (e) {
      debugPrint("S100 Scan Error: $e");
    }
    return [];
  }

  @override
  Future<void> onSaveUpdate({
    required String targetSsid,
    required String targetPass,
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
  }) async {
    final http.Client httpClient = http.Client();
    final payload = [
      'wifi.mode=3',
      'wifi.sta_ssid=$targetSsid',
      'wifi.sta_psw=$targetPass',
      'wifi.sta_wan=DHCP',
      'wifi.ap_ssid=$moduleSsid',
      'uart0.baud_rate=$bitrate',
      'uart0.socka_mode=2',
      'uart0.socka_raddr=$ipA',
      'uart0.socka_rport=$portA',
      'uart0.sockb_mode=2',
      'uart0.sockb_raddr=$ipB',
      'uart0.sockb_rport=$portB',
    ].join(',');

    final response = await httpClient.post(
      Uri.parse('$_baseUrl/api/nv/set'),
      body: payload,
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['result'] == 'ok') {
        await postRestart();
      } else {
        throw Exception("S100 Save Failed: ${response.body}");
      }
    } else {
      throw Exception("S100 HTTP Error: ${response.statusCode}");
    }
  }

  @override
  Future<String> postRestart() async {
    final http.Client httpClient = http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse('$_baseUrl/api/system/do_func'),
        body: 'do_esp_restart()',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? "error";
      }
    } catch (e) {
      return "Restart Error: $e";
    }
    return "error";
  }

  @override
  String? mac;

  @override
  String? ssidName;
}