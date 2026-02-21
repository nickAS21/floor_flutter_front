
enum UsrClientDeviceType {
  b2("USR-WIFI232-B2_", "WIFI232-B2"),
  a2("USR-WIFI232-A2_", "WIFI232-A2"),
  s100("USR-S100-", "S100");

  final String prefix; // Для SSID модуля
  final String label;  // Для відображення в UI

  const UsrClientDeviceType(this.prefix, this.label);

  static UsrClientDeviceType fromClient(dynamic client) {
    final String typeName = client.runtimeType.toString().toUpperCase();
    if (typeName.contains('S100')) return UsrClientDeviceType.s100;
    if (typeName.contains('A2')) return UsrClientDeviceType.a2;
    return UsrClientDeviceType.b2; // Дефолт
  }
}