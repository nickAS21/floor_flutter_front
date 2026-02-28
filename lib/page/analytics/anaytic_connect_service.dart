import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'analitic_model.dart';
import 'analytic_enums.dart';

class AnalyticConnectService {
  // Видаляємо baseUrl та token з конструктора, щоб отримати їх всередині,
  // як це зроблено в HomePage, або передаємо їх для гнучкості.

  Future<List<AnalyticModel>> fetchData({
    required ViewMode mode,
    required DateTime date,
    required LocationType location,
    required PowerType powerType,
    required String token,
  }) async {
    String subPath = '';
    Map<String, String> params = {
      'locationType': location.name.toUpperCase(), // GOLEGO або DACHA
      'powerType': powerType.apiValue,            // GRID, SOLAR і т.д.
    };

    // Формування специфічних шляхів згідно з AnalyticController
    if (mode == ViewMode.day) {
      subPath = AppHelper.subPathDay;
      params['date'] = DateFormat('yyyy-MM-dd').format(date);
    } else if (mode == ViewMode.month) {
      subPath = AppHelper.subPathMonth;
      params['date'] = DateFormat('yyyy-MM').format(date);
    } else if (mode == ViewMode.year) {
      subPath = AppHelper.subPathYear;
      params['year'] = DateFormat('yyyy').format(date);
    }

    // Збірка фінального URL за аналогією з HomePage
    // Використовуємо прямий шлях контролера: /api/analytic
    // final String apiUrl = '${ApiServerHelper.backendUrl}/api/analytic$subPath';
    final String apiUrl = '${ApiServerHelper.backendUrl}${AppHelper.apiPathAnalytic}$subPath';

    try {
      final response = await http.get(
        Uri.parse(apiUrl).replace(queryParameters: params),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded.map((e) => AnalyticModel.fromJson(e)).toList();
        } else if (decoded != null) {
          return [AnalyticModel.fromJson(decoded)];
        }
        return [];
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow; // Передаємо помилку вище для обробки в UI (SnackBar)
    }
  }
}