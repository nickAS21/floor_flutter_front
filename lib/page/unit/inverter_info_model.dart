class InverterInfoModel {
  final String productName;
  final String manufacturer;
  final String modelName;
  final double ratedPower;
  final String commissioningDate;
  final String phaseType;
  final bool isHybrid;
  final String mpptControllerName;
  final int inputVoltage;
  final String zoneId; // <--- ТУТ ТВОЯ ЗОНА

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
    required this.zoneId,
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
      zoneId: json['zoneId'] ?? 'Europe/Kyiv', // По дефолту Київ, а не UTC!
    );
  }
}