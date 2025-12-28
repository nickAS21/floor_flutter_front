class SettingsModel {
  final bool devicesChangeHandleControl;
  final double? batteryCriticalNightSocWinter;

  SettingsModel({
    required this.devicesChangeHandleControl,
    this.batteryCriticalNightSocWinter,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'devicesChangeHandleControl': devicesChangeHandleControl,
    if (batteryCriticalNightSocWinter != null)
      'batteryCriticalNightSocWinter': batteryCriticalNightSocWinter,
  };
}
