import '../analytics/panel_info_model.dart';
import 'battery_info_model.dart';
import 'device_model.dart';
import 'inverter_model.dart';

class UnitModel {
  final InverterModel? inverter;
  final List<BatteryInfoModel> batteries;
  final PanelInfoModels? panelInfos;
  final List<DeviceModel> devices;

  UnitModel({
    this.inverter,
    required this.batteries,
    this.panelInfos,
    required this.devices,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      inverter: json['inverter'] != null
          ? InverterModel.fromJson(json['inverter'])
          : null,
      batteries: (json['batteries'] as List? ?? [])
          .map((e) => BatteryInfoModel.fromJson(e))
          .toList(),
      panelInfos: json['panelInfoDtos'] != null
          ? PanelInfoModels.fromJson(json['panelInfoDtos'])
          : null,
      devices: (json['devices'] as List? ?? [])
          .map((e) => DeviceModel.fromJson(e))
          .toList(),
    );
  }
}
