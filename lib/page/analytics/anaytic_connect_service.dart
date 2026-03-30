import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:floor_front/page/analytics/solarman_excel_columns.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'analitic_model.dart';

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

  Future<ImportResult> importXmlsData(List<AnalyticModel> data) async {
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
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return ImportResult(true, "Дані успішно імпортовано");
      } else if (response.statusCode == 413) {
        return ImportResult(false, "Помилка 413: Файл занадто великий для сервера. Зменшіть обсяг даних.");
      } else {
        return ImportResult(false, "Сервер повернув помилку: ${response.statusCode}");
      }
    } catch (e) {
      return ImportResult(false, "Помилка з'єднання: $e");
    }
  }

  Future<List<AnalyticModel>> processExcelData({
    required Uint8List bytes,
    required LocationType location,
  }) async {
    try {
      // compute запускає _doExcelWork у фоновому потоці (Isolate)
      // Весь важкий парсинг і декодування Excel тепер НЕ гальмують UI
      return await compute(decodeExcelIsolate, {
        'bytes': bytes,
        'locationName': location.name,
      });
    } catch (e) {
      debugPrint("Критична помилка ізолята: $e");
      return [];
    }
  }


  int _parseTimestamp(Data? cell) {
    if (cell?.value == null) return DateTime.now().millisecondsSinceEpoch;

    var val = cell!.value;
    DateTime? time;

    if (val is DateTimeCellValue) {
      time = DateTime.utc(val.year, val.month, val.day, val.hour, val.minute, val.second);
    } else if (val is DateTime) {
      time = val as DateTime?;
    } else {
      time = DateTime.tryParse(val.toString().replaceAll('/', '-'));
    }

    return time?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  }

  Map<SolarmanExcelColumns, int> validateAndGetIndices(List<Data?> headerRow) {
    Map<SolarmanExcelColumns, int> indices = {};
    for (var col in SolarmanExcelColumns.values) {
      indices[col] = _getColumnIndex(headerRow, col.label);
    }
    return indices;
  }
  int _getColumnIndex(List<Data?> headerRow, String target) {
    // Очищаємо ціль від можливих спецсимволів
    final cleanTarget = target.replaceAll('\u00A0', ' ').trim();

    for (int i = 0; i < headerRow.length; i++) {
      var val = headerRow[i]?.value;
      if (val == null) continue;

      // Очищаємо значення з клітинки Excel
      String cellText = val.toString()
          .replaceAll('\u00A0', ' ') // Заміна нерозривного пробілу на звичайний
          .trim();

      if (cellText == cleanTarget) {
        return i;
      }
    }
    throw Exception("Стовпець '$target' не знайдено!");
  }


  List<AnalyticModel> decodeExcelIsolate(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final String locationName = params['locationName'];

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final parser = AnalyticConnectService();
    final indices = parser.validateAndGetIndices(sheet.rows.first);

    final rows = sheet.rows;
    final result = <AnalyticModel>[];

    final int idxTime = indices[SolarmanExcelColumns.timeStamp]!;
    final int idxGrid = indices[SolarmanExcelColumns.gridPower]!;
    final int idxGridTotal = indices[SolarmanExcelColumns.gridDailyTotalPower]!;
    final int idxSolar = indices[SolarmanExcelColumns.solarPower]!;
    final int idxSolarDaily = indices[SolarmanExcelColumns.solarDailyPower]!;
    final int idxHome = indices[SolarmanExcelColumns.homePower]!;
    final int idxHomeDaily = indices[SolarmanExcelColumns.homeDailyPower]!;
    final int idxSoc = indices[SolarmanExcelColumns.bmsSoc]!;
    final int idxDischarge = indices[SolarmanExcelColumns.bmsDailyDischarge]!;
    final int idxCharge = indices[SolarmanExcelColumns.bmsDailyCharge]!;

    // ✅ правильний fast double для CellValue
    double fastDouble(Data? cell) {
      final v = cell?.value;

      if (v == null) return 0;

      if (v is IntCellValue) {
        return v.value.toDouble();
      }

      if (v is DoubleCellValue) {
        return v.value;
      }

      if (v is TextCellValue) {
        return double.tryParse(v.value.text ?? '') ?? 0;
      }

      return 0;
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      if (row.length <= idxCharge) continue;

      final timeCell = row[idxTime];
      if (timeCell?.value == null) continue;

      final timestamp = parser._parseTimestamp(timeCell);

      result.add(AnalyticModel(
        timestamp: timestamp,
        location: locationName,
        gridPower: fastDouble(row[idxGrid]),
        gridDailyTotalPower: fastDouble(row[idxGridTotal]),
        solarPower: fastDouble(row[idxSolar]),
        solarDailyPower: fastDouble(row[idxSolarDaily]),
        homePower: fastDouble(row[idxHome]),
        homeDailyPower: fastDouble(row[idxHomeDaily]),
        bmsSoc: fastDouble(row[idxSoc]),
        bmsDailyDischarge: fastDouble(row[idxDischarge]),
        bmsDailyCharge: fastDouble(row[idxCharge]),

        gridDailyDayPower: 0,
        gridDailyNightPower: 0,
        temperatureOut: 0,
        humidityOut: 0,
        luminanceOut: 0,
        temperatureIn: 0,
        humidityIn: 0,
        luminanceIn: 0,
      ));
    }

    return result;
  }

  Future<bool> uploadExcelFile({required String filePath, required LocationType location}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      // Формуємо URL до нового ендпоінта на Spring Boot
      var uri = Uri.parse('${ApiServerHelper.backendUrl}${AppHelper.apiPathImportFileXMLS}');

      var request = http.MultipartRequest('POST', uri);

      // Заголовки
      request.headers['Authorization'] = 'Bearer $token';

      // Поля форми (метадані)
      request.fields['location'] = location.name; // Наприклад, "dacha"

      // Додаємо сам файл
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        // Можна додати filename, якщо сервер його очікує
      ));

      // Надсилаємо та чекаємо відповіді
      var streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Server rejected file: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Multipart error: $e");
      return false;
    }
  }

}

class ImportResult {
  final bool isSuccess;
  final String message;
  ImportResult(this.isSuccess, this.message);
}