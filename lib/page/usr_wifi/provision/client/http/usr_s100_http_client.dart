import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../usr_client.dart';
import 'usr_s100_http_client_helper.dart';

class UsrS100HttpClient implements UsrClient {
  static const String _baseUrl = UsrS100HttpClientHelper.baseUrlHttpS100;

  /// 1. Discovery: Отримання MAC-адреси
  @override
  Future<String?> getMacAddress() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/nv/get'),
        body: 'sys.base_mac',
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mac = data['sys.base_mac']; // Формат "D4AD20E7CE50"
        return mac?.toString().toUpperCase();
      }
    } catch (e) {
      debugPrint("S100 MAC Error: $e");
    }
    return null;
  }

  /// 2. Scan: Отримання списку мереж
  @override
  Future<List<Map<String, dynamic>>> getScanResults() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/system/do_func'),
        body: 'do_get_wifi_ap_tablelist()', // Payload з логів
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String htmlTable = data['result'] ?? "";
        List<Map<String, dynamic>> networks = [];

        // Парсимо HTML рядки <tr>
        final rows = htmlTable.split("<tr>");
        for (var row in rows) {
          if (!row.contains("selectedSSIDChange")) continue;

          // SSID знаходиться в selectedSSIDChange('SSID_NAME', ...)
          final ssidMatch = RegExp(r"selectedSSIDChange\('(.+?)',").firstMatch(row);
          final ssid = ssidMatch?.group(1) ?? "";

          // RSSI знаходиться в комірці <td class="tab_r tab_b">-53</td>
          final rssiMatch = RegExp(r'<td class="tab_r tab_b">(-?\d+)</td>').firstMatch(row);
          final int rssi = int.tryParse(rssiMatch?.group(1) ?? "0") ?? 0;

          if (ssid.isNotEmpty) {
            // Конвертуємо RSSI в якість 0-100%
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

  /// 3. Save: Запис налаштувань (WiFi + Сервери + Бітрейт)
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
    // Формуємо комбінований Payload згідно з вашими логами
    final payload = [
      'wifi.mode=3',
      'wifi.sta_ssid=$targetSsid',
      'wifi.sta_psw=$targetPass',
      'wifi.sta_wan=DHCP',
      'wifi.ap_ssid=$moduleSsid',
      'uart0.baud_rate=$bitrate',
      'uart0.socka_mode=2', // TCP Client
      'uart0.socka_raddr=$ipA',
      'uart0.socka_rport=$portA',
      'uart0.sockb_mode=2', // TCP Client
      'uart0.sockb_raddr=$ipB',
      'uart0.sockb_rport=$portB',
    ].join(',');

    // 1. Відправляємо налаштування
    final response = await http.post(
      Uri.parse('$_baseUrl/api/nv/set'),
      body: payload,
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['result'] == 'ok') {
        // 2. Якщо успішно — робимо рестарт
        await postRestart();
      } else {
        throw Exception("S100 Save Failed: ${response.body}");
      }
    } else {
      throw Exception("S100 HTTP Error: ${response.statusCode}");
    }
  }

  /// 4. Restart: Перезавантаження модуля
  @override
  Future<String> postRestart() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/system/do_func'),
        body: 'do_esp_restart()', // Payload з логів
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
}