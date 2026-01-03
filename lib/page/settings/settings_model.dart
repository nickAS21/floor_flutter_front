class SettingsModel {
  // Константи ключів для усунення хардкоду
  static const String keyVersionBackend = 'versionBackend';
  static const String keyHandle = 'handleControl';
  static const String keyLogs = 'logsLimit';
  static const String keySoc = 'socLevel';
  static const String keyHeaterNightAuto = 'heaterNightAuto';
  static const String keySeasonsId = 'seasonsId';

  // Мапа лейблів
  static Map<String, String> get fieldLabels => {
    keyVersionBackend: "Версія Backend",
    keyHandle: "Ручне керування пристроями",
    keyLogs: "Кількість рядків логів (App Limit)",
    keySoc: "Критичний рівень заряду (SoC %)",
    keyHeaterNightAuto: "Автоматичне включення підігріву полів першого поверху ніччю взимку",
    keySeasonsId: "Пора року",
  };

  final String versionBackend;
  final bool devicesChangeHandleControl;
  final int logsAppLimit;
  final double? batteryCriticalNightSocWinter;
  final bool? heaterNightAutoOnDachaWinter;
  final int? seasonsId;

  SettingsModel({
    required this.versionBackend,
    required this.devicesChangeHandleControl,
    required this.logsAppLimit,
    this.batteryCriticalNightSocWinter,
    this.heaterNightAutoOnDachaWinter,
    this.seasonsId,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      versionBackend: json['versionBackend']?.toString() ?? "",
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      logsAppLimit: (json['logsAppLimit'] ?? json['logsDachaLimit'] ?? 100).toInt(),
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
      heaterNightAutoOnDachaWinter: json['heaterNightAutoOnDachaWinter'] ?? false,
      seasonsId: json['seasonsId'] != null ? json['seasonsId'] as int : null,
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
    if (seasonsId != null) 'seasonsId': seasonsId,
  };
}