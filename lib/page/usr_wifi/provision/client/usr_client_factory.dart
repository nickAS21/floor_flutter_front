import 'package:floor_front/helpers/app_helper.dart';
import 'package:floor_front/page/usr_wifi/provision/client/usr_client.dart';
import 'package:flutter/cupertino.dart';
import 'http/usr_s100_http_client.dart';
import 'http/usr_wifi_232_http_client.dart';

class UsrClientFactory {
  static Future<UsrClient> discoverDevice() async {

    final s100Result = await getMacWithRetry(UsrS100HttpClient());
    if (s100Result.isNotBlank){
      debugPrint("Виявлено пристрій серії S100 (MAC: $s100Result)");
      return UsrS100HttpClient()..mac = s100Result;
    }

    final wifi232Result = await getMacWithRetry(UsrWiFi232HttpClient());
    if (wifi232Result.isNotBlank) {
      debugPrint("Виявлено пристрій серії 232 (MAC: $wifi232Result)");
      return UsrWiFi232HttpClient()..mac = wifi232Result;
    }

    debugPrint("Пристрій не знайдено, повертаємо дефолтний клієнт.");
    return UsrWiFi232HttpClient();
  }

  // Внутрішня функція для ретраїв, щоб не дублювати код
  static Future<String?> getMacWithRetry(UsrClient client) async {
    for (int i = 0; i < 2; i++) {
      try {
        // Збільшуємо таймаут до 3 секунд - це стандарт для китайських модулів
        final mac = await client.getMacAddress().timeout(const Duration(seconds: 4));
        if (mac.isNotBlank) return mac;
      } catch (e) {
        debugPrint("Спроба ${i + 1} для ${client.runtimeType} невдала: $e");
        // Мікро-пауза перед повтором, щоб мережевий стек "продихався"
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return null;
  }


  static List<Map<String, dynamic>> processScanResults(List<dynamic> results) {
    final Map<String, Map<String, dynamic>> uniqueMap = {};
    for (var net in results) {
      final String ssid = (net['ssid'] ?? "").toString();
      if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
      uniqueMap[ssid] = net;
    }
    final list = uniqueMap.values.toList();
    list.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
    return list;
  }
}