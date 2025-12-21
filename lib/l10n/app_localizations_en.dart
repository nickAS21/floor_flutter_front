// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String apiError(Object apiUrl) {
    return 'API: $apiUrl - no internet connection';
  }

  @override
  String serverError(Object apiUrl) {
    return 'API: $apiUrl - invalid server response';
  }

  @override
  String formatError(Object apiUrl) {
    return 'API: $apiUrl - invalid response format';
  }

  @override
  String get credentialsError => 'Invalid Credentials';

  @override
  String get titleRegLogin => 'Registration and Login';

  @override
  String get signIn => 'Sign In';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get enterCustomAPI => 'Enter custom API (optional)';

  @override
  String get windowSize => 'Window is';

  @override
  String get solarPanel => 'Solar Panels';

  @override
  String get battery => 'Battery';

  @override
  String get grid => 'Grid';

  @override
  String get load => 'Load';
}
