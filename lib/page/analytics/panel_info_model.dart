class PanelInfoModel {
  final int timeStamp;
  final int pvIndex;
  final String parallelInfo;
  final double pvVoltageCurV;
  final double pvCurrentCurA;
  final double pvPowerCurW;
  final String vendor;
  final String modelName;
  final int panelsCount;

  PanelInfoModel({
    required this.timeStamp,
    required this.pvIndex,
    required this.parallelInfo,
    required this.pvVoltageCurV,
    required this.pvCurrentCurA,
    required this.pvPowerCurW,
    required this.vendor,
    required this.modelName,
    required this.panelsCount,
  });

  factory PanelInfoModel.fromJson(Map<String, dynamic> json) {
    return PanelInfoModel(
      timeStamp: json['timeStamp'] ?? 0,
      pvIndex: json['pvIndex'] ?? 0,
      parallelInfo: json['parallelInfo'] ?? '',
      pvVoltageCurV: (json['pvVoltageCurV'] ?? 0.0).toDouble(),
      pvCurrentCurA: (json['pvCurrentCurA'] ?? 0.0).toDouble(),
      pvPowerCurW: (json['pvPowerCurW'] ?? 0.0).toDouble(),
      vendor: json['vendor'] ?? '',
      modelName: json['modelName'] ?? '',
      panelsCount: json['panelsCount'] ?? 0,
    );
  }

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

    dynamic rawPanels = json['panels'];

    if (rawPanels is Map<String, dynamic>) {
      rawPanels.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          panelsMap[key] = PanelInfoModel.fromJson(val);
        }
      });
    } else {
      json.forEach((key, val) {
        if (key != 'timestamp' && val is Map<String, dynamic>) {
          panelsMap[key] = PanelInfoModel.fromJson(val);
        }
      });
    }

    return PanelInfoModels(
      timestamp: json['timestamp'] ?? '',
      panels: panelsMap,
    );
  }
}