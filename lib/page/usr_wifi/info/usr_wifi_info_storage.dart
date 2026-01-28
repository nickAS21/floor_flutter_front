import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data_home/data_location_type.dart';
import 'data_usr_wifi_info.dart';

class UsrWiFiInfoStorage {
  static const String _keyPrefix = 'usr_wifi_info_';

  // Збереження даних для конкретної локації
  Future<void> saveInfo(DataUsrWiFiInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _keyPrefix + info.locationType.name;
    await prefs.setString(key, jsonEncode(info.toJson()));
  }

  // Читання даних
  Future<DataUsrWiFiInfo> loadInfo(LocationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _keyPrefix + type.name;
    final String? data = prefs.getString(key);

    if (data != null) {
      return DataUsrWiFiInfo.fromJson(jsonDecode(data));
    }
    // Якщо даних немає, повертаємо дефолтний об'єкт, як у Java сервісі
    return DataUsrWiFiInfo(locationType: type);
  }
}