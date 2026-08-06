class PanelInfoModel {
  final int timeStamp;
  final int pvIndex;
  final String parallelInfo;
  final double pvVoltageCurV;
  final double pvCurrentCurA;
  final double pvPowerCurW;

  PanelInfoModel({
    required this.timeStamp,
    required this.pvIndex,
    required this.parallelInfo,
    required this.pvVoltageCurV,
    required this.pvCurrentCurA,
    required this.pvPowerCurW,
  });

  factory PanelInfoModel.fromJson(Map<String, dynamic> json) {
    return PanelInfoModel(
      timeStamp: json['timeStamp'] ?? 0,
      pvIndex: json['pvIndex'] ?? 0,
      parallelInfo: json['parallelInfo'] ?? '',
      pvVoltageCurV: (json['pvVoltageCurV'] ?? 0.0).toDouble(),
      pvCurrentCurA: (json['pvCurrentCurA'] ?? 0.0).toDouble(),
      pvPowerCurW: (json['pvPowerCurW'] ?? 0.0).toDouble(),
    );
  }

  // Унікальний ключ для зручності за аналогією з getPvKey() на бенеці
  String get pvKey => '${parallelInfo}_PV$pvIndex';
}

class PanelInfoModels {
  final String timestamp;
  final Map<String, PanelInfoModel> panels;

  PanelInfoModels({
    required this.timestamp,
    required this.panels,
  });

  factory PanelInfoModels.fromJson(Map<String, dynamic> json) {
    var panelsMap = <String, PanelInfoModel>{};
    if (json['panels'] != null && json['panels'] is Map) {
      (json['panels'] as Map<String, dynamic>).forEach((key, val) {
        if (val != null) {
          panelsMap[key] = PanelInfoModel.fromJson(val as Map<String, dynamic>);
        }
      });
    }

    return PanelInfoModels(
      timestamp: json['timestamp'] ?? '',
      panels: panelsMap,
    );
  }
}