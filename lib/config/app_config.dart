enum Environment { local, aws, custom }

class AppConfig {
  static const String localBackend = 'http://localhost:8084';
  static const String awsBackend = 'https://your-aws-endpoint.amazonaws.com';
  static const String apiPath = '/api/auth/login';

  static String currentBackend = localBackend; // Значення за замовчуванням

  static void setBackend(String backend) {
    currentBackend = backend;
  }
}

class EnvironmentConfig {
  static Environment currentEnvironment = Environment.local;
  static String customBackend = ''; // Кастомний URL

  static String get backendUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return AppConfig.localBackend + AppConfig.apiPath;
      case Environment.aws:
        return AppConfig.awsBackend + AppConfig.apiPath;
      case Environment.custom:
        if (customBackend.startsWith('http://') || customBackend.startsWith('https://')) {
          return customBackend + AppConfig.apiPath;
        } else {
          throw Exception("Invalid custom backend URL. Must start with http:// or https://");
        }
      default:
        return AppConfig.localBackend + AppConfig.apiPath;
    }
  }
}

