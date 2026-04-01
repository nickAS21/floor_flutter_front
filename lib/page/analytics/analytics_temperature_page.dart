import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data_home/data_location_type.dart';
import '../refreshable_state.dart';
import 'analitic_model.dart';
import 'anaytic_connect_service.dart';

class AnalyticsTemperaturePage extends StatefulWidget {
  final LocationType location;
  final bool isTemperature;
  const AnalyticsTemperaturePage({super.key, required this.location, required this.isTemperature});

  @override
  State<AnalyticsTemperaturePage> createState() => _AnalyticsTemperaturePageState();
}

class _AnalyticsTemperaturePageState extends RefreshableState<AnalyticsTemperaturePage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  int _touchedBarIndex = -1;
  int _touchedGroupIndex = -1;
  double tempRatio = 2.0;

  @override
  void refresh() {
    setState(() => _isLoading = true);
    _fetchData();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant AnalyticsTemperaturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Якщо локація в новому віджеті відрізняється від старої
    if (oldWidget.location != widget.location) {
      _fetchData(); // Перезавантажуємо дані для нової локації
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAnalyticDay(date: _selectedDate, location: widget.location);
      if (mounted) {
        setState(() {
          _allData = data..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  LineChartBarData _buildLineData(List<AnalyticModel> data, double Function(AnalyticModel) getValue, Color color) {

    return LineChartBarData(
      spots: data.map((m) => FlSpot(m.timestamp.toDouble(), getValue(m))).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,

      // ВИМИКАЄМО ТОЧКИ:
      dotData: const FlDotData(show: false),

      // ДОДАЄМО ЛЕГКУ ЗАЛИВКУ (як у Power):
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1), // Ледь помітний фон під лінією
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.location.label, style: const TextStyle(fontSize: 16)),
            Text(DateFormat('dd.MM.yyyy').format(_selectedDate), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: _pickDate),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
              child: _buildMainChart(),
            ),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now());
    if (d != null) { setState(() { _selectedDate = d; }); _fetchData(); }
  }

  Widget _buildHeader() {
    if (_allData.isEmpty) return const SizedBox(height: 60);
    final index = (_touchedGroupIndex == -1 || _touchedGroupIndex >= _allData.length)
        ? _allData.length - 1
        : _touchedGroupIndex;
    final last = _allData[index];
    final timeStr = DateFormat('HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(last.timestamp, isUtc: true));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Table(
        // Визначаємо ширину колонок: перша для часу, інші рівномірні
        columnWidths: const {
          0: FlexColumnWidth(1.2), // Для "Time"
          1: FlexColumnWidth(2),   // Temp
          2: FlexColumnWidth(2),   // Hum
          3: FlexColumnWidth(2),   // Lum
        },
        children: [
          // ПЕРШИЙ РЯДОК (Внутрішні показники + Час)
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Text("Time:\n$timeStr",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              _statItem("In Temp", "${last.temperatureIn.toStringAsFixed(1)}°", Colors.green),
              _statItem("In Hum", "${last.humidityIn.toStringAsFixed(1)}%", Colors.brown),
              _statItem("In Lum", "${last.luminanceIn.toStringAsFixed(1)}%", Colors.orange),
            ],
          ),
          // Відступ між рядками
          const TableRow(children: [SizedBox(height: 8), SizedBox(), SizedBox(), SizedBox()]),
          // ДРУГИЙ РЯДОК (Зовнішні показники)
          TableRow(
            children: [
              const SizedBox(), // Порожньо під часом
              _statItem("Out Temp", "${last.temperatureOut.toStringAsFixed(1)}°", Colors.blue),
              _statItem("Out Hum", "${last.humidityOut.toStringAsFixed(1)}%", Colors.deepPurple),
              _statItem("Out Lum", "${last.luminanceOut.toStringAsFixed(1)}%", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String l, String v, Color c) => Column(children: [Text(l, style: TextStyle(color: c, fontSize: 9)), Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]);

  Widget _buildMainChart() {
    if (_allData.isEmpty) return const Center(child: Text("Немає даних"));

    var firstDate = DateTime.fromMillisecondsSinceEpoch(_allData.first.timestamp, isUtc: true);
    double minX = DateTime.utc(firstDate.year, firstDate.month, firstDate.day).millisecondsSinceEpoch.toDouble();
    double maxX = DateTime.utc(firstDate.year, firstDate.month, firstDate.day + 1).millisecondsSinceEpoch.toDouble();

    // Налаштування осей залежно від типу графіка
    double chartMinY;
    double chartMaxY;
    List<LineChartBarData> lines = [];

    if (widget.isTemperature) {
      // --- ЛОГІКА ДЛЯ ТЕМПЕРАТУРИ ---
      double minTemp = 100.0;
      double maxTemp = -100.0;

      for (var m in _allData) {
        if (m.temperatureOut < minTemp) minTemp = m.temperatureOut;
        if (m.temperatureIn < minTemp) minTemp = m.temperatureIn;
        if (m.temperatureOut > maxTemp) maxTemp = m.temperatureOut;
        if (m.temperatureIn > maxTemp) maxTemp = m.temperatureIn;
      }

      // Округлення до кратних 5 градусам із запасом
      chartMinY = (minTemp / 5).floor() * 5.0 - 5.0;
      chartMaxY = (maxTemp / 5).ceil() * 5.0 + 5.0;

      lines = [
        _buildLineData(_allData, (m) => m.temperatureOut, Colors.blue),
        _buildLineData(_allData, (m) => m.temperatureIn, Colors.green),
      ];
    } else {
      // --- ЛОГІКА ДЛЯ L & H (Вологість та Яскравість) ---
      chartMinY = 0;
      chartMaxY = 105; // 100% + невеликий запас зверху

      lines = [
        _buildLineData(_allData, (m) => m.humidityOut, Colors.deepPurple),
        _buildLineData(_allData, (m) => m.humidityIn, Colors.brown),
        _buildLineData(_allData, (m) => m.luminanceOut, Colors.red),
        _buildLineData(_allData, (m) => m.luminanceIn, Colors.orange),
      ];
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: chartMinY,
        maxY: chartMaxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, res) {
            if (res == null || res.lineBarSpots == null || res.lineBarSpots!.isEmpty) {
              setState(() { _touchedBarIndex = -1; _touchedGroupIndex = -1; });
              return;
            }
            setState(() {
              _touchedBarIndex = res.lineBarSpots!.first.barIndex;
              _touchedGroupIndex = res.lineBarSpots!.first.spotIndex;
            });
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.grey.withValues(alpha: 0.4), strokeWidth: 2),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3.0, color: Colors.white, strokeColor: barData.color ?? Colors.black, strokeWidth: 1.5,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (spots) => spots.map((s) => null).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 3600000,
          checkToShowVerticalLine: (v) => DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true).hour % 4 == 0,
          getDrawingVerticalLine: (v) {
            final date = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
            return date.hour == 0 ? FlLine(color: Colors.black, strokeWidth: 1.5) : FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 0.5);
          },
          // Горизонтальна сітка кожні 5 градусів або 20 відсотків
          horizontalInterval: widget.isTemperature ? 5 : 20,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: widget.isTemperature ? 5 : 20,
                  getTitlesWidget: (v, m) {
                    if (!widget.isTemperature && v > 100) return const SizedBox();
                    String unit = widget.isTemperature ? "°" : "%";
                    return Text("${v.toInt()}$unit", style: const TextStyle(fontSize: 8));
                  }
              )
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3600000,
              getTitlesWidget: (v, m) {
                final date = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
                if ((v - maxX).abs() < 1000) return SideTitleWidget(meta: m, child: const Text("24:00", style: TextStyle(fontSize: 8)));
                if (date.minute != 0 || date.hour % 4 != 0) return const SizedBox();
                if (date.hour == 0 && date.minute == 0) {
                  return SideTitleWidget(
                    meta: m,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(4), color: Colors.white),
                      child: Text(DateFormat('dd.MM').format(date), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                return SideTitleWidget(meta: m, child: Text("${date.hour}:00", style: const TextStyle(fontSize: 8)));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
        lineBarsData: lines,
      ),
    );
  }
}