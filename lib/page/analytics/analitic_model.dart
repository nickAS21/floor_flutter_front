class AnalyticModel {
  final int timestamp;
  final String location;
  final double gridPower;
  final double gridDailyDayPower;
  final double gridDailyNightPower;
  final double gridDailyTotalPower;
  final double solarPower;
  final double solarDailyPower;
  final double homePower;
  final double homeDailyPower;
  final double bmsSoc;
  final double bmsDailyDischarge;
  final double bmsDailyCharge;
  final double temperatureOut;
  final double humidityOut;
  final double luminanceOut;
  final double temperatureIn;
  final double humidityIn;
  final double luminanceIn;

  AnalyticModel({
    required this.timestamp,
    required this.location,
    required this.gridPower,
    required this.gridDailyDayPower,
    required this.gridDailyNightPower,
    required this.gridDailyTotalPower,
    required this.solarPower,
    required this.solarDailyPower,
    required this.homePower,
    required this.homeDailyPower,
    required this.bmsSoc,
    required this.bmsDailyDischarge,
    required this.bmsDailyCharge,
    required this.temperatureOut,
    required this.humidityOut,
    required this.luminanceOut,
    required this.temperatureIn,
    required this.humidityIn,
    required this.luminanceIn,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory AnalyticModel.fromJson(Map<String, dynamic> json) {
    return AnalyticModel(
      timestamp: json['timestamp'] ?? 0, // Чистий UTC від сервера
      location: json['location'] ?? '',
      gridPower: _toDouble(json['gridPower']),
      gridDailyDayPower: _toDouble(json['gridDailyDayPower']),
      gridDailyNightPower: _toDouble(json['gridDailyNightPower']),
      gridDailyTotalPower: _toDouble(json['gridDailyTotalPower']),
      solarPower: _toDouble(json['solarPower']),
      solarDailyPower: _toDouble(json['solarDailyPower']),
      homePower: _toDouble(json['homePower']),
      homeDailyPower: _toDouble(json['homeDailyPower']),
      bmsSoc: _toDouble(json['bmsSoc']),
      bmsDailyDischarge: _toDouble(json['bmsDailyDischarge']),
      bmsDailyCharge: _toDouble(json['bmsDailyCharge']),
      temperatureOut: _toDouble(json['temperatureOut']),
      humidityOut: _toDouble(json['humidityOut']),
      luminanceOut: _toDouble(json['luminanceOut']),
      temperatureIn: _toDouble(json['temperatureIn']),
      humidityIn: _toDouble(json['humidityIn']),
      luminanceIn: _toDouble(json['luminanceIn']),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'location': location,
    'gridPower': gridPower,
    'gridDailyDayPower': gridDailyDayPower,
    'gridDailyNightPower': gridDailyNightPower,
    'gridDailyTotalPower': gridDailyTotalPower,
    'solarDailyPower': solarDailyPower,
    'solarPower': solarPower,
    'homePower': homePower,
    'homeDailyPower': homeDailyPower,
    'bmsSoc': bmsSoc,
    'bmsDailyDischarge': bmsDailyDischarge,
    'bmsDailyCharge': bmsDailyCharge,
    'temperatureOut': temperatureOut,
    'humidityOut': humidityOut,
    'luminanceOut': luminanceOut,
    'temperatureIn': temperatureIn,
    'humidityIn': humidityIn,
    'luminanceIn': luminanceIn,
  };
}