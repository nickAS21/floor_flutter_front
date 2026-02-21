import '../usr_client_helper.dart';

class UsrWiFi232HttpClientHelper {

  // html
  static const String htmlDoCmd = "do_cmd.html";
  static const String htmlStaConfig = "sta_config.html";
  static const String htmlAppConfig = "app_config.html";
  static const String htmlOpmode = "opmode.html";
  static const String htmlAp = "ap.html";
  static const String htmlFast = "fast.html";
  static const String htmlSiteSurvey = "site_survey.html";
  static const String baseUrlHttpFast = "${UsrClientHelper.baseUrlHttpWiFi232}/EN/$htmlFast";
  static const String baseUrlHttpSiteSurvey = "${UsrClientHelper.baseUrlHttpWiFi232}/EN/$htmlSiteSurvey";
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
  static const String set6 = "SET6";
  static const String set7 = "SET7";
  static const String set8 = "SET8";
  static const String set9 = "SET9";
  static const String set10 = "SET10";
  static const String set11 = "SET11";
  static const String set12 = "SET12";
  static const String set13 = "SET13";
  static const String set14 = "SET14";


  // ID Fields
  // opmode.html
  static const String fieldApCliEnable = '81002752';        // addCfg('apcli_enable',0x04d40100,'0');
  static const String fieldWifiMode = '288162304';          // addCfg('wifi_mode',0x112d0200,'STA');
  static const String fieldCountryCode = '75038976';        // addCfg('country_code',0x04790100,'5');
  static const String fieldSysOpmode = '18088192';          // addCfg('sys_opmode',0x01140100,'2');
  static const String fieldDataTransformMode = '285278720'; // addCfg('Data_Transfor_Mode',0x11010200,'0');

  /**
   * DHCP Mode
   * CMD LAN
      GO sta_config.html
      SET0 50397440=2                   // addCfg('WAN_TYPE',0x03010100,'2'); 1- SATTIC(fixed IP) 2 - DCHP (Auto config)
      SET1 17105408=USR-WIFI232-B2_5AE0 // addCfg('HN',0x01050200,'USR-WIFI232-B2_5AE0');
      SET2 235077888=0                  // addCfg('SWANDNSFIX',0x0e030100,'0'); 0- Auto; 1 - Static

   *
   * sta_config.html new Ssid/Pwd (AP1's SSID + Pass Phrase1) + STA - on
      CMD LAN
      GO sta_config.html
      SET0 81723904=lebed         +
      SET1 81134080=WPA2PSK       +
      SET2 81199616=AES           +
      SET3 81658368=lebedhomewifi +
      SET4 82706944=OPEN          +
      SET5 82772480=NONE          +
      SET6 83231232=OPEN          +
      SET7 83296768=NONE          +
      SET8 304087552=lebed        +
      SET9 303694336=WPA2PSK      +
      SET10 303759872=AES         +
      SET11 304022016=lebedhomewifi +
      SET12 305136128=0           +
      SET13 304677376=on          +

      addCfg('ssid_name',0x04df0200,'lebed');               +
      addCfg('apcli_bssid',0x04d50200,''); ??
      addCfg('S_SecurityMode',0x04d60200,'WPA2PSK');        +
      addCfg('S_EncryptionType',0x04d70200,'AES');          +
      addCfg('S_EnTyWEP',0x04d80100,'0');
      addCfg('S_EnTy_KEY',0x04d90200,'');
      addCfg('S_EnTy_Pass_P',0x04de0200,'lebedhomewifi');
      addCfg('ssid_name1',0x04f40200,'USR-WIFI232-AP2');
      addCfg('apcli_bssid1',0x04ed0200,'');
      addCfg('S_SecurityMode1',0x04ee0200,'');              +
      addCfg('S_EncryptionType1',0x04ef0200,'');            +
      addCfg('S_EnTyWEP1',0x04f00100,'0');
      addCfg('S_EnTy_KEY1',0x04f10200,'');
      addCfg('S_EnTy_Pass_P1',0x04f30200,'');
      addCfg('ssid_name2',0x04fc0200,'USR-WIFI232-AP3');
      addCfg('apcli_bssid2',0x04f50200,'');
      addCfg('S_SecurityMode2',0x04f60200,'');              +
      addCfg('S_EncryptionType2',0x04f70200,'');            +
      addCfg('S_EnTyWEP2',0x04f80100,'0');
      addCfg('S_EnTy_KEY2',0x04f90200,'');
      addCfg('S_EnTy_Pass_P2',0x04fb0200,'');
      addCfg('ssid_name3',0x12200200,'lebed');
      addCfg('apcli_bssid3',0x12190200,'');
      addCfg('S_SecurityMode3',0x121a0200,'WPA2PSK');       +
      addCfg('S_EncryptionType3',0x121b0200,'AES');         +
      addCfg('S_EnTyWEP3',0x121c0200,'0');
      addCfg('S_EnTy_KEY3',0x121d0200,'');
      addCfg('S_EnTy_Pass_P3',0x121f0200,'lebedhomewifi');  +
      addCfg('wlan_clinum',0x12110200,'100');
      addCfg('WAN_TYPE',0x03010100,'2');
      addCfg('HN',0x01050200,'USR-WIFI232-B2_34D4');
      addCfg('SWANIP',0x03020300,'0.0.0.0');
      addCfg('SWANMSK',0x03030300,'0.0.0.0');
      addCfg('SWANGW',0x03040300,'0.0.0.0');
      addCfg('SWANDNS',0x0e020301,'');
      addCfg('SWANDNSFIX',0x0e030100,'0');
      addCfg('sta_protect',0x12300200,'off');             +
      addCfg('hd_ver',0x12220200,'A');
      addCfg('apsta_en',0x12290200,'on');                 +
      addCfg('phy_wmod',0x113b0200,'n');


   */

  // sta_config.html - STA - on
  static const String fieldApStaEnable = '304677376';           // addCfg('apsta_en',0x12290200,'on');
  static const String fieldWlanClinum = '303104512';            // addCfg('wlan_clinum',0x12110200,'100'); => Signal threshold 100% == Note: The signal is less than this value, Switching network,If the value is 100,it's not switching network!
  // sta_config.html - DHCP mode auto
  static const String fieldWanType = '50397440';                // addCfg('WAN_TYPE',0x03010100,'2'); 1- SATTIC(fixed IP) 2 - DCHP (Auto config)
  static const String fieldHNWanName = '17105408';              // addCfg('HN',0x01050200,'USR-WIFI232-B2_5AE0');
  static const String fieldSWanDnsFix = '235077888';            // addCfg('SWANDNSFIX',0x0e030100,'0'); 0- Auto; 1 - Static
  // sta_config.html - new Ssid/Pwd                                                                                                              // Примечание. Сигнал меньше этого значения. Переключение сети. Если значение равно 100, это не переключение сети!
  static const String fieldSsidName = '81723904';               // addCfg('ssid_name',0x04df0200,'ThingsBoard_Guest');
  static const String fieldSSecurityMode = '81134080';          // addCfg('S_SecurityMode',0x04d60200,'WPA2PSK');
  static const String fieldSEncryptionType = '81199616';          // addCfg('S_EncryptionType',0x04d70200,'AES');
  static const String fieldSEnTyWEP = '81264896';          // addCfg('S_EnTyWEP',0x04d80100,'1');
  static const String fieldSEnTyPassP = '81658368';             // addCfg('S_EnTy_Pass_P',0x04de0200,'4Friends123!');
  static const String fieldSSecurityMode1 = '82706944';             // addCfg('S_SecurityMode1',0x04ee0200,'');
  static const String fieldSEncryptionType1 = '82772480';             // addCfg('S_EncryptionType1',0x04ef0200,'');
  static const String fieldSSecurityMode2 = '83231232';             // addCfg('S_SecurityMode2',0x04f60200,'');
  static const String fieldSEncryptionType2 = '83296768';             // addCfg('S_EncryptionType2',0x04f70200,'');
  static const String fieldSsidName3 = '304087552';             // addCfg('ssid_name3',0x12200200,'ThingsBoard_Guest');
  static const String fieldSSecurityMode3 = '303694336';             // addCfg('S_SecurityMode3',0x121a0200,'WPA2PSK');
  static const String fieldSEncryptionType3 = '303759872';             // addCfg('S_EncryptionType3',0x121b0200,'AES');
  static const String fieldSEnTyWEP3 = '303825408';             // addCfg('S_EnTyWEP3',0x121c0200,'');
  static const String fieldSEnTyPassP3 = '304022016';           // addCfg('S_EnTy_Pass_P3',0x121f0200,'4Friends123!');
  static const String fieldStaProtec = '305136128';           // addCfg('sta_protect',0x12300200,'off');

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
  static const String fieldFrequencyAuto = '70713600';         // addCfg('Frequency_auto',0x04370100,'1');
                                                            // addCfg('AP_EnTy_KEY',0x049c0200,'11111');
                                                            // addCfg('AP_EnTy_Pass_P',0x049a0200,'12345678');


  // values
  static const String valuesOn = "on";
  static const String valuesOff = "off";
  static const int valuesOn1 = 1;
  static const int valuesOff0 = 0;
  static const int values0 = 0;
  static const int values1 = 1;
  static const int values2 = 2;
  static const int values5 = 5;
  static const int values100 = 100;
  static const String valuesSta = "STA";
  static const String valuesEmpty = "";
  static const String valuesClient = "client";
  static const String valuesWPA2PSK = "WPA2PSK";
  static const String valuesAES = "AES";
  static const String valuesOPEN = "OPEN";
  static const String valuesNONE = "NONE";

}