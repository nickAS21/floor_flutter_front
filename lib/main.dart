import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'locale/LacaleHelper.dart';
import 'locale/SharedPreferencesHelper.dart';
import 'page/login_page.dart';
import 'locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Locale? locale = await LocaleHelper.getValueInit();
  runApp(MyApp(initialLocale: locale));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;

  MyApp({this.initialLocale});

  @override
  _MyAppState createState() => _MyAppState();
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
