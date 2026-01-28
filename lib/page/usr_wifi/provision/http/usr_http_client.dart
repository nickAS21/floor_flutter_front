import 'dart:convert';
import 'package:floor_front/page/usr_wifi/provision/http/usr_http_client_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UsrHttpClient {
  static const String _baseUrl = "http://${UsrHttpClientHelper.baseIpAtHttp}/EN/${UsrHttpClientHelper.htmlDoCmd}";

  final Map<String, String> _headers = {
    'Authorization': UsrHttpClientHelper.authBasicHeader,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Future<String?> getMacAddress() async {
    if (kIsWeb) return null; // У браузері навіть не намагаємось

    try {
      final response = await http.get(
        Uri.parse(UsrHttpClientHelper.baseUrlHttpFast),
        headers: {'Authorization': UsrHttpClientHelper.authBasicHeader},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final bodyText = String.fromCharCodes(response.bodyBytes);
        final regExp = RegExp(r'BSSID<\/td>\s*<td>([0-9A-Fa-f:]{17})<\/td>', caseSensitive: false);
        final match = regExp.firstMatch(bodyText);
        if (match != null) return match.group(1);
      }
    } catch (e) {
      debugPrint("MAC Error: $e");
    }
    return null;
  }

// Додайте цей метод сюди
  bool isOk(String response) {
    // Тут логіка, яку ви використовували раніше.
    // Можна розширити її, якщо пристрій повертає "FAIL" або інші тексти помилок.
    return !response.contains("ERROR_HTTP") && !response.toLowerCase().contains("fail");
  }

  Future<String> _sendRequest(Map<String, String> body) async {
    try {
      final response = await http.post(
          Uri.parse(_baseUrl),
          headers: _headers,
          body: body,
          encoding: latin1
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);

        // Тепер 'isOk' буде доступний, бо ми його визначили вище
        if (!isOk(decodedBody)) {
          throw Exception("Пристрій повернув помилку: $decodedBody");
        }

        return decodedBody;
      } else {
        throw Exception("HTTP помилка: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> postApStaMode() async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdWirelessBasic,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlOpmode,
      // STA mode = 1 AP mode = 0
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApCliEnable}=1',
      // "", STA, AP => STA
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldWifiMode}=${UsrHttpClientHelper.valuesSta}',
      // STA mode = 2 AP mode = 1 => STA
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSysOpmode}=2',
      // Transparent mode = 0; Serial Comand Mode = 1; GPIO Mode = 3; HTTP Mode = 4; Modbus TCP<=>Modbus RTU = 5;
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldDataTransformMode}=0',
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldCountryCode}=5',
    });
  }

  Future<String> postApStaOn() async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // AP + STA - on
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApStaEnable}=${UsrHttpClientHelper.valuesOn}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldWlanClinum}=100',
    });
  }
  Future<String> postApStaOnWithUpdateSsidPwd(String ssid, String pwd) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // AP + STA - on
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApStaEnable}=${UsrHttpClientHelper.valuesOn}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldSsidName}=$ssid',
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSEnTyPassP}=$pwd',
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldSsidName3}=$ssid',
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldSEnTyPassP3}=$pwd',
    });
  }

  /// 3. Setting ServeA + ServerB
  Future<String> postAppSetting({
    required String serverIpA,
    required int serverPortA,
    required String serverIpB,
    required int serverPortB,
    required int deviceId
  }) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdApplication,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlAppConfig,
      // 'client'/'server' -> 'client'
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldNetMode}=${UsrHttpClientHelper.valuesClient}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldNetPort}=$serverPortA',
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldNetIp}=$serverIpA',
      // Socket B Setting off = 0; on = 1
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldNetbMode}=1',
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldNetbPort}=$serverPortB',
      UsrHttpClientHelper.set5: '${UsrHttpClientHelper.fieldNetbIp}=$serverIpB',
    });
  }

  Future<String> postApLan(String fullSsidName) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlAp,
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldNkSsidName}=$fullSsidName',
    });
  }

  Future<String> postRestart()  async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdASysConf,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlManagement,
      UsrHttpClientHelper.mainCCMD: '${UsrHttpClientHelper.values0}',
    });
  }
}