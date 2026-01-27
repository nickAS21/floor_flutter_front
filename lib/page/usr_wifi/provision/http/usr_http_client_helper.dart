
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class UsrHttpClientHelper {

  // main for connect
  static const String baseIpAtHttp = "10.10.100.254";
  static const String baseUrlHttp = "http://$baseIpAtHttp";
  static const String baseHttpLogin = "admin";
  static const String baseHttpPwd = "admin";
  static String get authBasicHeader {
    final credentials = '$baseHttpLogin:$baseHttpPwd';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  // const port + ip
  static const String backendHostHome = '192.168.8.119';
  static const String backendHostDacha = '192.168.28.15';
  static const String backendHostKubernet = '89.35.145.1';
  static const int netPortADef = 18890;
  static const int netPortBDef = 8890;
  static const String wifiSsidB2 = "USR-WIFI232-B2_";
  static const String wifiSsidA2 = "USR-WIFI232-A2_";
  static const String wifiSsidAx = "USR-WIFI232-AX_";
  static const List<String> usrSsidPrefixes = [wifiSsidB2, wifiSsidA2, wifiSsidAx];

  // html
  static const String htmlDoCmd = "do_cmd.html";
  static const String htmlStaConfig = "sta_config.html";
  static const String htmlAppConfig = "app_config.html";
  static const String htmlOpmode = "opmode.html";
  static const String htmlAp = "ap.html";
  static const String htmlFast = "fast.html";
  static const String baseUrlHttpFast = "$baseUrlHttp/EN/$htmlFast";
  static const String htmlRestart = "restart.html";
  static const String htmlManagement = "management.html";

  // commands main
  static const String mainCmd = "CMD";
  static const String mainGo = "GO";
  static const String mainCCMD = "CCMD";

  static const String cmdWirelessBasic = 'WIRELESS_BASIC';
  static const String cmdLan = 'LAN';
  static const String cmdApply = 'APPLY';
  static const String cmdASysConf = 'SYS_CONF';
  static const String cmdApplication = 'Application';

  // keys set
  static const String set0 = "SET0";
  static const String set1 = "SET1";
  static const String set2 = "SET2";
  static const String set3 = "SET3";
  static const String set4 = "SET4";
  static const String set5 = "SET5";


  // ID Fields
  // opmode.html
  static const String fieldApCliEnable = '81002752';        // addCfg('apcli_enable',0x04d40100,'0');
  static const String fieldWifiMode = '288162304';          // addCfg('wifi_mode',0x112d0200,'');
  static const String fieldCountryCode = '75038976';        // addCfg('country_code',0x04790100,'5');
  static const String fieldSysOpmode = '18088192';          // addCfg('sys_opmode',0x01140100,'1');
  static const String fieldDataTransformMode = '285278720'; // addCfg('Data_Transfor_Mode',0x11010200,'0');
  // sta_config.html - STA - on
  static const String fieldApStaEnable = '304677376';       // addCfg('apsta_en',0x12290200,'on');
  static const String fieldWlanClinum = '303104512';        // addCfg('wlan_clinum',0x12110200,'100'); => Signal threshold 100% == Note: The signal is less than this value, Switching network,If the value is 100,it's not switching network!
  // sta_config.html - new Ssid/Pwd                                                                                                              // Примечание. Сигнал меньше этого значения. Переключение сети. Если значение равно 100, это не переключение сети!
  static const String fieldSsidName = '81723904';           // addCfg('ssid_name',0x04df0200,'ThingsBoard_Guest');
  static const String fieldSEnTyPassP = '81658368';         // addCfg('S_EnTy_Pass_P',0x04de0200,'4Friends123!');
  static const String fieldSsidName3 = '304087552';         // addCfg('ssid_name3',0x12200200,'ThingsBoard_Guest');
  static const String fieldSEnTyPassP3 = '304022016';       // addCfg('S_EnTy_Pass_P3',0x121f0200,'4Friends123!');

  // app_config.html
  static const String fieldNetMode = '285999616';           // addCfg('net_mode',0x110c0200,'client');
                                                            // addCfg('net_protocol',0x110b0200,'TCP');
  static const String fieldNetPort = '286064896';           // addCfg('net_port',0x110d0100,'8899');
  static const String fieldNetIp = '286130688';             // addCfg('net_ip',0x110e0200,'192.168.8.119');
                                                            // addCfg('tcp_to',0x110f0100,'0'); => TCP Time out (MAX 600 s)
  static const String fieldNetbPort = '286392576';          // addCfg('netb_port',0x11120100,'18899');
  static const String fieldNetbIp = '286458368';            // addCfg('netb_ip',0x11130200,'89.35.145.1');
                                                            // addCfg('tcpb_to',0x11140100,'5'); => TCPB Time out (MAX 600 s)
  static const String fieldNetbMode = '286327040';          // addCfg('netb_mode',0x11110100,'1');
  // ap.html
  static const String fieldNkSsidName = '71041536';         // addCfg('NK_ssid_name',0x043c0200,'USR-WIFI232-A2_5DF8');
                                                            // addCfg('AP_EnTy_KEY',0x049c0200,'11111');
                                                            // addCfg('AP_EnTy_Pass_P',0x049a0200,'12345678');


  // values
  static const String valuesOn = "on";
  static const String valuesOff = "off";
  static const int valuesOn1 = 1;
  static const int valuesOff0 = 0;
  static const int values0 = 0;
  static const String valuesSta = "STA";
  static const String valuesEmpty = "";
  static const String valuesClient = "client";

  static void openModuleInChrome() {
    if (kIsWeb) return;

    // Формуємо URL виду http://admin:admin@10.10.100.254
    final String authUrl = "http://$baseHttpLogin:$baseHttpPwd@$baseIpAtHttp"; //

    if (Platform.isLinux) {
      // Запускаємо Chrome з URL, що вже містить логін/пароль
      Process.run('google-chrome', [authUrl]).catchError((_) {
        return Process.run('chromium-browser', [authUrl]);
      });
    }
  }
}