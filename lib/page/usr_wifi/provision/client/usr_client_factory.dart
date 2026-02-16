
import 'package:floor_front/page/usr_wifi/provision/client/usr_client.dart';

import 'http/usr_s100_http_client.dart';
import 'http/usr_wifi_232_http_client.dart';

class UsrClientFactory {
  /// Основна точка входу для пошуку пристрою.
  /// Кожен виклик — це новий екземпляр (Rescan).
  static Future<UsrClient> discoverDevice() async {
    // 1. Створюємо тимчасовий екземпляр S100 для перевірки API
    final s100Candidate = UsrS100HttpClient();

    // 2. Спроба отримати MAC через специфічний для S100 шлях (/api/nv/get)
    final s100Mac = await s100Candidate.getMacAddress();

    if (s100Mac != null) {
      // Якщо відповіло — це 100% модель S100
      return s100Candidate;
    } else {
      // 3. Якщо S100 не знайдено, створюємо гібридний клієнт для 232 серії.
      // Він сам всередині розбереться, як працювати (UDP на Android або HTTP на Linux).
      return UsrWiFi232HttpClient();
    }
  }
}