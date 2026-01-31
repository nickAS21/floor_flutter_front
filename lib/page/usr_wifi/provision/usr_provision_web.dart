import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:url_launcher/url_launcher.dart';

class UsrProvisionWeb implements UsrProvisionBase {
  @override
  String getHint() => "Web/Linux: Перевірте підключення до USR-WIFI. Налаштування відбудеться через браузер (admin/admin).";

  @override
  Future<List<Map<String, dynamic>>> scanNetworks() async {
    return [];
  }
}