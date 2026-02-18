import '../../data_home/data_location_type.dart';
import '../provision/client/http/usr_wifi_232_http_client_helper.dart';

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
  int bitrate;                    // Bit Rate (Baud)

  DataUsrWiFiInfo({
    this.id = 0,
    this.locationType = LocationType.golego,
    this.bssidMac = '',
    this.ssidWifiBms = '',
    this.netIpA = '',
    this.netAPort = UsrWiFi232HttpClientHelper.netPortADef,
    this.netIpB = '',
    this.netBPort = UsrWiFi232HttpClientHelper.netPortBDef,
    this.oui,
    this.bitrate = 2400,
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
      netAPort: json['netAPort'] ?? UsrWiFi232HttpClientHelper.netPortADef,
      netIpB: json['netIpB'] ?? '',
      netBPort: json['netBPort'] ?? UsrWiFi232HttpClientHelper.netPortBDef,
      oui: json['oui'],
      bitrate: json['bitrate'] ?? 2400,
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
    'bitrate': bitrate,
  };
}