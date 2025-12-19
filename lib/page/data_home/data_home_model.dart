class DataHome {
  final int timestamp;
  final double batterySoc;
  final double batteryVol;
  final double batteryCurrent;
  final bool gridStatusRealTime;
  final double solarPower;
  final double homePower;
  final double gridPower;
  final double dailyConsumptionPower;
  final double dailyGridPower;
  final double dailyBatteryCharge;
  final double dailyBatteryDischarge;
  final double dailyProductionSolarPower;

  DataHome({
    required this.timestamp,
    required this.batterySoc,
    required this.batteryVol,
    required this.batteryCurrent,
    required this.gridStatusRealTime,
    required this.solarPower,
    required this.homePower,
    required this.gridPower,
    required this.dailyConsumptionPower,
    required this.dailyGridPower,
    required this.dailyBatteryCharge,
    required this.dailyBatteryDischarge,
    required this.dailyProductionSolarPower,
  });

  factory DataHome.fromJson(Map<String, dynamic> json) {
    return DataHome(
      timestamp: json['timestamp'] ?? 0,
      batterySoc: (json['batterySoc'] ?? 0).toDouble(),
      batteryVol: (json['batteryVol'] ?? 0).toDouble(),
      batteryCurrent: (json['batteryCurrent'] ?? 0).toDouble(),
      gridStatusRealTime: json['gridStatusRealTime'] ?? false,
      solarPower: (json['solarPower'] ?? 0).toDouble(),
      homePower: (json['homePower'] ?? 0).toDouble(),
      gridPower: (json['gridPower'] ?? 0).toDouble(),
      dailyConsumptionPower: (json['dailyConsumptionPower'] ?? json['consumptionPower'] ?? 0).toDouble(),
      dailyGridPower: (json['dailyGridPower'] ?? 0).toDouble(),
      dailyBatteryCharge: (json['dailyBatteryCharge'] ?? 0).toDouble(),
      dailyBatteryDischarge: (json['dailyBatteryDischarge'] ?? 0).toDouble(),
      dailyProductionSolarPower: (json['dailyProductionSolarPower'] ?? 0).toDouble(),
    );
  }
}