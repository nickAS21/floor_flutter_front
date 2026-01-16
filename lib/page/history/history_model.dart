class HistoryModel {
  final int timestamp;
  final double batterySoc;
  final String batteryStatus;
  final double batteryVol;
  final bool gridStatusRealTimeOnLine;
  final bool gridStatusRealTimeSwitch;
  final Map<String, dynamic>? dataHome;
  final List<dynamic>? batteries;

  HistoryModel({
    required this.timestamp,
    required this.batterySoc,
    required this.batteryStatus,
    required this.batteryVol,
    required this.gridStatusRealTimeOnLine,
    required this.gridStatusRealTimeSwitch,
    this.dataHome,
    this.batteries,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      timestamp: json['timestamp'] ?? 0,
      batterySoc: (json['batterySoc'] ?? 0.0).toDouble(),
      batteryStatus: json['batteryStatus'] ?? '--',
      batteryVol: (json['batteryVol'] ?? 0.0).toDouble(),
      gridStatusRealTimeOnLine: json['gridStatusRealTimeOnLine'] ?? false,
      gridStatusRealTimeSwitch: json['gridStatusRealTimeSwitch'] ?? false,
      dataHome: json['dataHome'] as Map<String, dynamic>?,
      batteries: json['batteries'] as List<dynamic>?,
    );
  }

  String get timeOnly {
    if (timestamp == 0) return "--:--";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}