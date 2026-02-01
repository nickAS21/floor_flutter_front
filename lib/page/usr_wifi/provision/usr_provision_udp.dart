import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_utils.dart';

class UsrProvisionUdp implements UsrProvisionBase {
  static const int port = 49000;
  static const String broadcastIp = "255.255.255.255";
  final packetTest1 = Uint8List.fromList([
    0xFF, 0x00, 0x0F, 0x02, 0x00, 0x54, 0x45, 0x53, 0x54, 0x31, 0x0D, 0x0A, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0xCE
  ]);
  static const String ssidTest = "TEST1";
  static const String pwdTest = "123456";

  @override
  String getHint() => UsrProvisionUtils.provisionHint;

  @override
  Future<List<Map<String, dynamic>>> scanNetworks(String? mac) async {
    List<Map<String, dynamic>> found = [];
    RawDatagramSocket? socketCcanNetworks;
    try {
      socketCcanNetworks = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socketCcanNetworks.broadcastEnabled = true;

      final initPacket = Uint8List.fromList([0xFF, 0x00, 0x01, 0x01, 0x02]);
      socketCcanNetworks.send(initPacket, InternetAddress(broadcastIp), port);

      await socketCcanNetworks.timeout(const Duration(seconds: 3)).forEach((event) {
        if (event == RawSocketEvent.read) {
          final dg = socketCcanNetworks?.receive();
          if (dg != null && dg.data.length > 3 && dg.data[3] == 0x81) {
            found = _parseScanResponse(dg.data);
            socketCcanNetworks?.close();
          }
        }
      });
    } catch (_) {} finally {
      socketCcanNetworks?.close();
    }
    return found;
  }

  // cmd 0x02: Save SSID/PWD and reboot
  Future<String> saveAndRestart(String ssid, String pwd) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    // TODO test for algorithm by send packet
    // final packetTest = _generateSavePacket(ssidTest, pwdTest);
    // bool rez = packetTest == packetTest1;
    // socket.send(packetTest, InternetAddress(broadcastIp), port);


    final packet = _generateSavePacket(ssid, pwd);
    socket.send(packet, InternetAddress(broadcastIp), port);

    String result = "timeout";
    try {
      await socket.timeout(const Duration(seconds: 30)).forEach((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket?.receive();
          if (dg != null && dg.data[3] == 0x82) {
            int ssidCheck = dg.data[4];
            int pwdCheck = dg.data[5];
            if (ssidCheck == 0x01 && pwdCheck == 0x01) {
              result = "ok";
            } else if (ssidCheck == 0x00) {
              result = "invalid_ssid";
            } else if (pwdCheck == 0x00) {
              result = "invalid_password";
            } else {
              result = "unknown error";
            }
            socket.close();
          }
        }
      });
    } catch (_) {}
    socket.close();
    return result;
  }

  List<Map<String, dynamic>> _parseScanResponse(Uint8List data) {
    int pos = 5; // Згідно п. 4.8.7 [cite: 1106]
    List<Map<String, dynamic>> networks = [];
    List<int> buf = [];

    while (pos < data.length - 1) {
      if (data[pos] == 0x0D && data[pos + 1] == 0x0A) {
        if (buf.isNotEmpty) {
          int signal = buf.last;
          String ssid = latin1
              .decode(buf.takeWhile((b) => b != 0).toList())
              .trim();
          if (ssid.isNotEmpty) networks.add({'ssid': ssid, 'level': signal});
        }
        buf = [];
        pos += 2;
      } else {
        buf.add(data[pos++]);
      }
    }
    return networks;
  }

  Uint8List _generateSavePacket(String ssid, String pwd) {
    final builder = BytesBuilder();
    final sBytes = latin1.encode(ssid);
    final pBytes = latin1.encode(pwd);

    // 1. Заголовок (FF)
    builder.addByte(0xFF);

    // 2. Довжина (CMD[1] + ZERO[1] + SSID + \r\n[2] + PWD)
    // Для "TEST1" (5) + "123456" (6) + 1 + 1 + 2 = 15 (0x0F)
    final payloadLen = 1 + 1 + sBytes.length + 2 + pBytes.length;

    builder.addByte((payloadLen >> 8) & 0xFF); // 00
    builder.addByte(payloadLen & 0xFF);        // 0F

    // 3. Команда (02)
    builder.addByte(0x02);

    // 4. Дані (0x00 + SSID + \r\n + PWD)
    builder.addByte(0x00); // Обов'язковий нуль перед SSID з твого прикладу
    builder.add(sBytes);
    builder.add([0x0D, 0x0A]); // Розділювач \r\n
    builder.add(pBytes);

    // 5. Контрольна сума (CE)
    final pktSoFar = builder.toBytes();
    int sum = 0;
    // Сумуємо все після FF (починаючи з індексу 1)
    for (int i = 1; i < pktSoFar.length; i++) {
      sum += pktSoFar[i];
    }

    builder.addByte(sum & 0xFF);
    return builder.toBytes();
  }
}