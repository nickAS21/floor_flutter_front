
import 'dart:convert';
import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/client/usr_client_device_type.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UsrClientHelper {
  // Використовуємо Enum для всіх налаштувань
  static List<UsrClientDeviceType> get devices => UsrClientDeviceType.values;

  // const ports
  static const int netPortADef = 18890;
  static const int netPortBDef = 8890;

  // main for connect
  static const String baseIpAtHttpWiFi232 = "10.10.100.254";
  static const String baseUrlHttpWiFi232 = "http://$baseIpAtHttpWiFi232";
  static const String baseIpAtHttpS100 = "192.168.1.1";
  static const String baseUrlHttpS100 = "http://$baseIpAtHttpS100";
  static const String baseHttpLogin = "admin";
  static const String baseHttpPwd = "admin";
  static String get authBasicHeader {
    final credentials = '$baseHttpLogin:$baseHttpPwd';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  static const String openHttp232On10_10_100_254 = "ВІДКРИТИ ${UsrClientHelper.baseIpAtHttpWiFi232} (WiFi232)";
  static const String openHttpS100On168_8_1_1 = "ВІДКРИТИ ${UsrClientHelper.baseIpAtHttpS100} (S100)";
  static const String provisionHint = "Відсутній коннект Device в режимі AP: USR-...";

  static Future<void> openDeviceWeb({bool isS100 = false}) async {
    final String host = isS100
        ? UsrClientHelper.baseIpAtHttpS100
        : UsrClientHelper.baseIpAtHttpWiFi232;

    // Формуємо URL: http://admin:admin@host
    final url = Uri.parse("http://${UsrClientHelper.baseHttpLogin}:${UsrClientHelper.baseHttpPwd}@$host");

    if (kIsWeb) {
      if (await canLaunchUrl(url)) await launchUrl(url);
    } else if (Platform.isLinux) {
      // Для Linux запускаємо Chrome безпосередньо
      Process.run('google-chrome', [url.toString()]);
    }
  }


  static void openModuleInChrome() {
    if (kIsWeb) return;

    // Формуємо URL виду http://admin:admin@10.10.100.254
    final String authUrl = "http://$baseHttpLogin:$baseHttpPwd@$baseIpAtHttpWiFi232"; //

    if (Platform.isLinux) {
      // Запускаємо Chrome з URL, що вже містить логін/пароль
      Process.run('google-chrome', [authUrl]).catchError((_) {
        return Process.run('chromium-browser', [authUrl]);
      });
    }
  }
}