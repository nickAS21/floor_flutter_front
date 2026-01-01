class SettingsModel {
  // Константи ключів для усунення хардкоду
  static const String keyVersionBackend = 'versionBackend';
  static const String keyHandle = 'handleControl';
  static const String keyLogs = 'logsLimit';
  static const String keySoc = 'socLevel';

  // Мапа лейблів
  static Map<String, String> get fieldLabels => {
    keyVersionBackend: "Версія Backend",
    keyHandle: "Ручне керування пристроями",
    keyLogs: "Кількість рядків логів (App Limit)",
    keySoc: "Критичний рівень заряду (SoC %)",
  };

  final String versionBackend;
  final bool devicesChangeHandleControl;
  final int logsAppLimit;
  final double? batteryCriticalNightSocWinter;

  SettingsModel({
    required this.versionBackend,
    required this.devicesChangeHandleControl,
    required this.logsAppLimit,
    this.batteryCriticalNightSocWinter,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      // Виправлено: версія — це String, тому значення за замовчуванням ""
      versionBackend: json['versionBackend']?.toString() ?? "",
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      logsAppLimit: (json['logsAppLimit'] ?? json['logsDachaLimit'] ?? 100).toInt(),
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'versionBackend': versionBackend,
    'devicesChangeHandleControl': devicesChangeHandleControl,
    'logsAppLimit': logsAppLimit,
    if (batteryCriticalNightSocWinter != null)
      'batteryCriticalNightSocWinter': batteryCriticalNightSocWinter,
  };
}