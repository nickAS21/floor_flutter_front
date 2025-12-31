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

  @override
  String get dailySolarPanel => 'Daily Solar';

  @override
  String get dailyBatteryCharge => 'Daily Battery Charge';

  @override
  String get dailyBatteryDischarge => 'Daily Battery Discharge';

  @override
  String get dailyGrid => 'Daily Grid';

  @override
  String get dailyLoad => 'Daily Load';

  @override
  String get aboutDialogTitle => 'Oasis: Solar & Smart Home Ecosystem';

  @override
  String get aboutDialogTitleDop => 'Technical Details:';

  @override
  String get aboutDialogMessage =>
      '• Smart control of solar inverter-based equipment\n• Seamless management for apartments and country houses\n• Real-time battery and power grid monitoring\n• Remote discharge depth adjustment (60%, 50%, etc.)\n• Advanced charge mode control (Auto/Manual)\n• Comprehensive system logs and error tracking';

  @override
  String get aboutDialogMessageSettingsBms =>
      'This application is optimized for GBL_2.45K3 batteries by GS Energy Storage (SYL Battery). Reliable operation requires configuration of the USR-WIFI232-B2/A2 Wi-Fi module.';

  @override
  String get versionInfo => 'Version: ';

  @override
  String get githubUrl => 'https://github.com/nickAS21/floor_flutter_front.git';

  @override
  String get githubUrlSettingsBms =>
      'https://github.com/nickAS21/BMSUSRProvision_Android';

  @override
  String get authorInfo => 'Author: ';

  @override
  String get author => 'Nick Kulikov (nickAS21)';

  @override
  String get gitHub => 'GitHub: ';
}
