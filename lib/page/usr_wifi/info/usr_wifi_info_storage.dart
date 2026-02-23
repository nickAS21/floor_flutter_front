import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data_home/data_location_type.dart';
import 'data_usr_wifi_info.dart';

class UsrWiFiInfoStorage {
  static const String _keyPrefix = 'usr_wifi_info_list_'; // Змінив префікс для списків

  // 1. ЗАВАНТАЖЕННЯ ВСЬОГО СПИСКУ ДЛЯ ЛОКАЦІЇ
  Future<List<DataUsrWiFiInfo>> loadAllInfoForLocation(LocationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _keyPrefix + type.name;
    final String? data = prefs.getString(key);

    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => DataUsrWiFiInfo.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // 2. ЗБЕРЕЖЕННЯ ВСЬОГО СПИСКУ
  Future<void> saveFullList(LocationType type, List<DataUsrWiFiInfo> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _keyPrefix + type.name;
    final String data = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(key, data);
  }

  // 3. ОНОВЛЕННЯ АБО ДОДАВАННЯ ЗА ID (Твій метод тепер працюватиме)
  Future<bool> updateOrAddById(DataUsrWiFiInfo newItem) async {
    List<DataUsrWiFiInfo> list = await loadAllInfoForLocation(newItem.locationType);

    int index = list.indexWhere((e) => e.id == newItem.id);

    bool isUpdated = false;
    if (index != -1) {
      list[index] = newItem;
      isUpdated = true;
    } else {
      list.add(newItem);
      isUpdated = false;
    }

    await saveFullList(newItem.locationType, list);
    return isUpdated;
  }

  // 4. Перенесення модулів між локаціями
  Future<void> moveItemsToLocation({
    required LocationType from,
    required LocationType to,
    required List<DataUsrWiFiInfo> itemsToMove, // Передаємо вже готові об'єкти
  }) async {
    // 1. Вантажимо цільовий список (куди переносимо)
    List<DataUsrWiFiInfo> targetList = await loadAllInfoForLocation(to);
    // 2. Вантажимо вихідний список (звідки видаляємо)
    List<DataUsrWiFiInfo> sourceList = await loadAllInfoForLocation(from);

    for (var item in itemsToMove) {
      // Оновлюємо мітку локації в самому об'єкті
      item.locationType = to;

      // Додаємо в цільову локацію (з перевіркою дублікатів по ID)
      int existingIndex = targetList.indexWhere((target) => target.id == item.id);
      if (existingIndex != -1) {
        targetList[existingIndex] = item;
      } else {
        targetList.add(item);
      }

      // Видаляємо з початкової локації
      sourceList.removeWhere((e) => e.id == item.id);
    }

    // 3. Зберігаємо обидва списки — це і є твоя "чиста" копія
    await saveFullList(from, sourceList);
    await saveFullList(to, targetList);
  }

  // Для сумісності з твоїм старим кодом (якщо десь викликається loadInfo)
  Future<DataUsrWiFiInfo> loadInfo(LocationType type) async {
    final list = await loadAllInfoForLocation(type);
    if (list.isNotEmpty) return list.first;
    return DataUsrWiFiInfo(locationType: type);
  }

  // --- НОВІ МЕТОДИ ТІЛЬКИ ДЛЯ СИНХРОНІЗАЦІЇ ---

  /// НОВИЙ: Повне видалення гілки локації перед синхронізацією з сервером
  Future<void> clearLocationData(LocationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix + type.name);
  }

  /// НОВИЙ: Масове збереження (те саме, що saveFullList, але з назвою для логіки синхронізації)
  Future<void> replaceAllWithServerData(LocationType type, List<DataUsrWiFiInfo> list) async {
    await saveFullList(type, list);
  }
}