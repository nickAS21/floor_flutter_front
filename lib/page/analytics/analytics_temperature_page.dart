import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data_home/data_location_type.dart';
import 'analitic_model.dart';
import 'anaytic_connect_service.dart';

class AnalyticsTemperaturePage extends StatefulWidget {
  final LocationType location;
  const AnalyticsTemperaturePage({super.key, required this.location});

  @override
  State<AnalyticsTemperaturePage> createState() => _AnalyticsTemperaturePageState();
}

class _AnalyticsTemperaturePageState extends State<AnalyticsTemperaturePage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  int _touchedBarIndex = -1;
  int _touchedGroupIndex = -1;
  double tempRatio = 2.0;

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

  LineChartBarData _buildLineData(List<AnalyticModel> data, double Function(AnalyticModel) getValue, Color color, int barIndex) {
    final bool isTouched = _touchedBarIndex == barIndex;

    return LineChartBarData(
      spots: data.map((m) => FlSpot(m.timestamp.toDouble(), getValue(m))).toList(),
      isCurved: true,
      curveSmoothness: 0.15, // Мала плавність, щоб не було "хвиль" там, де дані різко стрибають
      color: isTouched ? color : color.withValues(alpha: 0.7), // Неактивні лінії трохи блідіші

      // ОСЬ ТУТ ТОНКІ ЛІНІЇ:
      barWidth: isTouched ? 1.5 : 1.2, // У Power десь 1.2-1.5

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
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchData),
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
    final index = (_touchedGroupIndex == -1 || _touchedGroupIndex >= _allData.length) ? _allData.length - 1 : _touchedGroupIndex;
    final d = _allData[index];
    final timeStr = DateFormat('dd.MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(d.timestamp, isUtc: true));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Time:$timeStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              _statText("Out T:", d.temperatureOut, "°", Colors.blueAccent),      // Насичений синій
              _statText("H:", d.humidityOut, "%", Colors.teal),                 // Хвиля
              _statText("L:", d.luminanceOut, "%", Colors.orangeAccent),        // Помаранчевий
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 35),
              _statText("In T:", d.temperatureIn, "°", Colors.deepPurpleAccent), // Фіолетовий (замість світло-синього)
              _statText("H:", d.humidityIn, "%", Colors.limeAccent[700]!),       // Салатовий (замість зеленого)
              _statText("L:", d.luminanceIn, "%", Colors.pinkAccent),            // Рожевий/Маджента (замість жовтого)
            ],
          ),
        ],
      ),
    );
  }

  Widget _statText(String label, double val, String unit, Color col) {
    return RichText(text: TextSpan(style: const TextStyle(fontSize: 10, color: Colors.black), children: [
      TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w300)),
      TextSpan(text: " ${val.toStringAsFixed(1)}$unit", style: TextStyle(fontWeight: FontWeight.bold, color: col)),
    ]));
  }

  Widget _buildMainChart() {
    if (_allData.isEmpty) return const Center(child: Text("Немає даних"));

    var firstDate = DateTime.fromMillisecondsSinceEpoch(_allData.first.timestamp, isUtc: true);
    double minX = DateTime.utc(firstDate.year, firstDate.month, firstDate.day).millisecondsSinceEpoch.toDouble();
    double maxX = DateTime.utc(firstDate.year, firstDate.month, firstDate.day + 1).millisecondsSinceEpoch.toDouble();

    // --- ЛОГІКА ЯК У POWER (Динамічний масштаб для температури) ---
    double maxTemp = 0.5; // Твій "запобіжник" близький до нуля
    for (var m in _allData) {
      if (m.temperatureOut > maxTemp) maxTemp = m.temperatureOut;
      if (m.temperatureIn > maxTemp) maxTemp = m.temperatureIn;
    }
    double tempMaxY = maxTemp * 1.15; // Запас 15% зверху
    double ratio = 100 / tempMaxY;    // Коефіцієнт підтягування до шкали 100
    // --------------------------------------------------------------

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: 105, // База 100 + невеликий запас для %
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
          horizontalInterval: 20,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: 20,
                  getTitlesWidget: (v, m) {
                    if (v > 100) return const SizedBox();
                    // Зворотний перерахунок у градуси (як у Power для кВт)
                    return Text("${(v * tempMaxY / 100).toStringAsFixed(1)}°", style: const TextStyle(fontSize: 8));
                  }
              )
          ),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: 20,
                  getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 8, color: Colors.teal))
              )
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
        lineBarsData: [
          // ТЕМПЕРАТУРА: множимо на ratio (Out - Синій, In - Фіолетовий)
          _buildLineData(_allData, (m) => m.temperatureOut * ratio, Colors.blueAccent, 0),
          _buildLineData(_allData, (m) => m.temperatureIn * ratio, Colors.deepPurpleAccent, 1),

          // ВІДСОТКИ: малюємо 1 до 1 (Out - Teal, In - Салатовий)
          _buildLineData(_allData, (m) => m.humidityOut, Colors.teal, 2),
          _buildLineData(_allData, (m) => m.humidityIn, Colors.limeAccent[700]!, 3),

          // ЯСКРАВІСТЬ: (Out - Помаранчевий, In - Рожевий)
          _buildLineData(_allData, (m) => m.luminanceOut, Colors.orangeAccent, 4),
          _buildLineData(_allData, (m) => m.luminanceIn, Colors.pinkAccent, 5),
        ],
      ),
    );
  }
}