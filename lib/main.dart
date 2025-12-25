import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'helpers/app_helper.dart';
import 'l10n/app_localizations.dart';
import 'helpers/locale_helper.dart';
import 'locale/shared_preferences_helper.dart';
import 'page/login/login_page.dart';
import 'locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppHelper.initPackageInfo();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized(); // Перенесено сюди

    WindowOptions windowOptions = WindowOptions(
      title: AppHelper.getTitleByPlatform(),
      center: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Locale? locale = await LocaleHelper.getValueInit();
  runApp(MyApp(initialLocale: locale));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;

  const MyApp({super.key, this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    SharedPreferencesHelper.saveValueList(LocaleHelper.localeKey, [locale.languageCode, locale.countryCode ?? '']);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      changeLocale: _setLocale,
      child: Builder(
        builder: (context) {
          final localeState = LocaleProvider.of(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeState?.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Web Smart Dacha, Solarman and Tuya',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: LoginPage(),
          );
        },
      ),
    );
  }
}
