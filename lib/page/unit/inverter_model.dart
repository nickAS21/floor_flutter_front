import 'inverter_info_model.dart';
import 'package:flutter/material.dart';

class InverterModel {
  final String? timestamp;
  final int? port;
  final String? connectionStatus; // Рядок прямо з Java Enum: "ACTIVE", "STANDBY", "OFFLINE"
  final InverterInfoModel? inverterInfo;

  InverterModel({
    this.timestamp,
    this.port,
    this.connectionStatus,
    this.inverterInfo,
  });

  factory InverterModel.fromJson(Map<String, dynamic> json) {
    return InverterModel(
      timestamp: json['timestamp'],
      port: json['port'],
      connectionStatus: json['connectionStatus'],
      inverterInfo: json['inverterInfo'] != null
          ? InverterInfoModel.fromJson(json['inverterInfo'])
          : null,
    );
  }

// Логіка визначення кольору за рядком
  Color get statusColor {
    switch (connectionStatus?.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;          // Дані йдуть напряму (менше 20 хв)
      case 'ACTIVE_INVERTER':
        return Colors.teal;           // Транзит через інвертор (тимчасовий хак)
      case 'STANDBY':
        return Colors.orange;         // Пауза (20-61 хв)
      case 'OFFLINE':
        return Colors.red;            // Труба (більше 61 хв)
      default:
        return Colors.grey;
    }
  }

  // Логіка відображення тексту
  String get statusText {
    switch (connectionStatus?.toUpperCase()) {
      case 'ACTIVE':
        return "Активний";
      case 'ACTIVE_INVERTER':
        return "Інвертор";           // Текст для відображення в UI
      case 'STANDBY':
        return "Очікування";
      case 'OFFLINE':
        return "Офлайн";
      default:
        return connectionStatus ?? "Невідомо";
    }
  }
}