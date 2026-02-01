import '../info/data_usr_wifi_info.dart';

class UsrWiFiInfoSynchronization {
  /// ЛОГІКА: Нові додаємо, старі заміщаємо (по ID)
  /// Цей метод оновлює серверний список даними з локального
  static List<DataUsrWiFiInfo> updateFromLocalToServer({
    required List<DataUsrWiFiInfo> currentServerList,
    required List<DataUsrWiFiInfo> localList,
  }) {
    // Створюємо карту для швидкого пошуку та заміни за ID
    final Map<int, DataUsrWiFiInfo> map = {
      for (var item in currentServerList) item.id: item
    };

    for (var localItem in localList) {
      // Якщо ID існує — заміщаємо, якщо ні — додаємо в карту
      map[localItem.id] = localItem;
    }

    final List<DataUsrWiFiInfo> result = map.values.toList();
    // Сортуємо за ID для ідентичного відображення з UsrWiFiInfoListPage
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  static List<DataUsrWiFiInfo> copyServerToLocal(List<DataUsrWiFiInfo> serverList) {
    // Повертаємо новий список, щоб уникнути посилань на той самий об'єкт у пам'яті
    return List<DataUsrWiFiInfo>.from(serverList)
      ..sort((a, b) => a.id.compareTo(b.id));
  }
}