class BatteryInfoModel {
  final String timestamp;
  final int port;
  final double voltageCurV;
  final double currentCurA;
  final double socPercent;
  final double? bmsTempValue;
  final String bmsStatusStr;
  final String errorInfoDataHex;
  final String errorOutput;
  final bool isActive;
  final double deltaMv; // Тепер double, бо на беку ділимо на 1000.0 (V)
  final int minCellIdx;
  final int maxCellIdx;
  final Map<int, double> cellVoltagesV;

  BatteryInfoModel({
    required this.timestamp,
    required this.port,
    required this.voltageCurV,
    required this.currentCurA,
    required this.socPercent,
    this.bmsTempValue,
    required this.bmsStatusStr,
    required this.errorInfoDataHex,
    required this.errorOutput,
    required this.isActive,
    required this.deltaMv,
    required this.minCellIdx,
    required this.maxCellIdx,
    required this.cellVoltagesV,
  });

  factory BatteryInfoModel.fromJson(Map<String, dynamic> json) {
    // Парсимо мапу комірок: "1": 3.25 -> 1: 3.25
    var voltages = <int, double>{};
    if (json['cellVoltagesV'] != null) {
      (json['cellVoltagesV'] as Map<String, dynamic>).forEach((key, val) {
        voltages[int.parse(key)] = (val as num).toDouble();
      });
    }

    return BatteryInfoModel(
      timestamp: json['timestamp'] ?? '',
      port: json['port'] ?? 0,
      voltageCurV: (json['voltageCurV'] ?? 0.0).toDouble(),
      currentCurA: (json['currentCurA'] ?? 0.0).toDouble(),
      socPercent: (json['socPercent'] ?? 0.0).toDouble(),
      bmsTempValue: json['bmsTempValue'] != null ? (json['bmsTempValue'] as num).toDouble() : null,
      bmsStatusStr: json['bmsStatusStr'] ?? 'Unknown',
      errorInfoDataHex: json['errorInfoDataHex'] ?? '0x00',
      errorOutput: json['errorOutput'] ?? '',
      isActive: json['isActive'] ?? false,
      deltaMv: (json['deltaMv'] ?? 0.0).toDouble(),
      minCellIdx: json['minCellIdx'] ?? 0,
      maxCellIdx: json['maxCellIdx'] ?? 0,
      cellVoltagesV: voltages,
    );
  }
}
