import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/api_server_helper.dart';
import '../../../helpers/app_helper.dart';
import '../info/data_usr_wifi_info.dart';
import '../../data_home/data_location_type.dart';

class UsrWiFiInfoConnection {
  static Future<List<DataUsrWiFiInfo>> fetchFromServer(LocationType location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      String locPath = location == LocationType.golego ? AppHelper.pathGolego : AppHelper.pathDacha;
      final String url = '${ApiServerHelper.backendUrl}${AppHelper.apiPathProvision}$locPath';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => DataUsrWiFiInfo.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("GET Error: $e");
    }
    return [];
  }

  static Future<bool> uploadToServer(LocationType location, List<DataUsrWiFiInfo> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      String locPath = location == LocationType.golego ? AppHelper.pathGolego : AppHelper.pathDacha;
      final String url = '${ApiServerHelper.backendUrl}${AppHelper.apiPathProvision}$locPath';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(list.map((e) => e.toJson()).toList()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("POST Error: $e");
      return false;
    }
  }
}