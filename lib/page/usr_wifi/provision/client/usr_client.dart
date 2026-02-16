// lib/page/usr_wifi/provision/client/usr_client.dart
abstract class UsrClient {
  Future<String?> getMacAddress();
  Future<List<Map<String, dynamic>>> getScanResults();
  Future<String> postRestart();

  // Приймаємо готові значення з полів
  Future<void> onSaveUpdate({
    required String targetSsid,
    required String targetPass,
    required String moduleSsid,
    required String ipA,
    required int portA,
    required String ipB,
    required int portB,
    required int bitrate,
  });
}