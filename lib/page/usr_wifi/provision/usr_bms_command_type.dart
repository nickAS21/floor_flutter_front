enum UsrBmsCommandType {
  cmdGetWifiList(0x01, "req_wifi_list"),
  rspWifiList(0x81, "resp_wifi_list"),
  cmdUpdateSettings(0x02, "req_wifi_config"),
  rspUpdateSettings(0x82, "resp_wifi_config"),
  rspErrors(0x101, "resp_wifi_error"),
  unknown(0x00, "unknown");

  final int code;
  final String typeName;

  const UsrBmsCommandType(this.code, this.typeName);

  static UsrBmsCommandType fromCode(int code) {
    return UsrBmsCommandType.values.firstWhere(
          (element) => element.code == code,
      orElse: () => UsrBmsCommandType.unknown,
    );
  }
}