import '../../page/usr_wifi/provision/client/connect_interface_type.dart';

class DataEspBmsInfo {
  String mac;              // MAC-адреса (для BLE) або унікальний ID (для RS485)
  String name;             // Read-only підсумкова назва (наприклад, "Daren-1" або "JK-A1B2")
  ConnectInterfaceType interfaceType; // rs485 або ble
  int? addressRs485;       // DIP / Modbus ID (для RS485, для BLE -> null)

  DataEspBmsInfo({
    this.mac = '',
    this.name = '',
    this.interfaceType = ConnectInterfaceType.rs485,
    this.addressRs485,
  });

  /// Генератор підсумкового поля [name] на основі префіксу (пользовательського суфіксу/моделі),
  /// інтерфейсу підключення та DIP-адреси або остатніх 4 символів MAC.
  static String buildName({
    required String customPrefix,
    required ConnectInterfaceType interfaceType,
    int? addressRs485,
    String mac = '',
  }) {
    final prefix = customPrefix.trim();

    if (interfaceType == ConnectInterfaceType.rs485) {
      final addr = addressRs485 ?? 1;
      return '$prefix-$addr';
    } else {
      // Для BLE: витягуємо останні 4 символи MAC у верхньому регістрі
      final cleanMac = mac.replaceAll(':', '').replaceAll('-', '').toUpperCase();
      final mac4 = cleanMac.length >= 4
          ? cleanMac.substring(cleanMac.length - 4)
          : "____";
      return '$prefix-$mac4';
    }
  }

  factory DataEspBmsInfo.fromJson(Map<String, dynamic> json) {
    return DataEspBmsInfo(
      mac: json['mac'] ?? '',
      name: json['name'] ?? '',
      interfaceType: ConnectInterfaceType.values.firstWhere(
            (e) => e.name == json['interfaceType'] || e.type == json['interfaceType'],
        orElse: () => ConnectInterfaceType.rs485,
      ),
      addressRs485: json['addressRs485'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mac': mac,
    'name': name,
    'interfaceType': interfaceType.name,
    if (addressRs485 != null) 'addressRs485': addressRs485,
  };
}