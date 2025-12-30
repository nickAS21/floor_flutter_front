import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart' deferred as app_localizations_en;
import 'app_localizations_uk.dart' deferred as app_localizations_uk;

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk')
  ];

  /// No description provided for @apiError.
  ///
  /// In en, this message translates to:
  /// **'API: {apiUrl} - no internet connection'**
  String apiError(Object apiUrl);

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'API: {apiUrl} - invalid server response'**
  String serverError(Object apiUrl);

  /// No description provided for @formatError.
  ///
  /// In en, this message translates to:
  /// **'API: {apiUrl} - invalid response format'**
  String formatError(Object apiUrl);

  /// No description provided for @credentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Credentials'**
  String get credentialsError;

  /// No description provided for @titleRegLogin.
  ///
  /// In en, this message translates to:
  /// **'Registration and Login'**
  String get titleRegLogin;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterCustomAPI.
  ///
  /// In en, this message translates to:
  /// **'Enter custom API (optional)'**
  String get enterCustomAPI;

  /// No description provided for @windowSize.
  ///
  /// In en, this message translates to:
  /// **'Window is'**
  String get windowSize;

  /// No description provided for @solarPanel.
  ///
  /// In en, this message translates to:
  /// **'Solar Panels'**
  String get solarPanel;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @dailySolarPanel.
  ///
  /// In en, this message translates to:
  /// **'Daily Solar'**
  String get dailySolarPanel;

  /// No description provided for @dailyBatteryCharge.
  ///
  /// In en, this message translates to:
  /// **'Daily Battery Charge'**
  String get dailyBatteryCharge;

  /// No description provided for @dailyBatteryDischarge.
  ///
  /// In en, this message translates to:
  /// **'Daily Battery Discharge'**
  String get dailyBatteryDischarge;

  /// No description provided for @dailyGrid.
  ///
  /// In en, this message translates to:
  /// **'Daily Grid'**
  String get dailyGrid;

  /// No description provided for @dailyLoad.
  ///
  /// In en, this message translates to:
  /// **'Daily Load'**
  String get dailyLoad;

  /// No description provided for @aboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About program\nOasis: Solar & Smart Home Ecosystem'**
  String get aboutDialogTitle;

  /// No description provided for @aboutDialogTitleDop.
  ///
  /// In en, this message translates to:
  /// **'Additional information:'**
  String get aboutDialogTitleDop;

  /// No description provided for @aboutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'• Equipment control based on solar inverters\n• Management in an apartment and a country house\n• Monitoring battery status and power grid\n• Remote discharge adjustment (60%, 50%, etc.)\n• Charge mode control (auto/manual)\n• System log viewing and error tracking'**
  String get aboutDialogMessage;

  /// No description provided for @aboutDialogMessageSettingsBms.
  ///
  /// In en, this message translates to:
  /// **'This application is designed for use with the GBL_2.45K3 battery from GS Energy Storage (SYL Battery), which must be configured through the Wi-Fi parameters of the USR-WIFI232-B2/A2 module.'**
  String get aboutDialogMessageSettingsBms;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version: '**
  String get versionInfo;

  /// No description provided for @githubUrl.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/nickAS21/floor_flutter_front.git'**
  String get githubUrl;

  /// No description provided for @githubUrlSettingsBms.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/nickAS21/BMSUSRProvision_Android'**
  String get githubUrlSettingsBms;

  /// No description provided for @authorInfo.
  ///
  /// In en, this message translates to:
  /// **'Author: '**
  String get authorInfo;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Nick Kulikov (nickAS21)'**
  String get author;

  /// No description provided for @gitHub.
  ///
  /// In en, this message translates to:
  /// **'GitHub: '**
  String get gitHub;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return lookupAppLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

Future<AppLocalizations> lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return app_localizations_en
          .loadLibrary()
          .then((dynamic _) => app_localizations_en.AppLocalizationsEn());
    case 'uk':
      return app_localizations_uk
          .loadLibrary()
          .then((dynamic _) => app_localizations_uk.AppLocalizationsUk());
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
