import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static Future<void> saveValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> removeValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }


  static Future<void> saveValueList(String key, List<String>? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value!);
  }

  static Future<List<String>> getValueList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedLocaleList = prefs.getStringList(key) ?? [];
    return savedLocaleList;
  }
}