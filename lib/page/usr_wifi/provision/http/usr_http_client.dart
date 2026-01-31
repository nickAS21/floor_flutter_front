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

  Future<List<Map<String, dynamic>>> getScanResults() async {
    if (kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse(UsrHttpClientHelper.baseUrlHttpSiteSurvey),
        headers: {'Authorization': UsrHttpClientHelper.authBasicHeader},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final bodyText = String.fromCharCodes(response.bodyBytes);
        debugPrint("bodyText: [$bodyText]");
        List<Map<String, dynamic>> networks = [];

        // Регулярний вираз для пошуку рядків таблиці сканування:
        // Шукаємо SSID, Channel та RSSI (Signal Level)
        // Примітка: Структура залежить від прошивки, зазвичай це <tr>...<td>SSID</td><td>RSSI</td>...</tr>
        final regExp = RegExp(
          r'<tr>.*?<td>\d+<\/td>.*?<td>(.*?)<\/td>.*?<td>(\d+)<\/td>.*?<td>(\d+)%<\/td>',
          caseSensitive: false,
          multiLine: true,
          dotAll: true,
        );

        final matches = regExp.allMatches(bodyText);
        for (final m in matches) {
          final ssid = m.group(1)?.trim() ?? "";
          final level = int.tryParse(m.group(3) ?? "0") ?? 0;

          if (ssid.isNotEmpty && !ssid.toLowerCase().contains("empty")) {
            networks.add({
              'ssid': ssid,
              'level': level,
            });
          }
        }

        // Сортуємо за рівнем сигналу як у CMD 01
        networks.sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));
        return networks;
      }
    } catch (e) {
      debugPrint("HTTP Scan Error: $e");
    }
    return [];
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

  /**
   * Default factory
   * Request URL http://10.10.100.254/EN/do_cmd_fast.html
   *  CMD WIRELESS_BASIC
      GO fast.html
      SET0 77267456=1     ?? addCfg('AP_EnTyWEP',0x049b0200,'1');
      SET1 81134080=OPEN  ?? addCfg('S_SecurityMode',0x04d60200,'OPEN');
      SET2 81199616=NONE  ?? addCfg('S_EncryptionType',0x04d70200,'NONE');
      SET3 81264896=1     ?? addCfg('S_EnTyWEP',0x04d80100,'1');
      SET4 303694336=OPEN ?? addCfg('S_SecurityMode3',0x121a0200,'OPEN');
      SET5 303759872=NONE ?? addCfg('S_EncryptionType3',0x121b0200,'NONE');
      SET6 303825408=1    ?? addCfg('S_EnTyWEP3',0x121c0200,'1');
      SET7 304284160=2    ?? addCfg('f_ver',0x12230200,'3');
   */

  // After Default factory
  /**
   * 1) MODE SELECTION: STA mode + Transporent Mode
   *  CMD WIRELESS_BASIC
      GO opmode.html
      SET0 81002752=1
      SET1 288162304=STA
      SET2 18088192=2
      SET3 285278720=0
      SET4 75038976=5
    */
  Future<String> postApStaMode() async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdWirelessBasic,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlOpmode,
      // STA mode = 1 AP mode = 0
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApCliEnable}=${UsrHttpClientHelper.values1}',
      // "", STA, AP => STA
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldWifiMode}=${UsrHttpClientHelper.valuesSta}',
      // STA mode = 2 AP mode = 1 => STA
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSysOpmode}=${UsrHttpClientHelper.values2}',
      // Transparent mode = 0; Serial Comand Mode = 1; GPIO Mode = 3; HTTP Mode = 4; Modbus TCP<=>Modbus RTU = 5;
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldDataTransformMode}=${UsrHttpClientHelper.values0}',
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldCountryCode}=${UsrHttpClientHelper.values5}',
    });
  }

  /**
   *    *
   * 2) AP Interface
   *  CMD WIRELESS_BASIC
      GO ap.html
      SET0 71041536=USR-WIFI232-A2_5DF8
      SET1 70713600=1
   */


  Future<String> postApLan(String fullSsidName) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdWirelessBasic,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlAp,
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldNkSsidName}=$fullSsidName',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldFrequencyAuto}=${UsrHttpClientHelper.values1}',
    });
  }

  /**
   *    * 3) STA Interface: AP+STA settings => AP+STA = on + Ssid + pwd
   *  CMD LAN
      GO sta_config.html
      SET0 304677376=on
   */
  Future<String> postApStaOn() async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // AP + STA - on
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApStaEnable}=${UsrHttpClientHelper.valuesOn}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldWlanClinum}=${UsrHttpClientHelper.values100}',
    });
  }

  /**
   * DHCP Mode
   * CMD LAN
      GO sta_config.html
      SET0 50397440=2                   // addCfg('WAN_TYPE',0x03010100,'2'); 1- SATTIC(fixed IP) 2 - DCHP (Auto config)
      SET1 17105408=USR-WIFI232-B2_5AE0 // addCfg('HN',0x01050200,'USR-WIFI232-B2_5AE0');
      SET2 235077888=0                  // addCfg('SWANDNSFIX',0x0e030100,'0'); 0- Auto; 1 - Static
   */
  Future<String> postDhcpModeWanAuto(String fullSsidName) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // AP + STA - on
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldWanType}=${UsrHttpClientHelper.values2}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldHNWanName}=$fullSsidName',
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSWanDnsFix}=${UsrHttpClientHelper.values0}',
    });
  }

  /**
   *
      CMD LAN
      GO sta_config.html
      SET0 81723904=lebed
      SET1 81134080=WPA2PSK
      SET2 81199616=AES
      SET3 81658368=lebedhomewifi
      SET4 82706944=OPEN
      SET5 82772480=NONE
      SET6 83231232=OPEN
      SET7 83296768=NONE
      SET8 304087552=lebed
      SET9 303694336=WPA2PSK
      SET10 303759872=AES
      SET11 304022016=lebedhomewifi
      SET12 305136128=0
      SET13 304677376=on

   *
   *  4) Application Settings:
   *  CMD Application
      GO app_config.html
      SET0 285999616=client
      SET1 286064896=18890          // portA
      SET2 286130688=192.168.8.119  // apiA
      SET3 286392576=8890           // portB
      SET4 286458368=40.81.42.93    // apiB
   */
  Future<String> postApStaOnWithUpdateSsidPwd(String ssid, String pwd) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,

      // Профіль 1 (STA)
      // 'SET0': '81723904=$ssid',           // SSID
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldSsidName}=$ssid',
      // 'SET1': '81134080=WPA2PSK',        // Auth Mode
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldSSecurityMode}=${UsrHttpClientHelper.valuesWPA2PSK}',
      // 'SET2': '81199616=AES',            // Encryption
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSEncryptionType}=${UsrHttpClientHelper.valuesAES}',
      // 'SET3': '81264896=1',              // Активація профілю (важливо для nLink)
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldSEnTyWEP}=${UsrHttpClientHelper.values1}',
      // 'SET4': '81658368=$pwd',            // Password [cite: 150]
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldSEnTyPassP}=$pwd',
      // Заглушки (OPEN)
      // 'SET5': '82706944=OPEN',
      UsrHttpClientHelper.set5: '${UsrHttpClientHelper.fieldSSecurityMode1}=${UsrHttpClientHelper.valuesOPEN}',
      // 'SET6': '82772480=NONE',
      UsrHttpClientHelper.set6: '${UsrHttpClientHelper.fieldSEncryptionType1}=${UsrHttpClientHelper.valuesNONE}',
      // 'SET7': '83231232=OPEN',
      UsrHttpClientHelper.set7: '${UsrHttpClientHelper.fieldSSecurityMode2}=${UsrHttpClientHelper.valuesOPEN}',
      // 'SET8': '83296768=NONE',
      UsrHttpClientHelper.set8: '${UsrHttpClientHelper.fieldSEncryptionType2}=${UsrHttpClientHelper.valuesNONE}',
      // Профіль 2 (дублювання для стабільності)
      // 'SET9': '304087552=$ssid',
      UsrHttpClientHelper.set9: '${UsrHttpClientHelper.fieldSsidName3}=$ssid',
      // 'SET10': '303694336=WPA2PSK',
      UsrHttpClientHelper.set10: '${UsrHttpClientHelper.fieldSSecurityMode3}=${UsrHttpClientHelper.valuesWPA2PSK}',
      // 'SET11': '303759872=AES',
      UsrHttpClientHelper.set11: '${UsrHttpClientHelper.fieldSEncryptionType3}=${UsrHttpClientHelper.valuesAES}',
      // 'SET12': '303825408=1',            // Активація профілю 2
      UsrHttpClientHelper.set12: '${UsrHttpClientHelper.fieldSEnTyWEP3}=${UsrHttpClientHelper.values1}',
      // 'SET13': '304022016=$pwd',
      UsrHttpClientHelper.set13: '${UsrHttpClientHelper.fieldSEnTyPassP3}=$pwd',
      // 'SET14': '305136128=0',            // Прапорець захисту
      UsrHttpClientHelper.set14: '${UsrHttpClientHelper.fieldStaProtec}=${UsrHttpClientHelper.values0}',
    });
  }

  Future<String> postApStaOnWithUpdateSsidPwd1(String ssid, String pwd) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // SET0 81723904=lebed
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldSsidName}=$ssid',
      // SET1 81134080=WPA2PSK
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldSSecurityMode}=${UsrHttpClientHelper.valuesWPA2PSK}',
      // SET2 81199616=AES
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSSecurityMode}=${UsrHttpClientHelper.valuesAES}',
      // SET3 81658368=lebedhome???
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldSEnTyPassP}=$pwd',
      });
  }  
    Future<String> postApStaOnWithUpdateSsidPwd2() async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldApStaEnable}=${UsrHttpClientHelper.valuesOn}'
      });
  }

  Future<String> postApStaOnWithUpdateSsidPwd12(String ssid, String pwd) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdLan,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlStaConfig,
      // SET0 81723904=lebed
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldSsidName}=$ssid',
      // SET1 81134080=WPA2PSK
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldSSecurityMode}=${UsrHttpClientHelper.valuesWPA2PSK}',
      // SET2 81199616=AES
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldSSecurityMode}=${UsrHttpClientHelper.valuesAES}',
      // SET3 81658368=lebedhome???
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldSEnTyPassP}=$pwd',
      // SET4 82706944=OPEN
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldSSecurityMode1}=${UsrHttpClientHelper.valuesOPEN}',
      // SET5 82772480=NONE
      UsrHttpClientHelper.set5: '${UsrHttpClientHelper.fieldSEncryptionType1}=${UsrHttpClientHelper.valuesNONE}',
      // SET6 83231232=OPEN
      UsrHttpClientHelper.set6: '${UsrHttpClientHelper.fieldSSecurityMode2}=${UsrHttpClientHelper.valuesOPEN}',
      // SET7 83296768=NONE
      UsrHttpClientHelper.set7: '${UsrHttpClientHelper.fieldSEncryptionType2}=${UsrHttpClientHelper.valuesNONE}',
      // SET8 304087552=lebed
      UsrHttpClientHelper.set8: '${UsrHttpClientHelper.fieldSsidName3}=$ssid',
      // SET9 303694336=WPA2PSK
      UsrHttpClientHelper.set9: '${UsrHttpClientHelper.fieldSSecurityMode3}=${UsrHttpClientHelper.valuesWPA2PSK}',
      // SET10 303759872=AES
      UsrHttpClientHelper.set10: '${UsrHttpClientHelper.fieldSEncryptionType3}=${UsrHttpClientHelper.valuesAES}',
      // SET11 304022016=lebedhome???
      UsrHttpClientHelper.set11: '${UsrHttpClientHelper.fieldSEnTyPassP3}=$pwd',
      // SET12 304677376=on => AP + STA - on
      UsrHttpClientHelper.set12: '${UsrHttpClientHelper.fieldApStaEnable}=${UsrHttpClientHelper.valuesOn}',
      UsrHttpClientHelper.set13: '${UsrHttpClientHelper.fieldWlanClinum}=${UsrHttpClientHelper.values100}',
      //?? SET14 305136128=0 => fieldStaProtec = '305136128'; => addCfg('sta_protect',0x12300200,'off');
    });
  }

  /// 3. Setting ServeA + ServerB
  Future<String> postAppSetting({
    required String serverIpA,
    required int serverPortA,
    required String serverIpB,
    required int serverPortB
  }) async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdApplication,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlAppConfig,
      // 'client'/'server' -> 'client'
      UsrHttpClientHelper.set0: '${UsrHttpClientHelper.fieldNetMode}=${UsrHttpClientHelper.valuesClient}',
      UsrHttpClientHelper.set1: '${UsrHttpClientHelper.fieldNetPort}=$serverPortA',
      UsrHttpClientHelper.set2: '${UsrHttpClientHelper.fieldNetIp}=$serverIpA',
      // Socket B Setting off = 0; on = 1
      UsrHttpClientHelper.set3: '${UsrHttpClientHelper.fieldNetbMode}=${UsrHttpClientHelper.values1}',
      UsrHttpClientHelper.set4: '${UsrHttpClientHelper.fieldNetbPort}=$serverPortB',
      UsrHttpClientHelper.set5: '${UsrHttpClientHelper.fieldNetbIp}=$serverIpB',
    });
  }

  /**
   * CMD SYS_CONF
      GO management.html
      CCMD 0
   */
  Future<String> postRestart()  async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdASysConf,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlManagement,
      UsrHttpClientHelper.mainCCMD: '${UsrHttpClientHelper.values0}',
    });
  }

  /**
   * CMD SYS_CONF
      GO management.html
      CCMD 1
   */
  Future<String> postLoadDefaultWtithRestart()  async {
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: UsrHttpClientHelper.cmdASysConf,
      UsrHttpClientHelper.mainGo: UsrHttpClientHelper.htmlManagement,
      UsrHttpClientHelper.mainCCMD: '${UsrHttpClientHelper.values1}',
    });
  }

  Future<String> postApplyAndRestart() async {
    // Команда AT+Z — це і є "Apply" для цих модулів
    return await _sendRequest({
      UsrHttpClientHelper.mainCmd: 'Z', // Команда перезавантаження
      // Якщо ваш CGI вимагає інший формат, можна спробувати прямий GET: "/at+z"
    });
  }
}