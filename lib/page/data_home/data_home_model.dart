class DataHome {
  final int timestamp;
  final double batterySoc;
  final double batteryVol;
  final double batteryCurrent;
  final double solarPower;
  final double homePower;
  final bool gridStatusRealTimeOnLine;
  final bool gridStatusRealTimeSwitch;
  final String timestampLastUpdateGridStatus;
  final double gridPower;
  final double dailyConsumptionPower;
  final double dailyGridPower;
  final double dailyBatteryCharge;
  final double dailyBatteryDischarge;
  final double dailyProductionSolarPower;
  final Map<int, double> gridVoltageLs;

  DataHome({
    required this.timestamp,
    required this.batterySoc,
    required this.batteryVol,
    required this.batteryCurrent,
    required this.solarPower,
    required this.homePower,
    required this.gridStatusRealTimeOnLine,
    required this.gridStatusRealTimeSwitch,
    required this.timestampLastUpdateGridStatus,
    required this.gridPower,
    required this.dailyConsumptionPower,
    required this.dailyGridPower,
    required this.dailyBatteryCharge,
    required this.dailyBatteryDischarge,
    required this.dailyProductionSolarPower,
    required this.gridVoltageLs,
  });

  factory DataHome.fromJson(Map<String, dynamic> json) {
    final Map<int, double> voltages = {};
    if (json['gridVoltageLs'] != null) {
      (json['gridVoltageLs'] as Map<String, dynamic>).forEach((key, value) {
        voltages[int.parse(key)] = (value as num).toDouble();
      });
    }
    return DataHome(
      gridVoltageLs: voltages,
      timestamp: json['timestamp'] ?? 0,
      batterySoc: (json['batterySoc'] ?? 0).toDouble(),
      batteryVol: (json['batteryVol'] ?? 0).toDouble(),
      batteryCurrent: (json['batteryCurrent'] ?? 0).toDouble(),
      solarPower: (json['solarPower'] ?? 0).toDouble(),
      homePower: (json['homePower'] ?? 0).toDouble(),
      gridStatusRealTimeOnLine: json['gridStatusRealTimeOnLine'] ?? false,
      gridStatusRealTimeSwitch: json['gridStatusRealTimeSwitch'] ?? false,
      timestampLastUpdateGridStatus: json['timestampLastUpdateGridStatus']?.toString() ?? 'null',
      gridPower: (json['gridPower'] ?? 0).toDouble(),
      dailyConsumptionPower: (json['dailyConsumptionPower'] ?? json['consumptionPower'] ?? 0).toDouble(),
      dailyGridPower: (json['dailyGridPower'] ?? 0).toDouble(),
      dailyBatteryCharge: (json['dailyBatteryCharge'] ?? 0).toDouble(),
      dailyBatteryDischarge: (json['dailyBatteryDischarge'] ?? 0).toDouble(),
      dailyProductionSolarPower: (json['dailyProductionSolarPower'] ?? 0).toDouble(),
    );
  }
}