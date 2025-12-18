enum Environment { localHostApi, localApiChrome, localApiDevice, localApiEmulator, kubernetesApi, customApi }

class AppConfig {
  static const String localBackendHost = 'http://localhost:8084';
  static const String localBackendChrome = 'http://127.0.0.1:8084';
  static const String localBackendEmulator = 'http://10.0.2.2:8084'; // Emulator
  static const String localBackendDevice = 'http://192.168.251.92:8084'; //  Device
  static const String kubernetesBackend = 'https://tuya.k8s.solk.pl';
  static const String apiPathLogin = '/api/auth/login';
  static const String apiPathApi = '/api';
  static const String apiPathHome = '$apiPathApi/home';
  static const String apiPathTuya = '$apiPathApi/tuya';
  static const String apiPathSmart = '${apiPathApi}/smart';
  static const String pathGolego = '/golego';
  static const String pathDacha = '/dacha';
  static const String pathConfig = '/config';
  static const String pathDevice = '/device';
  static const String pathLogs = '/logs';
  static const int refreshIntervalMinutes = 4;

  // static const String localBackendHost = 'http://192.168.8.141:8084';

  static String currentBackend = localBackendHost; // Default value

  static void setBackend(String backend) {
    currentBackend = backend;
  }
}

class EnvironmentConfig {
  static Environment currentEnvironment = Environment.localHostApi;
  static String customBackend = ''; // custom URL

  static String get backendUrl {
    switch (currentEnvironment) {
      case Environment.localHostApi:
        return AppConfig.localBackendHost;
      case Environment.localApiChrome:
        return AppConfig.localBackendChrome;
      case Environment.localApiDevice:
        return AppConfig.localBackendDevice;
      case Environment. localApiEmulator:
        return AppConfig.localBackendEmulator + AppConfig.apiPathLogin;
      case Environment.kubernetesApi:
        return AppConfig.kubernetesBackend;
      case Environment.customApi:
        if (customBackend.startsWith('http://') ||
            customBackend.startsWith('https://')) {
          return customBackend;
        } else {
          throw Exception(
              "Invalid custom backend URL. Must start with http:// or https://");
        }
      }
  }
}
