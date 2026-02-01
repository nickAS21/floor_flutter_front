import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'http/usr_http_client_helper.dart';

class UsrProvisionUtils {

  static const String openHttpOn254 = "ВІДКРИТИ 10.10.100.254";
  static const String provisionHint = "Mobile: Перевірте підключення до точки доступу USR-WIFI";

  static Future<void> openDeviceWeb() async {
    final url = Uri.parse("http://${UsrHttpClientHelper.baseHttpLogin}:${UsrHttpClientHelper.baseHttpPwd}@${UsrHttpClientHelper.baseIpAtHttp}");

    if (kIsWeb) {
      // Якщо запущено в Chrome (Web) — відкриваємо нову вкладку
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else if (Platform.isLinux) {
      // Якщо запущено як Linux-додаток — запускаємо Chrome окремим процесом
      Process.run('google-chrome', [url.toString()]);
    }
  }
}