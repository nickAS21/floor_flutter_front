import 'client/usr_client.dart';
import 'client/usr_client_helper.dart';

abstract class UsrProvisionBase {
  // Реалізація за замовчуванням для всіх нащадків
  String getHint() => UsrClientHelper.provisionHint;

  /// Сканування мереж
  Future<List<Map<String, dynamic>>> scanNetworks(String? ssid, UsrClient usrClient);

  Future<String?> getActiveSsid();
}