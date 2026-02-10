class HistoryModel {
  final int timestamp;
  final double batterySoc;
  final String batteryStatus;
  final double batteryVol;
  final double batteryCurrent;
  final bool gridStatusRealTimeOnLine;
  final bool gridStatusRealTimeSwitch;
  final int inverterPort;
  final String inverterPortConnectionStatus;
  final Map<String, dynamic>? dataHome;
  final List<dynamic>? batteries;

  HistoryModel({
    required this.timestamp,
    required this.batterySoc,
    required this.batteryStatus,
    required this.batteryVol,
    required this.batteryCurrent,
    required this.gridStatusRealTimeOnLine,
    required this.gridStatusRealTimeSwitch,
    required this.inverterPort,
    required this.inverterPortConnectionStatus,
    this.dataHome,
    this.batteries,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      timestamp: json['timestamp'] ?? 0,
      batterySoc: (json['batterySoc'] ?? 0.0).toDouble(),
      batteryStatus: json['batteryStatus'] ?? '--',
      batteryVol: (json['batteryVol'] ?? 0.0).toDouble(),
      batteryCurrent: (json['batteryCurrent'] ?? 0.0).toDouble(),
      gridStatusRealTimeOnLine: json['gridStatusRealTimeOnLine'] ?? false,
      gridStatusRealTimeSwitch: json['gridStatusRealTimeSwitch'] ?? false,
      inverterPort: json['inverterPort'] ?? 0,
      inverterPortConnectionStatus: json['inverterPortConnectionStatus'] ?? '--',
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