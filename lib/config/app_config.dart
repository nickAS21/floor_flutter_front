enum Environment { localApi, kubernetesApi, customApi }

class AppConfig {
  static const String localBackend = 'http://localhost:8084';
  static const String kubernetesBackend = 'https://your-kubernetes-endpoint.com';
  static const String apiPath = '/api/auth/login';

  static String currentBackend = localBackend; // Default value

  static void setBackend(String backend) {
    currentBackend = backend;
  }
}

class EnvironmentConfig {
  static Environment currentEnvironment = Environment.localApi;
  static String customBackend = ''; // custom URL

  static String get backendUrl {
    switch (currentEnvironment) {
      case Environment.localApi:
        return AppConfig.localBackend + AppConfig.apiPath;
      case Environment.kubernetesApi:
        return AppConfig.kubernetesBackend + AppConfig.apiPath;
      case Environment.customApi:
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

