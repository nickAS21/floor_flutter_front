import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_base.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_helper.dart';

import 'client/usr_client.dart';

class UsrWiFi232ProvisionUdp extends UsrProvisionBase {
  RawDatagramSocket? _socket;

  Future<RawDatagramSocket> _getSocket() async {
    if (_socket != null) return _socket!;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
    return _socket!;
  }

  @override
  Future<List<Map<String, dynamic>>> scanNetworks(String? ssid, UsrClient usrClient) async {
    List<Map<String, dynamic>> found = [];

    try {
      final socket = await _getSocket();

      // final initPacket = Uint8List.fromList([0xFF, 0x00, 0x01, 0x01, 0x02]);
      socket.send(UsrProvisionHelper.initPacket, InternetAddress(UsrProvisionHelper.broadcastIp), UsrProvisionHelper.targetPortDef);

      await socket.timeout(const Duration(seconds: 3)).forEach((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null && dg.data.length > 3 && dg.data[3] == UsrProvisionHelper.byteRspWifiList) {
            found = _parseScanResponse(dg.data);
            throw "stop";
          }
        }
      });
    } catch (e) {
      // "stop" — це нормальний вихід, ігноруємо інші помилки
    }
    return found;
  }

  Future<String> saveAndRestart(String ssid, String pwd) async {
    final socket = await _getSocket();

    while (socket.receive() != null) {}

    final packet = _generateSavePacket(ssid, pwd);
    socket.send(packet, InternetAddress(UsrProvisionHelper.broadcastIp), UsrProvisionHelper.targetPortDef);

    String result = "timeout";
    try {
      await socket.timeout(const Duration(seconds: UsrProvisionHelper.timeoutSocketDuration)).forEach((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null && dg.data.length > 5 && dg.data[3] == UsrProvisionHelper.byteRspUpdateSettings) {
            int ssidCheck = dg.data[4];
            int pwdCheck = dg.data[5];

            if (ssidCheck == UsrProvisionHelper.byteUpdateSsidPwdOk && pwdCheck == UsrProvisionHelper.byteUpdateSsidPwdOk) {
              result = "ok";
            } else if (ssidCheck == UsrProvisionHelper.byteUpdateSsidPwdBad) {
              result = "invalid_ssid";
            } else if (pwdCheck == UsrProvisionHelper.byteUpdateSsidPwdBad) {
              result = "invalid_password";
            } else {
              result = "unknown error";
            }
            throw "stop";
          }
        }
      });
    } catch (_) {
      // "stop" перекине нас сюди, що нормально
    }
    return result;
  }

  List<Map<String, dynamic>> _parseScanResponse(Uint8List data) {
    int pos = 5; // Згідно п. 4.8.7 [cite: 1106]
    List<Map<String, dynamic>> networks = [];
    List<int> buf = [];

    while (pos < data.length - 1) {
      if (data[pos] == UsrProvisionHelper.byteSeparatorD && data[pos + 1] == UsrProvisionHelper.byteSeparatorA) {
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
    builder.addByte(UsrProvisionHelper.byteMaskTo255);

    // 2. Довжина (CMD[1] + ZERO[1] + SSID + \r\n[2] + PWD)
    // Для "TEST1" (5) + "123456" (6) + 1 + 1 + 2 = 15 (0x0F)
    final payloadLen = 1 + 1 + sBytes.length + 2 + pBytes.length;

    builder.addByte((payloadLen >> 8) & UsrProvisionHelper.byteMaskTo255); // 00
    builder.addByte(payloadLen & UsrProvisionHelper.byteMaskTo255);        // 0F

    // 3. Команда (02)
    builder.addByte(UsrProvisionHelper.byteCmdUpdateSettings);

    // 4. Дані (0x00 + SSID + \r\n + PWD)
    builder.addByte(0x00); // Обов'язковий нуль перед SSID з твого прикладу
    builder.add(sBytes);
    builder.add([UsrProvisionHelper.byteSeparatorD, UsrProvisionHelper.byteSeparatorA]); // Розділювач \r\n
    builder.add(pBytes);

    // 5. Контрольна сума (CE)
    final pktSoFar = builder.toBytes();
    int sum = 0;
    // Сумуємо все після FF (починаючи з індексу 1)
    for (int i = 1; i < pktSoFar.length; i++) {
      sum += pktSoFar[i];
    }

    builder.addByte(sum & UsrProvisionHelper.byteMaskTo255);
    return builder.toBytes();
  }

  void close() {
    _socket?.close();
    _socket = null;
  }

  void testSendSsidPwd() {
    // TODO test for algorithm by send packet
    final packetTest = _generateSavePacket(UsrProvisionHelper.ssidTest, UsrProvisionHelper.pwdTest);
    bool rez = packetTest == UsrProvisionHelper.packetTest1;
  }

  @override
  Future<String?> getActiveSsid() async {
    return null;
  }
}