class DataHome {
  final int timestamp;
  final double batterySoc;
  final double batteryVol;
  final double batteryCurrent;
  final bool gridStatusRealTime;
  final double solarPower;
  // Додаємо ці поля для розрахунку потоків
  final double consumptionPower;
  final double gridPower;
  final double batteryPower; // Скільки ват йде з/в батарею

  DataHome({
    required this.timestamp,
    required this.batterySoc,
    required this.batteryVol,
    required this.batteryCurrent,
    required this.gridStatusRealTime,
    required this.solarPower,
    this.consumptionPower = 0,
    this.gridPower = 0,
    this.batteryPower = 0,
  });

  factory DataHome.fromJson(Map<String, dynamic> json) {
    return DataHome(
      timestamp: json['timestamp'] ?? 0,
      batterySoc: (json['batterySoc'] ?? 0).toDouble(),
      batteryVol: (json['batteryVol'] ?? 0).toDouble(),
      batteryCurrent: (json['batteryCurrent'] ?? 0).toDouble(),
      gridStatusRealTime: json['gridStatusRealTime'] ?? false,
      solarPower: (json['solarPower'] ?? 0).toDouble(),
      // Ці дані зазвичай приходять з API, або вираховуються:
      consumptionPower: (json['consumptionPower'] ?? 0).toDouble(),
      gridPower: (json['gridPower'] ?? 0).toDouble(),
      batteryPower: (json['batteryPower'] ?? 0).toDouble(),
    );
  }
}