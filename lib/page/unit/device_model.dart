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