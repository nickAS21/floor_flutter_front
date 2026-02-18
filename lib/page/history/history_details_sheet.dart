import 'package:flutter/material.dart';
import 'history_model.dart';
import '../unit/unit_helper.dart';
import '../data_home/data_location_type.dart';

class HistoryDetailsSheet extends StatelessWidget {
  final HistoryModel record;
  final LocationType location;
  final Function(Map<String, dynamic>) onBatteryTap;

  const HistoryDetailsSheet(
      {super.key,
      required this.record,
      required this.location,
      required this.onBatteryTap});

  // Логіка кольору для верхньої іконки (статус мережі)
  Color _getGridStatusColor() {
    if (record.gridStatusRealTimeOnLine && record.gridStatusRealTimeSwitch) {
      return Colors.green;
    } else if (record.gridStatusRealTimeOnLine &&
        !record.gridStatusRealTimeSwitch) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

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
                  const Divider(height: 30),

                  // Блок потужності (Solar, Home, Grid)
                  if (record.dataHome != null) ...[
                    _buildDataHomeCard(record.dataHome!),
                    const SizedBox(height: 16),
                  ],

                  // Статус порта інвертора
                  _buildInverterPortStatus(),
                  const SizedBox(height: 16),

                  // Система акумуляторів
                  if (batteries.isNotEmpty) _batterySystem(context, batteries),

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
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      );

  Widget _mainInfo() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Запис ${record.timeOnly}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(children: [
          // Тут іконка СТАТУСУ (динамічна: зелена/оранжева/червона)
          Icon(Icons.cell_tower, size: 20, color: _getGridStatusColor()),
          const SizedBox(width: 8),
          _badge(record.gridStatusRealTimeSwitch ? "SW ON" : "SW OFF",
              record.gridStatusRealTimeSwitch ? Colors.blue : Colors.grey),
          const SizedBox(width: 4),
          _badge(record.gridStatusRealTimeOnLine ? "ON LINE" : "OFF LINE",
              record.gridStatusRealTimeOnLine ? Colors.green : Colors.red),
        ]),
      ]),
      const Divider(height: 20),
      _row("Заряд системи", "${record.batterySoc.toInt()}%",
          color: Colors.orange),
      _row("Напруга АКБ", "${record.batteryVol.toStringAsFixed(1)} V",
          color: Colors.blueGrey),
      _row("Статус роботи", record.batteryStatus,
          color: UnitHelper.getStatusColor(record.batteryStatus)),
    ]);
  }

  Widget _buildDataHomeCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _powerColumn(Icons.solar_power, "${data['solarPower'] ?? 0} W",
              "Solar", Colors.orange),
          _powerColumn(
              Icons.home, "${data['homePower'] ?? 0} W", "Home", Colors.blue),
          // ТУТ: Вежа в блоці потужності тепер ЗАВЖДИ ЗЕЛЕНА
          _powerColumn(Icons.cell_tower, "${data['gridPower'] ?? 0} W", "Grid",
              Colors.green),
        ],
      ),
    );
  }

  Widget _powerColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInverterPortStatus() {
    final status = record.inverterPortConnectionStatus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: UnitHelper.getConnectionColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: UnitHelper.getConnectionColor(status).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                UnitHelper.getConnectionIcon(status),
                color: UnitHelper.getConnectionColor(status),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text("Інвертор",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Text("Port: ${record.inverterPort}",
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _batterySystem(BuildContext context, List batteries) {
    // 1. Створюємо ВІДСОРТОВАНИЙ список як окрему зміну
    final List sortedList = List.from(batteries);
    sortedList.sort((a, b) {
      final int portA = int.tryParse(a['port']?.toString() ?? '0') ?? 0;
      final int portB = int.tryParse(b['port']?.toString() ?? '0') ?? 0;
      return portA.compareTo(portB);
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.battery_charging_full,
            // 2. Використовуємо sortedList для іконки
            color: sortedList.any((b) =>
            UnitHelper.hasRealError(b['errorInfoDataHex'] ?? '') ||
                ((b['deltaMv'] ?? 0.0) >= UnitHelper.cellsCriticalDeltaMin))
                ? Colors.red
                : Colors.blue,
            size: 40),
        title: const Text("Система акумуляторів",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          // 3. Використовуємо sortedList для підрахунку
            "Модулів: ${sortedList.length} | SOC: ${record.batterySoc.toInt()}%"),
        // 4. ТУТ ГОЛОВНЕ: ітеруємося по sortedList, а не по оригінальному batteries
        children: sortedList.map((b) {
          final bool hasError = UnitHelper.hasRealError(b['errorInfoDataHex'] ?? '');
          final bool isCritical = (b['deltaMv'] ?? 0.0) >= UnitHelper.cellsCriticalDeltaMin;

          Color statusColor = UnitHelper.getConnectionColor(b['connectionStatus']);
          if (hasError) {
            statusColor = Colors.red;
          } else if (isCritical) {
            statusColor = Colors.orange;
          }

          return ListTile(
            onTap: () => onBatteryTap(b),
            leading: Icon(
              UnitHelper.getConnectionIcon(b['connectionStatus']),
              color: statusColor,
            ),
            title: Text("Battery ${b['port'] ?? ''}"),
            subtitle: Text(
                "${(b['socPercent'] ?? 0).toInt()}% | ${(b['voltageCurV'] ?? 0).toStringAsFixed(2)}V"),
            trailing: const Icon(Icons.chevron_right),
          );
        }).toList(),
      ),
    );
  }

  Widget _row(String l, String? v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: Colors.black54)),
          Text(v ?? '--',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ]),
      );

  Widget _closeButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87),
          onPressed: () => Navigator.pop(context),
          child: const Text("Закрити"),
        ),
      );

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: c, width: 0.8)),
        child: Text(t,
            style:
                TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: c)),
      );
}
