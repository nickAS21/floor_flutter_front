class SettingsModel {
  // Константи ключів для усунення хардкоду
  static const String keyVersionBackend = 'versionBackend';
  static const String keyHandle = 'handleControl';
  static const String keyLogs = 'logsLimit';
  static const String keySoc = 'socLevel';
  static const String keyHeaterNightAuto = 'heaterNightAuto';

  // Мапа лейблів
  static Map<String, String> get fieldLabels => {
    keyVersionBackend: "Версія Backend",
    keyHandle: "Ручне керування пристроями",
    keyLogs: "Кількість рядків логів (App Limit)",
    keySoc: "Критичний рівень заряду (SoC %)",
    keyHeaterNightAuto: "Автоматичне включення підігріву полів першого поверху ніччю взимку",
  };

  final String versionBackend;
  final bool devicesChangeHandleControl;
  final int logsAppLimit;
  final double? batteryCriticalNightSocWinter;
  final bool? heaterNightAutoOnDachaWinter;

  SettingsModel({
    required this.versionBackend,
    required this.devicesChangeHandleControl,
    required this.logsAppLimit,
    this.batteryCriticalNightSocWinter,
    this.heaterNightAutoOnDachaWinter,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      versionBackend: json['versionBackend']?.toString() ?? "",
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      logsAppLimit: (json['logsAppLimit'] ?? json['logsDachaLimit'] ?? 100).toInt(),
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
      heaterNightAutoOnDachaWinter: json['heaterNightAutoOnDachaWinter'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'versionBackend': versionBackend,
    'devicesChangeHandleControl': devicesChangeHandleControl,
    'logsAppLimit': logsAppLimit,
    if (batteryCriticalNightSocWinter != null)
      'batteryCriticalNightSocWinter': batteryCriticalNightSocWinter,
    if (heaterNightAutoOnDachaWinter != null)
      'heaterNightAutoOnDachaWinter': heaterNightAutoOnDachaWinter,
  };
}