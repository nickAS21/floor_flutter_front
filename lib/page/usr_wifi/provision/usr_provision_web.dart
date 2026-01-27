import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:url_launcher/url_launcher.dart';

class UsrProvisionWeb implements UsrProvisionBase {
  @override
  String getHint() => "Web/Linux: Перевірте підключення до USR-WIFI. Налаштування відбудеться через браузер (admin/admin).";

  @override
  Future<List<Map<String, dynamic>>> scanNetworks() async {
    return [];
  }

  @override
  Future<String> saveAndRestart(String urlString, String pwd) async {
    // Тепер ми використовуємо urlString, який передали з TextField
    final Uri? url = Uri.tryParse(urlString);

    if (url == null) return "invalid_url";

    try {
      // Відкриваємо URL у зовнішньому браузері
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return "opened_in_browser";
      } else {
        return "could_not_launch";
      }
    } catch (e) {
      return "error_launching: $e";
    }
  }
}