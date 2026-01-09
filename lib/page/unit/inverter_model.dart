import 'inverter_info_model.dart';

class InverterModel {
  final String? timestamp;
  final int? port;
  final String? connectionStatus;
  final InverterInfoModel? inverterInfo;

  InverterModel({
    this.timestamp,
    this.port,
    this.connectionStatus,
    this.inverterInfo,
  });

  factory InverterModel.fromJson(Map<String, dynamic> json) {
    return InverterModel(
      timestamp: json['timestamp'],
      port: json['port'],
      connectionStatus: json['connectionStatus'],
      inverterInfo: json['inverterInfo'] != null
          ? InverterInfoModel.fromJson(json['inverterInfo'])
          : null,
    );
  }

  bool get isOnline => connectionStatus?.toLowerCase() == 'online';
}