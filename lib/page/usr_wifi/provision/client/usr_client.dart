
abstract class UsrClient {
  String? mac;
  String? ssidName;
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