// usr_provision_base.dart
import 'package:floor_front/page/usr_wifi/provision/usr_provision_utils.dart';

abstract class UsrProvisionBase {
  // Реалізація за замовчуванням для всіх нащадків
  String getHint() => UsrProvisionUtils.provisionHint;

  /// Сканування мереж
  Future<List<Map<String, dynamic>>> scanNetworks(String? mac);
}