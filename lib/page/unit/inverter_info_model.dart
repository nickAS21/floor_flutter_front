class InverterInfoModel {
  final String productName;
  final String manufacturer;
  final String modelName;
  final double ratedPower;
  final String commissioningDate; // Приходить як відформатована String
  final String phaseType;        // Приходить як "One Phase" / "Three Phase"
  final bool isHybrid;
  final String mpptControllerName;
  final int inputVoltage;

  InverterInfoModel({
    required this.productName,
    required this.manufacturer,
    required this.modelName,
    required this.ratedPower,
    required this.commissioningDate,
    required this.phaseType,
    required this.isHybrid,
    required this.mpptControllerName,
    required this.inputVoltage,
  });

  factory InverterInfoModel.fromJson(Map<String, dynamic> json) {
    return InverterInfoModel(
      productName: json['productName'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      modelName: json['modelName'] ?? '',
      ratedPower: (json['ratedPower'] as num?)?.toDouble() ?? 0.0,
      commissioningDate: json['commissioningDate'] ?? '',
      phaseType: json['phaseType'] ?? '',
      isHybrid: json['isHybrid'] ?? false,
      mpptControllerName: json['mpptControllerName'] ?? '',
      inputVoltage: json['inputVoltage'] ?? 0,
    );
  }
}