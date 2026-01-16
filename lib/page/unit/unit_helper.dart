import 'package:flutter/material.dart';

class UnitHelper {
  static const double cellsCriticalDeltaMin = 0.100;

  static IconData getConnectionIcon(String? status) {
    if (status?.toUpperCase() == 'ACTIVE' || status?.toUpperCase() == 'ONLINE') return Icons.cloud_done;
    if (status?.toUpperCase() == 'STANDBY') return Icons.access_time_filled;
    return Icons.cloud_off;
  }

  static Color getConnectionColor(String? status) {
    if (status?.toUpperCase() == 'ACTIVE' || status?.toUpperCase() == 'ONLINE') return Colors.green;
    if (status?.toUpperCase() == 'STANDBY') return Colors.orange;
    return Colors.red;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'charging': return Colors.green;
      case 'discharging': return Colors.red;
      case 'static': return Colors.blue;
      default: return Colors.grey;
    }
  }

  static bool hasRealError(String? hex) {
    if (hex == null || hex.isEmpty) return false;
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    final val = int.tryParse(cleanHex, radix: 16);
    return val != null && val > 0;
  }

  static String formatHex(String? hex) {
    if (hex == null || hex.isEmpty) return "0x0000";
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    return "0x${cleanHex.padLeft(4, '0').toUpperCase()}";
  }
}