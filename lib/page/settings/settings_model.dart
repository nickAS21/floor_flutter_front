class SettingsModel {
  final bool devicesChangeHandleControl;
  final double? batteryCriticalNightSocWinter;
  final int? logsDachaLimit;

  SettingsModel({
    required this.devicesChangeHandleControl,
    this.batteryCriticalNightSocWinter,
    this.logsDachaLimit,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
      logsDachaLimit: json['logsDachaLimit']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'devicesChangeHandleControl': devicesChangeHandleControl,
    if (batteryCriticalNightSocWinter != null) 'batteryCriticalNightSocWinter': batteryCriticalNightSocWinter,
    if (logsDachaLimit != null) 'logsDachaLimit': logsDachaLimit,
  };
}
