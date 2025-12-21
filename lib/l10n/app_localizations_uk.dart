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
}
