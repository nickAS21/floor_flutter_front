import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page/login_page.dart';
import 'locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? localeCode = prefs.getString('locale');
  Locale? locale = localeCode == null || localeCode.isEmpty ? null :
                  (localeCode.replaceAll('uk', '')).isEmpty ? Locale('uk', 'UA') :
                  (localeCode.replaceAll('en', '')).isEmpty ? Locale('uk', 'UA') : null;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      // locale: null,
      changeLocale: _setLocale,
      child: Builder(
        builder: (context) {
          final localeState = LocaleProvider.of(context);
          return MaterialApp(
            locale: localeState?.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'My App',
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
