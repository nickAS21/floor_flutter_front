import 'package:floor_front/locale/SharedPreferencesHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LocaleHelper {

  static const String localeKey = "locale";
  static Locale? locale;

  static Future<Locale?> getValueInit() async {
    List<String>? savedLocaleList = await SharedPreferencesHelper.getValueList(localeKey);
    locale = WidgetsBinding.instance.platformDispatcher.locale;
    if (savedLocaleList.isNotEmpty) {
      return Locale(savedLocaleList.first, savedLocaleList.length > 1 ? savedLocaleList.last : '');
    } else if (locale != null){
      await SharedPreferencesHelper.saveValueList(localeKey, [locale!.languageCode, locale!.countryCode ?? '']);
      return locale;
    } else {
      return null;
    }
  }
}