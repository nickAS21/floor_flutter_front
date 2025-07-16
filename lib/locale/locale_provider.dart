import 'package:flutter/material.dart';

class LocaleProvider extends InheritedWidget {
  final Locale? locale;
  final Function(Locale) changeLocale;

  const LocaleProvider({
    super.key,
    required this.locale,
    required this.changeLocale,
    required super.child,
  });

  static LocaleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) {
    return oldWidget.locale != locale;
  }
}
