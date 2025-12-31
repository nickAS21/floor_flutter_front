import '../unit/battery_info_model.dart';

class HistoryModel {
  final String timestamp;
  final String gridStatus;      // Online / Offline
  final String? gridDuration;   // Тривалість (наприклад, "3h 20m")
  final List<BatteryInfoModel> batteries; // Список батарей

  HistoryModel({
    required this.timestamp,
    required this.gridStatus,
    this.gridDuration,
    required this.batteries,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    // 1. Отримуємо сирий список з JSON (ключ 'batteries' як у Java)
    var list = json['batteries'] as List?;

    // 2. Перетворюємо кожен елемент списку на BatteryInfoModel
    List<BatteryInfoModel> batteryObjects = list != null
        ? list.map((i) => BatteryInfoModel.fromJson(i)).toList()
        : [];

    return HistoryModel(
      timestamp: json['timestamp'] ?? '',
      gridStatus: json['gridStatus'] ?? 'Unknown',
      // В Java поле названо gridDuration
      gridDuration: json['gridDuration'],
      batteries: batteryObjects,
    );
  }

  // Геттер для логіки іконок у UI
  bool get isGridOnline => gridStatus.toLowerCase() == 'online';

  // Геттер для виводу тільки часу в ліву колонку картки
  String get timeOnly => timestamp.contains(' ') ? timestamp.split(' ')[1] : timestamp;
}