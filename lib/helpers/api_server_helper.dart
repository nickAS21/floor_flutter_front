import 'api_server_type.dart';
import 'app_helper.dart';

class ApiServerHelper {
  static ApiServerType currentEnvironment = ApiServerType.localHostApi;
  static String customBackend = ''; // custom URL

  static String get backendUrl {
    switch (currentEnvironment) {
      case ApiServerType.localHostHome:
        return AppHelper.localBackendHostHome;
       case ApiServerType.localHostDacha:
        return AppHelper.localBackendHostDacha;
      case ApiServerType.localHostApi:
        return AppHelper.localBackendHost;
      case ApiServerType.localApiChrome:
        return AppHelper.localBackendChrome;
      case ApiServerType.localApiDevice:
        return AppHelper.localBackendDevice;
      case ApiServerType. localApiEmulator:
        return AppHelper.localBackendEmulator + AppHelper.apiPathLogin;
      case ApiServerType.kubernetesApi:
        return AppHelper.kubernetesBackend;
      case ApiServerType.customApi:
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
