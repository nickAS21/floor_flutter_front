import 'battery_info_model.dart';

class UnitModel {
  final List<BatteryInfoModel> batteries;
  final List<DeviceModel> devices;

  UnitModel({required this.batteries, required this.devices});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      batteries: (json['batteries'] as List? ?? [])
          .map((e) => BatteryInfoModel.fromJson(e))
          .toList(),
      devices: (json['devices'] as List? ?? [])
          .map((e) => DeviceModel.fromJson(e))
          .toList(),
    );
  }
}

// DeviceModel залишається без змін, як ми узгоджували раніше
class DeviceModel {
  final String name;
  final String type;
  final bool isOnline;
  final bool isOn;
  final double? currentValue;
  final double? settingValue;

  DeviceModel({
    required this.name,
    required this.type,
    required this.isOnline,
    required this.isOn,
    this.currentValue,
    this.settingValue,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      name: json['name'] ?? '',
      type: json['type'] ?? 'other',
      isOnline: json['isOnline'] ?? false,
      isOn: json['isOn'] ?? false,
      currentValue: (json['currentValue'] as num?)?.toDouble(),
      settingValue: (json['settingValue'] as num?)?.toDouble(),
    );
  }
}