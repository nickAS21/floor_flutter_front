class AnalyticModel {
  final int timestamp;
  final String powerType;
  final String location;
  final double powerDay;
  final double powerNight;
  final double powerTotal;

  AnalyticModel({
    required this.timestamp,
    required this.powerType,
    required this.location,
    required this.powerDay,
    required this.powerNight,
    required this.powerTotal,
  });

  factory AnalyticModel.fromJson(Map<String, dynamic> json) {
    return AnalyticModel(
      timestamp: json['timestamp'] ?? 0,
      powerType: json['powerType'] ?? '',
      location: json['location'] ?? '',
      powerDay: (json['powerDay'] as num).toDouble(),
      powerNight: (json['powerNight'] as num).toDouble(),
      powerTotal: (json['powerTotal'] as num).toDouble(),
    );
  }
}