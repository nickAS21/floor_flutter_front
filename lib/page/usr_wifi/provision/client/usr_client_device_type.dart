enum UsrClientDeviceType {
  a2("USR-WIFI232-A2_", "WIFI232-A2", isBleSupported: false),
  b2("USR-WIFI232-B2_", "WIFI232-B2", isBleSupported: false),
  s100("USR-S100-", "S100", isBleSupported: false),
  esp("ESP-", "ESP", isBleSupported: true),
  bl602("BL602-", "BL602", isBleSupported: true);

  final String prefix;
  final String label;
  final bool isBleSupported; // Явний прапорець підтримки BLE BMS

  const UsrClientDeviceType(
      this.prefix,
      this.label, {
        this.isBleSupported = false,
      });

  static UsrClientDeviceType fromPrefix(String prefix) {
    return UsrClientDeviceType.values.firstWhere(
          (e) => e.prefix == prefix,
      orElse: () => UsrClientDeviceType.b2,
    );
  }

  static UsrClientDeviceType fromClient(dynamic client) {
    final String typeName = client.runtimeType.toString().toUpperCase();
    if (typeName.contains('S100')) return UsrClientDeviceType.s100;
    if (typeName.contains('B2')) return UsrClientDeviceType.b2;
    if (typeName.contains('BL602')) return UsrClientDeviceType.bl602;
    if (typeName.contains('ESP')) return UsrClientDeviceType.esp;
    return UsrClientDeviceType.a2;
  }
}