import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'client/http/usr_wifi_232_http_client_helper.dart';

class UsrProvisionUtils {

  static const String openHttpOn254 = "ВІДКРИТИ 10.10.100.254";
  static const String provisionHint = "Перевірте підключення до Device в режимі AP: USR-WIFI-XX-XXXX";

  static Future<void> openDeviceWeb() async {
    final url = Uri.parse("http://${UsrWiFi232HttpClientHelper.baseHttpLogin}:${UsrWiFi232HttpClientHelper.baseHttpPwd}@${UsrWiFi232HttpClientHelper.baseIpAtHttpWiFi232}");

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