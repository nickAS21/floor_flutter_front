class SettingsModel {
  // Константи ключів для усунення хардкоду
  static const String keyHandle = 'handleControl';
  static const String keyLogs = 'logsLimit';
  static const String keySoc = 'socLevel';

  // Мапа лейблів (звідси будемо брати назви для UI та помилок)
  static Map<String, String> get fieldLabels => {
    keyHandle: "Ручне керування пристроями",
    keyLogs: "Кількість рядків логів (App Limit)",
    keySoc: "Критичний рівень заряду (SoC %)",
  };

  final bool devicesChangeHandleControl;
  final int logsAppLimit;
  final double? batteryCriticalNightSocWinter;

  SettingsModel({
    required this.devicesChangeHandleControl,
    required this.logsAppLimit,
    this.batteryCriticalNightSocWinter,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      logsAppLimit: (json['logsAppLimit'] ?? json['logsDachaLimit'] ?? 100).toInt(),
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'devicesChangeHandleControl': devicesChangeHandleControl,
    'logsAppLimit': logsAppLimit,
    if (batteryCriticalNightSocWinter != null)
      'batteryCriticalNightSocWinter': batteryCriticalNightSocWinter,
  };
}