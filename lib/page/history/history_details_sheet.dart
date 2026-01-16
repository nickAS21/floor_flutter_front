import 'package:flutter/material.dart';
import 'history_model.dart';
import '../unit/unit_helper.dart';
import '../data_home/data_location_type.dart';

class HistoryDetailsSheet extends StatelessWidget {
  final HistoryModel record;
  final LocationType location;
  final Function(Map<String, dynamic>) onBatteryTap;

  const HistoryDetailsSheet({
    super.key,
    required this.record,
    required this.location,
    required this.onBatteryTap
  });

  @override
  Widget build(BuildContext context) {
    final batteries = record.batteries ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  _mainInfo(),
                  if (batteries.isNotEmpty) _batterySystem(context, batteries),
                  const Divider(height: 30),
                  _powerInfo(),
                  const SizedBox(height: 20),
                  _closeButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    ),
  );

  Widget _mainInfo() => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text("Запис ${record.timeOnly}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      _badge(record.gridStatusRealTimeOnLine ? "GRID ON" : "GRID OFF", record.gridStatusRealTimeOnLine ? Colors.green : Colors.red),
    ]),
    const Divider(height: 30),
    _row("Заряд системи", "${record.batterySoc.toInt()}%", color: Colors.orange),
    _row("Статус роботи", record.batteryStatus, color: UnitHelper.getStatusColor(record.batteryStatus)),
  ]);

  Widget _batterySystem(BuildContext context, List batteries) => Card(
    elevation: 3,
    margin: const EdgeInsets.only(top: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: Icon(Icons.battery_charging_full,
          color: batteries.any((b) => UnitHelper.hasRealError(b['errorInfoDataHex'])) ? Colors.red : Colors.blue, size: 40),
      title: const Text("Система акумуляторів", style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Модулів: ${batteries.length} | SOC: ${record.batterySoc.toInt()}%"),
      children: batteries.map((b) => ListTile(
        onTap: () => onBatteryTap(b),
        leading: Icon(UnitHelper.getConnectionIcon(b['connectionStatus']), color: UnitHelper.getConnectionColor(b['connectionStatus'])),
        title: Text("Battery ${b['port'] ?? ''}"),
        subtitle: Text("${(b['socPercent'] ?? 0).toInt()}% | ${(b['voltageCurV'] ?? 0).toStringAsFixed(2)}V"),
        trailing: const Icon(Icons.chevron_right),
      )).toList(),
    ),
  );

  Widget _powerInfo() => Column(children: [
    _row("Сонячна панель", "${record.dataHome?['solarPower'] ?? 0} W"),
    _row("Споживання дому", "${record.dataHome?['homePower'] ?? 0} W"),
    _row("Навантаження Grid", "${record.dataHome?['gridPower'] ?? 0} W"),
  ]);

  Widget _row(String l, String? v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.black54)),
      Text(v ?? '--', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]),
  );

  Widget _closeButton(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
      onPressed: () => Navigator.pop(context),
      child: const Text("Закрити"),
    ),
  );

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: c, width: 0.8)),
    child: Text(t, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: c)),
  );
}