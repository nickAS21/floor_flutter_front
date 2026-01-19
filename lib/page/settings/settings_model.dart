enum BatteryStatus {
  staticMode("Static", 98.00),
  charging60("Charging", 60.00),
  charging50("Charging", 50.00),
  discharging("Discharging", 40.00),
  alarm("Alarm", 30.00);

  final String label;
  final double value;
  const BatteryStatus(this.label, this.value);
}

class SettingsModel {
  static double get maxSoc => BatteryStatus.staticMode.value; // 98.0
  static double get minSoc => BatteryStatus.discharging.value; // 40.0
  static double get alarmSoc => BatteryStatus.alarm.value; // 30.0
  static const String keyVersionBackend = 'versionBackend';
  static const String keyHandle = 'handleControl';
  static const String keyLogs = 'logsLimit';
  static const String keySoc = 'socLevel';
  static const String keyHeaterNightAuto = 'heaterNightAuto';
  static const String keyHeaterGridOnAutoAllDay = 'heaterGridOnAutoAllDay';
  static const String keySeasonsId = 'seasonsId';

  static Map<String, String> get fieldLabels => {
    keyVersionBackend: "Версія Backend",
    keyHandle: "Ручне керування пристроями",
    keyLogs: "Кількість рядків логів (App Limit)",
    keySoc: "Критичний рівень заряду (SoC %)",
    keyHeaterNightAuto: "Авто-підігрів (Ніч/Зима)",
    keyHeaterGridOnAutoAllDay: "Підключення Grid(on) цілодобово",
    keySeasonsId: "Пора року",
  };

  final String versionBackend;
  final bool devicesChangeHandleControl;
  final int logsAppLimit;
  final double? batteryCriticalNightSocWinter;
  final bool? heaterNightAutoOnDachaWinter;
  final bool heaterGridOnAutoAllDay;
  final int? seasonsId;

  SettingsModel({
    required this.versionBackend,
    required this.devicesChangeHandleControl,
    required this.logsAppLimit,
    this.batteryCriticalNightSocWinter,
    this.heaterNightAutoOnDachaWinter,
    required this.heaterGridOnAutoAllDay,
    this.seasonsId,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      versionBackend: json['versionBackend']?.toString() ?? "",
      devicesChangeHandleControl: json['devicesChangeHandleControl'] ?? false,
      logsAppLimit: (json['logsAppLimit'] ?? json['logsDachaLimit'] ?? 100).toInt(),
      batteryCriticalNightSocWinter: json['batteryCriticalNightSocWinter']?.toDouble(),
      heaterNightAutoOnDachaWinter: json['heaterNightAutoOnDachaWinter'] ?? false,
      heaterGridOnAutoAllDay: json['heaterGridOnAutoAllDay'] ?? false,
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
    'heaterGridOnAutoAllDay': heaterGridOnAutoAllDay,
    if (seasonsId != null) 'seasonsId': seasonsId,
  };
}