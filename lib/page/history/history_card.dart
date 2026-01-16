import 'package:flutter/material.dart';
import 'history_model.dart';
import '../unit/unit_helper.dart';

class HistoryCard extends StatelessWidget {
  final HistoryModel record;
  final VoidCallback onTap;

  const HistoryCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Container(
              width: 55, height: 50,
              alignment: Alignment.center,
              color: Colors.blueGrey.shade50,
              child: Text(record.timeOnly, style: const TextStyle(fontWeight: FontWeight.bold))
          ),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _badge(record.gridStatusRealTimeSwitch ? "SW ON" : "SW OFF", record.gridStatusRealTimeSwitch ? Colors.blue : Colors.grey),
                          const SizedBox(width: 4),
                          _badge(record.gridStatusRealTimeOnLine ? "GRID ON" : "GRID OFF", record.gridStatusRealTimeOnLine ? Colors.green : Colors.red),
                        ]),
                        Text("${record.batterySoc.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        Text(
                            record.batteryStatus,
                            style: TextStyle(color: UnitHelper.getStatusColor(record.batteryStatus), fontWeight: FontWeight.bold, fontSize: 11)
                        ),
                      ]
                  )
              )
          ),
        ]),
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: c, width: 0.8)),
    child: Text(t, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: c)),
  );
}