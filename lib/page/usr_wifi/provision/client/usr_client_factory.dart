import 'package:floor_front/page/usr_wifi/provision/client/usr_client.dart';
import 'package:flutter/cupertino.dart';
import 'http/usr_s100_http_client.dart';
import 'http/usr_wifi_232_http_client.dart';

class UsrClientFactory {
  static Future<UsrClient> discoverDevice() async {
    // Внутрішня функція для ретраїв, щоб не дублювати код
    Future<String?> getMacWithRetry(UsrClient client) async {
      for (int i = 0; i < 2; i++) {
        try {
          // Збільшуємо таймаут до 2 секунд - це стандарт для китайських модулів
          final mac = await client.getMacAddress().timeout(const Duration(seconds: 2));
          if (mac != null && mac.isNotEmpty) return mac;
        } catch (e) {
          debugPrint("Спроба ${i + 1} для ${client.runtimeType} невдала: $e");
          // Мікро-пауза перед повтором, щоб мережевий стек "продихався"
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      return null;
    }

    // Запускаємо пошук обох типів паралельно, але з нормальними таймаутами
    final results = await Future.wait([
      getMacWithRetry(UsrWiFi232HttpClient()),
      getMacWithRetry(UsrS100HttpClient()),
    ]);

    final String? mac232 = results[0];
    final String? macS100 = results[1];

    if (mac232 != null) {
      debugPrint("Виявлено пристрій серії 232 (MAC: $mac232)");
      return UsrWiFi232HttpClient()..mac = mac232;
    }

    if (macS100 != null) {
      debugPrint("Виявлено пристрій серії S100 (MAC: $macS100)");
      return UsrS100HttpClient()..mac = macS100;
    }

    debugPrint("Пристрій не знайдено, повертаємо дефолтний клієнт.");
    return UsrWiFi232HttpClient();
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