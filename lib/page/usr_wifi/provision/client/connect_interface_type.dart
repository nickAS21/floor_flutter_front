enum ConnectInterfaceType {
  rs485("RS485", 1),
  rxTx("Rx / Tx (UART)", 0),
  ble("BLE", 2);

  final String label;
  final int type;

  const ConnectInterfaceType(this.label, this.type);

  /// Геттер для зворотної сумісності з legacy USR-клієнтами (A2/B2/S100)
  bool get isRs485Enabled => this == ConnectInterfaceType.rs485;
}