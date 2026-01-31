// usr_provision_base.dart
abstract class UsrProvisionBase {
  /// Підказка для користувача перед початком
  String getHint() => "Перевірте підключення до Device в режимі AP: USR-WIFI-XX-XXXX";

  /// Сканування мереж
  Future<List<Map<String, dynamic>>> scanNetworks();
}