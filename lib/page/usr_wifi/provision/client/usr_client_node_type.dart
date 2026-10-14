enum UsrClientNodeType {
  a2("USR-WIFI232-A2_", "WIFI232-A2", isBleSupported: false),
  b2("USR-WIFI232-B2_", "WIFI232-B2", isBleSupported: false),
  s100("USR-S100-", "S100", isBleSupported: false),
  esp("ESP-", "ESP", isBleSupported: true),
  bl602("BL602-", "BL602", isBleSupported: true);

  final String prefix;
  final String label;
  final bool isBleSupported; // Явний прапорець підтримки BLE BMS

  const UsrClientNodeType(
      this.prefix,
      this.label, {
        this.isBleSupported = false,
      });

  static UsrClientNodeType fromPrefix(String prefix) {
    return UsrClientNodeType.values.firstWhere(
          (e) => e.prefix == prefix,
      orElse: () => UsrClientNodeType.b2,
    );
  }

  static UsrClientNodeType fromClient(dynamic client) {
    final String typeName = client.runtimeType.toString().toUpperCase();
    if (typeName.contains('S100')) return UsrClientNodeType.s100;
    if (typeName.contains('B2')) return UsrClientNodeType.b2;
    if (typeName.contains('BL602')) return UsrClientNodeType.bl602;
    if (typeName.contains('ESP')) return UsrClientNodeType.esp;
    return UsrClientNodeType.a2;
  }
}