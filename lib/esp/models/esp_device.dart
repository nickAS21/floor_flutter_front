enum EspChipType {
  bl602,
  esp32mini,
  unknown,
}

class EspDevice {
  final String id;
  final String name;
  final int rssi;
  final EspChipType chipType;

  const EspDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.chipType = EspChipType.bl602,
  });
}