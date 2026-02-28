import 'package:flutter/material.dart';
import 'history_model.dart';
import '../unit/unit_helper.dart';

class HistoryCard extends StatelessWidget {
  final HistoryModel record;
  final VoidCallback onTap;

  const HistoryCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final TextStyle s = UnitHelper.badgeStyle;

    // Логіка кольору для іконки вежі (Grid)
    Color getGridIconColor() {
      if (record.gridStatusRealTimeOnLine && record.gridStatusRealTimeSwitch) {
        return Colors.green; // Мережа є + увімкнено
      } else if (record.gridStatusRealTimeOnLine && !record.gridStatusRealTimeSwitch) {
        return Colors.orange; // Мережа є, але SW Off (очікування)
      } else {
        return Colors.red; // Мережі немає
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Ліва плашка з часом
            Container(
              width: 55,
              height: 50,
              alignment: Alignment.center,
              color: Colors.blueGrey.shade50,
              child: Text(
                record.timeOnly,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Секція статусів (Grid та Inverter)
                    Flexible(
                      child: Row(
                        children: [
                          // 1. GRID (Вежа з динамічним кольором)
                          Icon(
                            Icons.cell_tower,
                            size: 14,
                            color: getGridIconColor(),
                          ),
                          const SizedBox(width: 4),
                          _badge(
                            record.gridStatusRealTimeSwitch ? "SW ON" : "SW OFF",
                            record.gridStatusRealTimeSwitch ? Colors.blue : Colors.grey,
                          ),
                          const Text(" / ", style: TextStyle(fontSize: 8, color: Colors.grey)),
                          _badge(
                            record.gridStatusRealTimeOnLine ? "ON LINE" : "OFF LINE",
                            record.gridStatusRealTimeOnLine ? Colors.green : Colors.red,
                          ),

                          const SizedBox(width: 10),

                          // 2. INVERTER (Статус + Порт)
                          Icon(
                            UnitHelper.getConnectionIcon(record.inverterPortConnectionStatus),
                            size: 12,
                            color: UnitHelper.getConnectionColor(record.inverterPortConnectionStatus),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${record.inverterPort}",
                            style: s.copyWith(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    // Секція батареї (SOC + Статус)
                    Row(
                      children: [
                        Text(
                          "${record.batterySoc.toInt()}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.batteryStatus,
                          style: TextStyle(
                            color: UnitHelper.getStatusColor(record.batteryStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Допоміжний метод для створення компактних бейджів
  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: c.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: c, width: 0.8),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 7,
        fontWeight: FontWeight.bold,
        color: c,
      ),
    ),
  );
}