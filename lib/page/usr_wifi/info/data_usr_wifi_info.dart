import '../../data_home/data_location_type.dart';

class DataUsrWiFiInfo {
  int id;                         // netIpA - 18890 = id
  LocationType locationType;      // dacha/golego
  String bssidMac;                // MAC-адреса
  String ssidWifiBms;             // SSID модуля
  String netIpA;                  // IP сервера (STA mode Client)
  int netAPort;                   // Port STA (18890 + id)
  String netIpB;                  // IP BMS
  int netBPort;                   // Port BMS (8890 + id)
  String? oui;                    // Chip manufacturer (Vendor)

  DataUsrWiFiInfo({
    this.id = 0,
    this.locationType = LocationType.golego,
    this.bssidMac = '',
    this.ssidWifiBms = '',
    this.netIpA = '',
    this.netAPort = 18890,
    this.netIpB = '',
    this.netBPort = 8890,
    this.oui,
  });

  factory DataUsrWiFiInfo.fromJson(Map<String, dynamic> json) {
    return DataUsrWiFiInfo(
      id: json['id'] ?? 0,
      locationType: json['locationType'] == 'DACHA'
          ? LocationType.dacha
          : LocationType.golego,
      bssidMac: json['bssidMac'] ?? '',
      ssidWifiBms: json['ssidWifiBms'] ?? '',
      netIpA: json['netIpA'] ?? '',
      netAPort: json['netAPort'] ?? 18890,
      netIpB: json['netIpB'] ?? '',
      netBPort: json['netBPort'] ?? 8890,
      oui: json['oui'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'locationType': locationType == LocationType.dacha ? 'DACHA' : 'GOLEGO',
    'bssidMac': bssidMac,
    'ssidWifiBms': ssidWifiBms,
    'netIpA': netIpA,
    'netAPort': netAPort,
    'netIpB': netIpB,
    'netBPort': netBPort,
    'oui': oui,
  };
}