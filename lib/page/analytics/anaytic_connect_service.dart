import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_helper.dart';
import '../../helpers/api_server_helper.dart';
import '../data_home/data_location_type.dart';
import 'analitic_model.dart';
import 'analytic_enums.dart';

class ExcelColumns {
  static const String time = "Updated Time";
  static const String energy = "Daily Energy Buy(kWh)";
}

class AnalyticConnectService {

  // 1. GET МЕТОДИ
  Future<List<AnalyticModel>> getAnalyticDay({
    required DateTime date,
    required LocationType location,
    required PowerType powerType,
  }) async {
    final dateStr = DateFormat(AppHelper.paternYYYYMMDD).format(date);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathDay}"
        "?date=$dateStr&locationType=${location.name}&powerType=${powerType.apiValue}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticDays({
    required DateTime dateStart,
    required DateTime dateFinish,
    required LocationType location,
    required PowerType powerType,
  }) async {
    final startStr = DateFormat(AppHelper.paternYYYYMMDD).format(dateStart);
    final finishStr = DateFormat(AppHelper.paternYYYYMMDD).format(dateFinish);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathDays}"
        "?dateStart=$startStr&dateFinish=$finishStr&locationType=${location.name}&powerType=${powerType.apiValue}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticMonth({
    required DateTime date,
    required LocationType location,
    required PowerType powerType,
  }) async {
    final monthStr = DateFormat('yyyy-MM').format(date);
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathMonth}"
        "?date=$monthStr&locationType=${location.name}&powerType=${powerType.apiValue}";
    return _sendGetRequest(path);
  }

  Future<List<AnalyticModel>> getAnalyticYear({
    required int year,
    required LocationType location,
    required PowerType powerType,
  }) async {
    final path = "${AppHelper.apiPathAnalytic}${AppHelper.subPathYear}"
        "?year=$year&locationType=${location.name}&powerType=${powerType.apiValue}";
    return _sendGetRequest(path);
  }

  // 2. УНІВЕРСАЛЬНИЙ GET (Логіка з history)
  Future<List<AnalyticModel>> _sendGetRequest(String path) async {
    final String fullUrl = '${ApiServerHelper.backendUrl}$path';
    debugPrint("Requesting GET: $fullUrl");

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
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) {
          try {
            return AnalyticModel.fromJson(json);
          } catch (e) {
            debugPrint("Analytic parse error: $e");
            return null;
          }
        }).whereType<AnalyticModel>().toList();
      } else {
        debugPrint("API Error: ${response.statusCode} at $fullUrl");
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    return [];
  }

  // 3. POST МЕТОД (Import)
  Future<bool> importXmlsData(List<AnalyticModel> data) async {
    final String fullUrl = '${ApiServerHelper.backendUrl}${AppHelper.apiPathImportXMLS}';
    debugPrint("Requesting POST: $fullUrl");

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

      if (response.statusCode == 200) {
        debugPrint("Import successful");
        return true;
      } else {
        debugPrint("Import failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Import error: $e");
    }
    return false;
  }

  // 4. ПАРСИНГ EXCEL
  List<AnalyticModel> processExcelData({
    required Uint8List bytes,
    required LocationType location,
  }) {
    // Декодуємо байти. Якщо файл битий або не XLSX, тут може бути помилка
    var excel = Excel.decodeBytes(bytes);
    List<AnalyticModel> detailedPoints = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      var rows = sheet.rows;
      if (rows.length < 2) continue;

      // Знаходимо індекси колонок

      final int timeIdx = _getColumnIndex(rows[0], ExcelColumns.time);
      final int energyIdx = _getColumnIndex(rows[0], ExcelColumns.energy);

      if (timeIdx == -1 || energyIdx == -1) {
        debugPrint("Колонки не знайдено: Time=$timeIdx, Energy=$energyIdx");
        continue;
      }

      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];

        // Перевірка на довжину рядка та пусті клітинки
        if (row.length <= timeIdx || row.length <= energyIdx) continue;

        var timeCell = row[timeIdx];
        var energyCell = row[energyIdx];

        if (timeCell == null || energyCell == null) continue;

        try {
          DateTime? time;
          var cellTimeValue = timeCell.value;

          // 1. Обробка дати (підтримка різних версій бібліотеки)
          if (cellTimeValue is DateTimeCellValue) {
            time = DateTime(
                cellTimeValue.year,
                cellTimeValue.month,
                cellTimeValue.day,
                cellTimeValue.hour,
                cellTimeValue.minute
            );
          } else if (cellTimeValue != null) {
            // Спроба розпарсити рядок, якщо це не тип DateTime
            String timeStr = cellTimeValue.toString().replaceAll('/', '-');
            time = DateTime.tryParse(timeStr);
          }

          if (time == null) continue;

          // 2. Обробка енергії (безпечне перетворення)
          double energy = 0.0;
          var cellEnergyValue = energyCell.value;

          if (cellEnergyValue is DoubleCellValue) {
            energy = cellEnergyValue.value;
          } else if (cellEnergyValue is IntCellValue) {
            energy = cellEnergyValue.value.toDouble();
          } else if (cellEnergyValue != null) {
            energy = double.tryParse(cellEnergyValue.toString()) ?? 0.0;
          }

          detailedPoints.add(AnalyticModel(
            timestamp: time.millisecondsSinceEpoch,
            location: location.apiValue,
            powerType: PowerType.GRID.apiValue,
            powerDay: 0.0,
            powerNight: 0.0,
            powerTotal: energy,
          ));
        } catch (e) {
          debugPrint("Помилка в рядку $i: $e");
        }
      }
    }
    return detailedPoints;
  }

  int _getColumnIndex(List<Data?> headerRow, String columnName) {
    // Клонуємо та очищаємо назву нашої цілі один раз
    final String cleanTarget = _cloneAndClean(columnName);

    return headerRow.indexWhere((element) {
      if (element == null || element.value == null) return false;

      // Створюємо тимчасовий очищений клон значення клітинки
      final String cleanCellClone = _cloneAndClean(element.value);

      return cleanCellClone.contains(cleanTarget);
    });
  }

  String _cloneAndClean(dynamic value) {
    if (value == null) return "";

    // Створюємо незалежну копію рядка та очищаємо її
    return value.toString()
        .replaceAll(RegExp(r'[^\x00-\x7F]+'), ' ') // Видаляємо не-ASCII кряки
        .replaceAll(RegExp(r'\s+'), ' ')           // Уніфікуємо пробіли
        .trim()
        .toLowerCase();
  }
}