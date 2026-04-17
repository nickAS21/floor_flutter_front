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

  int _touchedGroupIndex = -1;
  final ScrollController _tempScrollController = ScrollController();

  @override
  void dispose() {
    _tempScrollController.dispose();
    super.dispose();
  }

  @override
  void refresh() {
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
    if (oldWidget.location != widget.location) {
      _fetchData();
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

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Оберіть дату',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // РЯДОК 1: КЕРУВАННЯ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.location.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd.MM.yyyy').format(_selectedDate), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: _pickDate),
                  buildScaleSelector(),
                ],
              ),
            ),
            const Divider(height: 1),

            // РЯДОК 2: ПОКАЗНИКИ (Time зліва, Дані парами справа)
            _buildCombinedChartsHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Зліва для Температури (In/Out)
                  Text(
                      widget.isTemperature ? "°C" : "%",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isTemperature ? Colors.blue : Colors.deepPurple)
                  ),
                  // Справа (якщо є друга шкала, або просто для симетрії)
                  Text(
                      widget.isTemperature ? "°C" : "%",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
                  ),
                ],
              ),
            ),

            // ГРАФІК
            Expanded(
              child: _buildMainChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedChartsHeader() {
    if (_allData.isEmpty) return const SizedBox.shrink();

    final index = (_touchedGroupIndex == -1 || _touchedGroupIndex >= _allData.length)
        ? _allData.length - 1
        : _touchedGroupIndex;
    final last = _allData[index];

    final timeStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(last.timestamp, isUtc: true));

    Widget statRow(String label, dynamic val, Color col, [String unit = ""]) {
      String display;
      if (val is num) {
        // Температура (малі числа) - 1 знак, Потужність (великі) - 2 знаки
        display = val.abs() < 20 ? val.toStringAsFixed(1) : val.toStringAsFixed(2);
      } else {
        display = val.toString();
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Назва поля (чорна, тонка)
          Text("$label: ", style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w400)),

          // Сама цифра (кольорова, жирна)
          Text(display, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),

          // Одиниця виміру (нейтральна, як і назва поля)
          if (unit.isNotEmpty)
            Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w400)),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Час (Time)
          Text("Time: $timeStr", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),

          // Дані в один рядок зі скролом
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.isTemperature) ...[
                    statRow("In T", last.temperatureIn.toStringAsFixed(1), Colors.green, "°"),
                    const SizedBox(width: 12),
                    statRow("Out T", last.temperatureOut.toStringAsFixed(1),
                        last.temperatureOut < 0 ? Colors.red : Colors.blue, "°"),
                  ] else ...[
                    statRow("In H", last.humidityIn.toInt(), Colors.brown, "%"),
                    const SizedBox(width: 12),
                    statRow("Out H", last.humidityOut.toInt(), Colors.deepPurple, "%"),
                    const SizedBox(width: 12),
                    statRow("In L", last.luminanceIn.toInt(), Colors.orange, "%"),
                    const SizedBox(width: 12),
                    statRow("Out L", last.luminanceOut.toInt(), Colors.red, "%"),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    if (_allData.isEmpty) return const Center(child: Text("Немає даних"));

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    double baseWidth = isLandscape ? screenWidth * 1.5 : screenWidth;
    double chartWidth = baseWidth * chartScale;

    // 1. Фактичні межі даних, які прийшли з беку (вже відсортовані)
    double actualMinX = _allData.first.timestamp.toDouble();
    double actualMaxX = _allData.last.timestamp.toDouble();

// 2. Межі обраної доби (UTC 00:00 - 24:00)
    final DateTime dayStart = DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    double targetMinX = dayStart.millisecondsSinceEpoch.toDouble();
    double targetMaxX = dayStart.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();

    // 3. Гнучкий розрахунок:
    // Якщо є записи за вчора (actualMinX менше 00:00 сьогодні) — розширюємо сітку вліво
    double minX = actualMinX < targetMinX ? actualMinX : targetMinX;

    // Якщо дані вилазять за межі доби (що навряд чи, але для симетрії) — розширюємо вправо
    double maxX = actualMaxX > targetMaxX ? actualMaxX : targetMaxX;

    double chartMinY;
    double chartMaxY;
    List<LineChartBarData> lines = [];

    if (widget.isTemperature) {
      double minTemp = 100.0;
      double maxTemp = -100.0;

      // Знаходимо реальні межі саме значень Out T для градієнта
      double outMin = 100.0;
      double outMax = -100.0;

      for (var m in _allData) {
        if (m.temperatureOut < minTemp) minTemp = m.temperatureOut;
        if (m.temperatureIn < minTemp) minTemp = m.temperatureIn;
        if (m.temperatureOut > maxTemp) maxTemp = m.temperatureOut;
        if (m.temperatureIn > maxTemp) maxTemp = m.temperatureIn;

        // Окремо для Out лінії
        if (m.temperatureOut < outMin) outMin = m.temperatureOut;
        if (m.temperatureOut > outMax) outMax = m.temperatureOut;
      }

      chartMinY = (minTemp / 5).floor() * 5.0 - 5.0;
      chartMaxY = (maxTemp / 5).ceil() * 5.0 + 5.0;

      // КРИТИЧНЕ ВИПРАВЛЕННЯ:
      // Градієнт LinearGradient у LineChartBarData малюється від outMin до outMax лінії.
      // Нам потрібно знайти, де 0.0 всередині діапазону [outMin, outMax]
      double outRange = outMax - outMin;
      double zeroPos;

      if (outMax <= 0) {
        zeroPos = 1.0; // Вся лінія нижче нуля (червона)
      } else if (outMin >= 0) {
        zeroPos = 0.0; // Вся лінія вище нуля (синя)
      } else {
        // Рахуємо відсоток, де знаходиться нуль
        zeroPos = (0.0 - outMin) / outRange;
      }

      zeroPos = zeroPos.clamp(0.0, 1.0);
      const double delta = 0.001;

      lines = [
        _buildLineData(_allData, (m) => m.temperatureIn, Colors.green),
        _buildLineData(
          _allData,
              (m) => m.temperatureOut,
          null,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.red,
              Colors.red,
              Colors.blue,
              Colors.blue,
            ],
            stops: [
              0.0,
              (zeroPos - delta).clamp(0.0, 1.0),
              (zeroPos + delta).clamp(0.0, 1.0),
              1.0
            ],
          ),
        ),
      ];
    } else {
      chartMinY = 0;
      chartMaxY = 105;
      lines = [
        _buildLineData(_allData, (m) => m.humidityOut, Colors.deepPurple),
        _buildLineData(_allData, (m) => m.humidityIn, Colors.brown),
        _buildLineData(_allData, (m) => m.luminanceOut, Colors.red),
        _buildLineData(_allData, (m) => m.luminanceIn, Colors.orange),
      ];
    }

    return Scrollbar(
      controller: _tempScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _tempScrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          width: chartWidth,
          padding: const EdgeInsets.only(left: 10, right: 30, bottom: 15),
          child: LineChart(
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
                    setState(() { _touchedGroupIndex = -1; });
                    return;
                  }
                  setState(() {
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
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(
      List<AnalyticModel> data,
      double Function(AnalyticModel) getValue,
      Color? color,
      {Gradient? gradient}
      ) {
    return LineChartBarData(
      spots: data.map((m) => FlSpot(m.timestamp.toDouble(), getValue(m))).toList(),
      isCurved: true,
      color: color,
      gradient: gradient, // Додано підтримку градієнта
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        // Прозорий фон під лінією
        color: (color ?? Colors.blue).withValues(alpha: 0.1),
      ),
    );
  }
}