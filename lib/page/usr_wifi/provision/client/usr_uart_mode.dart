enum UsrUartInterfaceType {
  rs485("RS485", true),
  rxTx("Rx / Tx (UART)", false);

  final String label;
  final bool isRs485Enabled;

  const UsrUartInterfaceType(this.label, this.isRs485Enabled);
}