// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String apiError(Object apiUrl) {
    return 'API: $apiUrl - немає підключення до інтернету';
  }

  @override
  String serverError(Object apiUrl) {
    return 'API: $apiUrl - помилка відповіді від сервера';
  }

  @override
  String formatError(Object apiUrl) {
    return 'API: $apiUrl - помилка в форматі запиту';
  }

  @override
  String get credentialsError => 'Недійсні облікові дані';

  @override
  String get titleRegLogin => 'Реєстрація та вхід';

  @override
  String get signIn => 'Увійти';

  @override
  String get username => 'Ім`я користувача';

  @override
  String get password => 'Пароль';

  @override
  String get enterCustomAPI => 'Введіть API користувача (необов`язково)';

  @override
  String get windowSize => 'Розмір вікна';

  @override
  String get solarPanel => 'Сонячні Панелі';

  @override
  String get battery => 'Батарея';

  @override
  String get grid => 'Електромережи';

  @override
  String get load => 'Споживання';

  @override
  String get dailySolarPanel => 'Щоденне Сонячні Панелі';

  @override
  String get dailyBatteryCharge => 'Щоденний Заряд Батареї';

  @override
  String get dailyBatteryDischarge => 'Щоденний Розаряд Батареї';

  @override
  String get dailyGrid => 'Щоденне від Електромережи';

  @override
  String get dailyLoad => 'Щоденне Споживання';

  @override
  String get aboutDialogTitle =>
      'Oasis: Екосистема сонячної енергії та розумного дому';

  @override
  String get aboutDialogTitleDop => 'Додаткова інформація:';

  @override
  String get aboutDialogMessage =>
      '• Інтелектуальне керування обладнанням на базі сонячних інверторів\n• Єдиний інтерфейс для керування квартирою та заміським будинком\n• Моніторинг стану акумуляторів та електромережі в реальному часі\n• Дистанційне налаштування глибини розряду (60%, 50% тощо)\n• Керування режимами зарядки (Автоматичний/Ручний)\n• Перегляд системних журналів та відстеження помилок';

  @override
  String get aboutDialogMessageSettingsBms =>
      'Цей застосунок оптимізовано для роботи з акумуляторами GBL_2.45K3 від GS Energy Storage (SYL Battery). Для коректної роботи необхідна конфігурація Wi-Fi модуля USR-WIFI232-B2/A2.';

  @override
  String get versionInfo => 'Версія: ';

  @override
  String get githubUrl => 'https://github.com/nickAS21/floor_flutter_front.git';

  @override
  String get githubUrlSettingsBms =>
      'https://github.com/nickAS21/BMSUSRProvision_Android';

  @override
  String get authorInfo => 'Автор: ';

  @override
  String get author => 'Nick Kulikov (nickAS21)';

  @override
  String get gitHub => 'GitHub: ';
}
