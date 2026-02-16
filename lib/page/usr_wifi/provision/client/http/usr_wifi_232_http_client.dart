import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../usr_client.dart';
import '../../usr_wifi_232_provision_udp.dart';
import 'usr_wifi_232_http_client_helper.dart';

class UsrWiFi232HttpClient implements UsrClient {
  static const String _baseUrl = "http://${UsrWiFi232HttpClientHelper.baseIpAtHttpWiFi232}/EN/${UsrWiFi232HttpClientHelper.htmlDoCmd}";

  final _udpProvider = UsrWiFi232ProvisionUdp();

  final Map<String, String> _headers = {
    'Authorization': UsrWiFi232HttpClientHelper.authBasicHeader,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  @override
  Future<String?> getMacAddress() async {
    if (kIsWeb) return null;
    try {
      final response = await http.get(
        Uri.parse(UsrWiFi232HttpClientHelper.baseUrlHttpFast),
        headers: {'Authorization': UsrWiFi232HttpClientHelper.authBasicHeader},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final bodyText = String.fromCharCodes(response.bodyBytes);
        final regExp = RegExp(r'BSSID<\/td>\s*<td>([0-9A-Fa-f:]{17})<\/td>', caseSensitive: false);
        final match = regExp.firstMatch(bodyText);

        final mac = match?.group(1);
        return mac?.toUpperCase();
      }
    } catch (e) {
      debugPrint("MAC Discovery Error: $e");
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getScanResults() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Виклик твого методу з передачею null (як у твоїй редакції)
      return await _udpProvider.scanNetworks(null);
    }

    try {
      final response = await http.get(
        Uri.parse(UsrWiFi232HttpClientHelper.baseUrlHttpSiteSurvey),
        headers: {'Authorization': UsrWiFi232HttpClientHelper.authBasicHeader},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final bodyText = String.fromCharCodes(response.bodyBytes);
        List<Map<String, dynamic>> networks = [];
        final regExp = RegExp(
          r'<tr>.*?<td>\d+<\/td>.*?<td>(.*?)<\/td>.*?<td>(\d+)<\/td>.*?<td>(\d+)%<\/td>',
          caseSensitive: false, multiLine: true, dotAll: true,
        );

        final matches = regExp.allMatches(bodyText);
        for (final m in matches) {
          final ssid = m.group(1)?.trim() ?? "";
          final level = int.tryParse(m.group(3) ?? "0") ?? 0;
          if (ssid.isNotEmpty && !ssid.toLowerCase().contains("empty")) {
            networks.add({'ssid': ssid, 'level': level});
          }
        }
        networks.sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));
        return networks;
      }
    } catch (e) {
      debugPrint("HTTP Scan Error: $e");
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
    // Послідовний ланцюжок налаштувань (взято з твого onSaveHttpUpdate)
    await postApStaMode();
    await postApStaOn();
    await postDhcpModeWanAuto(moduleSsid);
    await postApLan(moduleSsid);
    await postAppSetting(
        serverIpA: ipA,
        serverPortA: portA,
        serverIpB: ipB,
        serverPortB: portB
    );

    // Фінальний крок: Android (UDP) або Linux (HTTP)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final res = await _udpProvider.saveAndRestart(targetSsid, targetPass);
      if (res != "ok") throw Exception("UDP Save failed: $res");
    } else {
      await postApStaOnWithUpdateSsidPwd(targetSsid, targetPass);
      await postRestart();
    }
  }

  // --- Реалізація всіх внутрішніх методів ---

  Future<String> _sendRequest(Map<String, String> body) async {
    final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: body,
        encoding: latin1
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
      // Перевірка на успіх: "ok", HTML сторінка або код повернення 0
      bool success = decoded.toLowerCase().contains("ok") ||
          decoded.contains("<html") ||
          decoded.contains("rc=0");
      if (!success) throw Exception("Module Error: $decoded");
      return decoded;
    }
    throw Exception("HTTP Error: ${response.statusCode}");
  }

  Future<String> postApStaMode() async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdWirelessBasic,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlOpmode,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldApCliEnable}=${UsrWiFi232HttpClientHelper.values1}',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldWifiMode}=${UsrWiFi232HttpClientHelper.valuesSta}',
      UsrWiFi232HttpClientHelper.set2: '${UsrWiFi232HttpClientHelper.fieldSysOpmode}=${UsrWiFi232HttpClientHelper.values2}',
      UsrWiFi232HttpClientHelper.set3: '${UsrWiFi232HttpClientHelper.fieldDataTransformMode}=${UsrWiFi232HttpClientHelper.values0}',
      UsrWiFi232HttpClientHelper.set4: '${UsrWiFi232HttpClientHelper.fieldCountryCode}=${UsrWiFi232HttpClientHelper.values5}',
    });
  }

  Future<String> postApLan(String fullSsidName) async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdWirelessBasic,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlAp,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldNkSsidName}=$fullSsidName',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldFrequencyAuto}=${UsrWiFi232HttpClientHelper.values1}',
    });
  }

  Future<String> postApStaOn() async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdLan,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlStaConfig,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldApStaEnable}=${UsrWiFi232HttpClientHelper.valuesOn}',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldWlanClinum}=${UsrWiFi232HttpClientHelper.values100}',
    });
  }

  Future<String> postDhcpModeWanAuto(String fullSsidName) async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdLan,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlStaConfig,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldWanType}=${UsrWiFi232HttpClientHelper.values2}',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldHNWanName}=$fullSsidName',
      UsrWiFi232HttpClientHelper.set2: '${UsrWiFi232HttpClientHelper.fieldSWanDnsFix}=${UsrWiFi232HttpClientHelper.values0}',
    });
  }

  Future<String> postApStaOnWithUpdateSsidPwd(String ssid, String pwd) async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdLan,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlStaConfig,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldSsidName}=$ssid',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldSSecurityMode}=${UsrWiFi232HttpClientHelper.valuesWPA2PSK}',
      UsrWiFi232HttpClientHelper.set2: '${UsrWiFi232HttpClientHelper.fieldSEncryptionType}=${UsrWiFi232HttpClientHelper.valuesAES}',
      UsrWiFi232HttpClientHelper.set3: '${UsrWiFi232HttpClientHelper.fieldSEnTyWEP}=${UsrWiFi232HttpClientHelper.values1}',
      UsrWiFi232HttpClientHelper.set4: '${UsrWiFi232HttpClientHelper.fieldSEnTyPassP}=$pwd',
      UsrWiFi232HttpClientHelper.set12: '${UsrWiFi232HttpClientHelper.fieldApStaEnable}=${UsrWiFi232HttpClientHelper.valuesOn}',
    });
  }

  Future<String> postAppSetting({
    required String serverIpA, required int serverPortA,
    required String serverIpB, required int serverPortB
  }) async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdApplication,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlAppConfig,
      UsrWiFi232HttpClientHelper.set0: '${UsrWiFi232HttpClientHelper.fieldNetMode}=${UsrWiFi232HttpClientHelper.valuesClient}',
      UsrWiFi232HttpClientHelper.set1: '${UsrWiFi232HttpClientHelper.fieldNetPort}=$serverPortA',
      UsrWiFi232HttpClientHelper.set2: '${UsrWiFi232HttpClientHelper.fieldNetIp}=$serverIpA',
      UsrWiFi232HttpClientHelper.set3: '${UsrWiFi232HttpClientHelper.fieldNetbMode}=${UsrWiFi232HttpClientHelper.values1}',
      UsrWiFi232HttpClientHelper.set4: '${UsrWiFi232HttpClientHelper.fieldNetbPort}=$serverPortB',
      UsrWiFi232HttpClientHelper.set5: '${UsrWiFi232HttpClientHelper.fieldNetbIp}=$serverIpB',
    });
  }

  @override
  Future<String> postRestart() async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdASysConf,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlManagement,
      UsrWiFi232HttpClientHelper.mainCCMD: '${UsrWiFi232HttpClientHelper.values0}',
    });
  }

  Future<String> postLoadDefaultWtithRestart() async {
    return await _sendRequest({
      UsrWiFi232HttpClientHelper.mainCmd: UsrWiFi232HttpClientHelper.cmdASysConf,
      UsrWiFi232HttpClientHelper.mainGo: UsrWiFi232HttpClientHelper.htmlManagement,
      UsrWiFi232HttpClientHelper.mainCCMD: '${UsrWiFi232HttpClientHelper.values1}',
    });
  }
}