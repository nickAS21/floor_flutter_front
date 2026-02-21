import '../../data_home/data_location_type.dart';
import '../provision/client/usr_client_helper.dart';
import '../provision/usr_provision_helper.dart';

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
    this.netAPort = UsrClientHelper.netPortADef,
    this.netIpB = '',
    this.netBPort = UsrClientHelper.netPortBDef,
    this.oui,
    this.bitrate = UsrProvisionHelper.bitrateDef,
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
      netAPort: json['netAPort'] ?? UsrClientHelper.netPortADef,
      netIpB: json['netIpB'] ?? '',
      netBPort: json['netBPort'] ?? UsrClientHelper.netPortBDef,
      oui: json['oui'],
      bitrate: json['bitrate'] ?? UsrProvisionHelper.bitrateDef,
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