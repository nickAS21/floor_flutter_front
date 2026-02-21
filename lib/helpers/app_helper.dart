import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppHelper {
  static const String localBackendHost = 'http://localhost:8084';
  static const String backendHostHome = '192.168.8.102';
  static const String localBackendHostHome = 'http://$backendHostHome:8084';
  static const String backendHostDacha = '192.168.28.27';
  static const String localBackendHostDacha = 'http://$backendHostDacha:8084';
  static const String localBackendChrome = 'http://127.0.0.1:8084';
  static const String localBackendEmulator = 'http://10.0.2.2:8084'; // Emulator
  static const String localBackendDevice = 'http://192.168.251.92:8084'; //  Device
  static const String backendHostKubernet = '89.35.145.1';
  static const String kubernetesBackend = 'https://tuya.k8s.solk.pl';
  static const String apiPathLogin = '/api/auth/login';
  static const String apiPathApi = '/api';
  static const String apiPathHome = '$apiPathApi/home';
  static const String apiPathSettings = '$apiPathApi/settings';
  static const String apiPathLogs = '$apiPathApi/logs';
  static const String apiPathLogsDacha = '/actuator/logfile';
  static const String apiPathUnit = '$apiPathApi/unit';
  static const String apiPathHistory = '$apiPathApi/history';
  static const String apiPathAnalytics = '$apiPathApi/analytics';
  static const String apiPathAlarm = '$apiPathApi/alarm';
  static const String apiPathProvision = '$apiPathApi/provision';

  static const String apiPathTuya = '$apiPathApi/tuya';
  static const String apiPathSmart = '$apiPathApi/smart';
  static const String pathGolego = '/golego';
  static const String pathDacha = '/dacha';
 static const String pathToday = '/today';
  static const String pathYesterday = '/yesterday';
  static const String pathApp = '/app';
  static const String pathDevice = '/device';

  static const int refreshIntervalMinutes = 1;
  static const String pcTitle = "PC: Smart Home, Solarman and Tuya";
  static const String mobileTitle = "Oasis";
  static const String webTitle = "Web: Smart Home, Solarman and Tuya";
  static String _version = "0.0.0";
  static String get appVersion => _version;

  static String getTitleByPlatform() {
    if (kIsWeb) return webTitle;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return pcTitle;
    return mobileTitle;
  }

  static Future<void> initPackageInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
    } catch (e) {
      _version = "1.0.0"; // Значення за замовчуванням, якщо стався збій
    }
  }

  static Timer startRefreshTimer(void Function() callback) {
    return Timer.periodic(const Duration(minutes: 4), (timer) {
      callback();
    });
  }
}

extension StringExtensions on String? {
  /// Analog Java String.isBlank()
  bool get isBlank => this == null || this!.trim().isEmpty;
  bool get isNotBlank => !isBlank;
}
