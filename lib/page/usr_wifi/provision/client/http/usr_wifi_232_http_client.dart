import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../usr_client.dart';
import '../../usr_wifi_232_provision_udp.dart';
import '../usr_client_helper.dart';
import 'usr_wifi_232_http_client_helper.dart';

class UsrWiFi232HttpClient implements UsrClient {
  static const String _baseUrl = "http://${UsrClientHelper.baseIpAtHttpWiFi232}/EN/${UsrWiFi232HttpClientHelper.htmlDoCmd}";

  final _udpProvider = UsrWiFi232ProvisionUdp();

  final Map<String, String> _headers = {
    'Authorization': UsrClientHelper.authBasicHeader,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  @override
  Future<String?> getMacAddress() async {
    if (kIsWeb) return null;
    try {
      final response = await http.get(
        Uri.parse(UsrWiFi232HttpClientHelper.baseUrlHttpFast),
        headers: {'Authorization': UsrClientHelper.authBasicHeader},
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
    final uri = Uri.parse(UsrWiFi232HttpClientHelper.baseUrlHttpSiteSurvey);
    Socket? socket;

    try {
      // 1. Тупо відкриваємо TCP-порт
      socket = await Socket.connect(uri.host, uri.port == 0 ? 80 : uri.port, timeout: const Duration(seconds: 5));

      // 2. Кидаємо запит як у браузері, але кажемо модулю "здихнути" (close) після відповіді
      socket.add(utf8.encode(
          "GET ${uri.path} HTTP/1.1\r\n"
              "Host: ${uri.host}\r\n"
              "Authorization: ${UsrClientHelper.authBasicHeader}\r\n"
              "Connection: close\r\n\r\n"
      ));

      // 3. Згрібаємо ВСІ байти в одну кучу, поки сокет не закриється
      final List<int> bytes = [];
      await for (final chunk in socket) {
        bytes.addAll(chunk);
      }

      // 4. Перетворюємо байти в символи без жодних перевірок на UTF чи іншу фігню
      final rawData = String.fromCharCodes(bytes);

      // Шукаємо де починається HTML
      final htmlStart = rawData.indexOf('<html');
      if (htmlStart == -1) return [];

      // Твій метод очищення (назву не міняю)
      final cleanHtml = _cleanUsrHtml(rawData.substring(htmlStart));
      return _parseNetworks(cleanHtml);

    } catch (e) {
      // Якщо тут помилка — значить вайфаю фізично пизда
      return [];
    } finally {
      socket?.destroy(); // Рубаємо сокет в кінці
    }
  }

  // @override
  // Future<List<Map<String, dynamic>>> getScanResults() async {
  //   try {
  //     // Використовуємо curl з параметром --ignore-content-length та --http0.9
  //     // Це змушує його не закривати сесію, навіть якщо сервер бреше про розмір даних
  //     final result = await Process.run('curl', [
  //       '-u', 'admin:admin', // Або твій хеш через заголовок
  //       '--max-time', '10',
  //       '--ignore-content-length',
  //       '--http1.0', // Старі модулі люблять 1.0 більше ніж 1.1
  //       UsrWiFi232HttpClientHelper.baseUrlHttpSiteSurvey,
  //     ]);
  //
  //     if (result.exitCode == 0) {
  //       final rawData = result.stdout.toString();
  //       final htmlStart = rawData.indexOf('<html');
  //       if (htmlStart == -1) return [];
  //
  //       final cleanHtml = _cleanUsrHtml(rawData.substring(htmlStart));
  //       return _parseNetworks(cleanHtml); // Винеси парсинг в окремий метод
  //     }
  //   } catch (e) {
  //     debugPrint("Curl error: $e");
  //   }
  //   return [];
  // }
  // @override
  // Future<List<Map<String, dynamic>>> getScanResults() async {
  //   final List<int> bytes = [];
  //   Socket? socket;
  //
  //   try {
  //     // 1. Короткий таймаут на коннект
  //     socket = await Socket.connect('10.10.10.254', 80, timeout: const Duration(seconds: 2));
  //
  //     // 2. ВІДПРАВЛЯЄМО ТІЛЬКИ НЕОБХІДНЕ
  //     // Часто ці модулі "вішаються", якщо бачать заголовок Host або Connection у HTTP/1.0
  //     // Спробуй відправити тільки GET та Authorization
  //     socket.write("GET /EN/site_survey.html HTTP/1.0\r\n");
  //     socket.write("Authorization: Basic YWRtaW46YWRtaW4=\r\n");
  //     socket.write("\r\n"); // Порожній рядок - сигнал кінця запиту
  //
  //     await socket.flush();
  //
  //     final completer = Completer<List<int>>();
  //
  //     // 3. Читаємо агресивно
  //     socket.listen(
  //           (data) {
  //         bytes.addAll(data);
  //         // Якщо бачимо кінець HTML - виходимо раніше таймауту
  //         if (String.fromCharCodes(bytes).contains('</html>')) {
  //           completer.complete(bytes);
  //         }
  //       },
  //       onError: (e) => completer.complete(bytes),
  //       onDone: () => completer.complete(bytes),
  //       cancelOnError: false,
  //     );
  //
  //     // Чекаємо, поки модуль "одумається"
  //     final result = await completer.future.timeout(
  //         const Duration(seconds: 10),
  //         onTimeout: () => bytes
  //     );
  //
  //     final rawHtml = String.fromCharCodes(result);
  //
  //     // Якщо прийшло порожньо, значить він чекає іншого формату запиту
  //     if (rawHtml.isEmpty) {
  //       debugPrint("Модуль мовчить, хоча сокет живий.");
  //       return [];
  //     }
  //
  //     if (!rawHtml.contains('<html')) return [];
  //
  //     return _parseNetworks(_cleanUsrHtml(rawHtml.substring(rawHtml.indexOf('<html'))));
  //
  //   } catch (e) {
  //     debugPrint("Помилка: $e");
  //     return [];
  //   } finally {
  //     socket?.destroy(); // Важливо: вбиваємо сокет, щоб звільнити чергу модуля
  //   }
  // }
  // @override
  // Future<List<Map<String, dynamic>>> getScanResults() async {
  //   try {
  //     // 1. Прямий запит, отримуємо байти без спроб їх розпарсити автоматично
  //     final response = await http.get(
  //       Uri.parse(UsrWiFi232HttpClientHelper.baseUrlHttpSiteSurvey),
  //       headers: {'Authorization': UsrClientHelper.authBasicHeader},
  //     ).timeout(const Duration(seconds: 5));
  //
  //     // 2. Декодуємо байти вручну (String.fromCharCodes — це саме те, що робить браузер)
  //     // Це ігнорує всі UTF-помилки та байти типу 214
  //     final rawHtml = String.fromCharCodes(response.bodyBytes);
  //
  //     // 3. Твій метод очищення (без змін назви)
  //     final cleanHtml = _cleanUsrHtml(rawHtml);
  //
  //     debugPrint('DEBUG_BODY: $cleanHtml');
  //
  //     List<Map<String, dynamic>> networks = [];
  //
  //     // 4. Регулярка, яка не вгадує, а чітко бере дані з value та наступних колонок
  //     final regExp = RegExp(
  //       r'value="([^"]*)".*?<td>([\da-fA-F:]+)<\/td><td>(\d+)%<\/td>',
  //       caseSensitive: false,
  //     );
  //
  //     final matches = regExp.allMatches(cleanHtml);
  //
  //     for (final m in matches) {
  //       final ssid = m.group(1) ?? "";
  //       if (ssid.isEmpty) continue;
  //
  //       networks.add({
  //         'ssid': ssid,
  //         'bssid': m.group(2) ?? "",
  //         'level': int.tryParse(m.group(3) ?? "0") ?? 0,
  //       });
  //     }
  //
  //     networks.sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));
  //     return networks;
  //
  //   } catch (e) {
  //     debugPrint("HTTP Error: $e");
  //     return [];
  //   }
  // }

  List<Map<String, dynamic>> _parseNetworks(String cleanHtml) {
    List<Map<String, dynamic>> networks = [];
    // Жорстка регулярка по склеєних тегах
    final regExp = RegExp(
      r'value="([^"]*)".*?<\/td><td>([\da-fA-F:]+)<\/td><td>(\d+)%<\/td>',
      caseSensitive: false,
    );

    for (final m in regExp.allMatches(cleanHtml)) {
      final ssid = m.group(1) ?? "";
      if (ssid.isNotEmpty) {
        networks.add({
          'ssid': ssid,
          'bssid': m.group(2) ?? "",
          'level': int.tryParse(m.group(3) ?? "0") ?? 0,
        });
      }
    }

    networks.sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));
    return networks;
  }

  String _cleanUsrHtml(String html) {
    return html
    // 1. Видаляємо коментарі (тепер RegExp валідний)
        .replaceAll(RegExp(r'', dotAll: true), '')
    // 2. Замінюємо &nbsp; та прибираємо зайві пробіли/переноси
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
    // 3. Склеюємо теги, щоб регулярка не промахувалася
        .replaceAll(RegExp(r'>\s+<'), '><')
        .trim();
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

  @override
  String? mac;

  @override
  String? ssidName;
}