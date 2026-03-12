import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'analitic_model.dart';

class ExcelColumns {
  static const String time = "Updated Time";
  static const String energy = "Daily Energy Buy(kWh)";
}

class AnalyticConnectService {

  Future<List<AnalyticModel>> getAnalyticDay({
    required DateTime date,
    required LocationType location,
  }) async {
    final dateStr = DateFormat(AppHelper.paternYYYYMMDD).format(date);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathDay}?date=$dateStr&locationType=${location.name}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticDays({
    required DateTime dateStart,
    required DateTime dateFinish,
    required LocationType location,
  }) async {
    final s = DateFormat(AppHelper.paternYYYYMMDD).format(dateStart);
    final f = DateFormat(AppHelper.paternYYYYMMDD).format(dateFinish);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathDays}?dateStart=$s&dateFinish=$f&locationType=${location.name}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticMonth({
    required DateTime date,
    required LocationType location,
  }) async {
    final monthStr = DateFormat('yyyy-MM').format(date);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathMonth}?date=$monthStr&locationType=${location.name}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticYear({
    required int year,
    required LocationType location,
  }) async {
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathYear}?year=$year&locationType=${location.name}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> _sendGetRequest(String path) async {
    final String fullUrl = '${ApiServerHelper.backendUrl}$path';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body); // Отримуємо голий список
        return decodedData.map((item) => AnalyticModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    return [];
  }

  Future<bool> importXmlsData(List<AnalyticModel> data) async {
    final String fullUrl = '${ApiServerHelper.backendUrl}${AppHelper.apiPathImportXMLS}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data.map((e) => e.toJson()).toList()),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Import error: $e");
      return false;
    }
  }

  List<AnalyticModel> processExcelData({
    required Uint8List bytes,
    required LocationType location,
  }) {
    var excel = Excel.decodeBytes(bytes);
    List<AnalyticModel> detailedPoints = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null || sheet.rows.length < 2) continue;

      final int tIdx = _getColumnIndex(sheet.rows[0], ExcelColumns.time);
      final int eIdx = _getColumnIndex(sheet.rows[0], ExcelColumns.energy);

      if (tIdx == -1 || eIdx == -1) continue;

      for (var i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        if (row.length <= tIdx || row.length <= eIdx) continue;

        try {
          DateTime? time;
          var val = row[tIdx]?.value;
          if (val is DateTimeCellValue) {
            time = DateTime(val.year, val.month, val.day, val.hour, val.minute);
          } else if (val != null) {
            time = DateTime.tryParse(val.toString().replaceAll('/', '-'));
          }

          if (time == null) continue;

          double energy = 0.0;
          var eVal = row[eIdx]?.value;
          if (eVal is DoubleCellValue) {
            energy = eVal.value;
          } else if (eVal is IntCellValue) {
            energy = eVal.value.toDouble();
          }

          detailedPoints.add(AnalyticModel(
            timestamp: time.millisecondsSinceEpoch,
            location: location.name,
            gridPower: 0.0,
            gridDailyDayPower: 0.0,
            gridDailyNightPower: 0.0,
            gridDailyTotalPower: energy,
            solarPower: 0.0,
            solarDailyPower: 0.0,
            homePower: 0.0,
            homeDailyPower: 0.0,
            bmsSoc: 0.0,
            bmsDailyDischarge: 0.0,
            bmsDailyCharge: 0.0,
          ));
        } catch (_) {}
      }
    }
    return detailedPoints;
  }

  int _getColumnIndex(List<Data?> header, String name) {
    final target = name.toLowerCase().trim();
    return header.indexWhere((c) => c?.value?.toString().toLowerCase().contains(target) ?? false);
  }
}