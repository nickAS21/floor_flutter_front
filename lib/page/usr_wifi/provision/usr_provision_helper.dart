

class UsrProvisionHelper {
  static const int byteMaskTo255 = 0xFF;
  static const int byteSeparatorD = 0x0D;
  static const int byteSeparatorA = 0x0A;
  static const int byteUpdateSsidPwdBad = 0x00;
  static const int byteUpdateSsidPwdOk = 0x01;
  static const int byteCmdGetWifiList = 0x01;
  static const int byteRspWifiList = 0x81;
  static const int byteCmdUpdateSettings = 0x02;
  static const int byteRspUpdateSettings = 0x82;
  static const int portDef = 26000;
  static const int targetPortDef = 49000;
  static const int timeoutSocketDuration = 30; // TimeOut response in s
  static const String broadcastIp = "255.255.255.255";
  static List<int> get initPacket => List<int>.from([0xFF, 0x00, 0x01, 0x01, 0x02]);
  static const int bitrateDef = 2400;


  // Tetst
  static List<int> get packetTest1 => List<int>.from([0xFF, 0x00, 0x0F, 0x02, 0x00, 0x54, 0x45, 0x53, 0x54, 0x31, 0x0D, 0x0A, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xCE]);
  static const String ssidTest = "TEST1";
  static const String pwdTest = "123456";
  
}
