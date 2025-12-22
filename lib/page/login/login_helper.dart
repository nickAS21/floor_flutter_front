import '../../locale/shared_preferences_helper.dart';

class LoginHelper {
  // Public constants for cross-file access
  static const String kUser = 'username';
  static const String kPass = 'password';
  static const String kEnv  = 'env';
  static const String kCustom = 'custom_api';

  // Saves data using SharedPreferencesHelper
  static Future<void> saveAuth(String user, String pass, String env, String custom) async {
    await SharedPreferencesHelper.saveValue(kUser, user);
    await SharedPreferencesHelper.saveValue(kPass, pass);
    await SharedPreferencesHelper.saveValue(kEnv, env);
    await SharedPreferencesHelper.saveValue(kCustom, custom);
  }

  // Returns map with constants as keys for type safety
  static Future<Map<String, String?>> getAuth() async {
    return {
      kUser: await SharedPreferencesHelper.getValue(kUser),
      kPass: await SharedPreferencesHelper.getValue(kPass),
      kEnv:  await SharedPreferencesHelper.getValue(kEnv),
      kCustom: await SharedPreferencesHelper.getValue(kCustom),
    };
  }
}