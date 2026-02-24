import '../info/data_usr_wifi_info.dart';

class UsrWiFiInfoLocationServerSession {
  List<DataUsrWiFiInfo> data;
  bool isInitialized; // true — сесія почалася, авто-GET більше не турбує

  UsrWiFiInfoLocationServerSession({
    required this.data,
    this.isInitialized = false,
  });
}