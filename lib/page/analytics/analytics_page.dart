import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../data_home/data_location_type.dart';
import 'analitic_model.dart';
import 'analytic_enums.dart';
import 'anaytic_connect_service.dart';

class AnalyticsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsPage({super.key, required this.location});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  ViewMode _currentMode = ViewMode.day;

  // Офсет для Києва (зимовий час)
  Duration get inverterOffset => const Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<AnalyticModel> rawData = [];
      switch (_currentMode) {
        case ViewMode.day:
          rawData = await _service.getAnalyticDay(date: _selectedDate, location: widget.location);
          break;
        case ViewMode.month:
          rawData = await _service.getAnalyticMonth(date: _selectedDate, location: widget.location);
          break;
        case ViewMode.year:
          rawData = await _service.getAnalyticYear(year: _selectedDate.year, location: widget.location);
          break;
        case ViewMode.period:
          rawData = await _service.getAnalyticDays(dateStart: _startDate, dateFinish: _endDate, location: widget.location);
          break;
      }

      if (rawData.isNotEmpty) {
        rawData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (mounted) setState(() => _allData = rawData);
      } else {
        if (mounted) setState(() => _allData = []);
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // СПІЛЬНИЙ ШАБЛОН ДЛЯ ОБОХ ГРАФІКІВ
  Widget _buildBaseChart({
    required List<AnalyticModel> data,
    required double maxY,
    required List<LineChartBarData> lines,
    required bool isLandscape,
    required String yAxisLabel,
  }) {
    double minX;
    double maxX;
    double interval;

    if (data.isEmpty) {
      minX = 0;
      maxX = 1;
      interval = 1;
    } else {
      if (_currentMode == ViewMode.period) {
        // 1. ПЕРІОД: від 00:00 першого дня до 23:59 останнього дня
        final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0);
        final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

        minX = start.millisecondsSinceEpoch.toDouble();
        maxX = end.millisecondsSinceEpoch.toDouble();

        // Якщо днів багато, ставимо мітки раз на добу (86.4 млн мс)
        double dayCount = (maxX - minX) / 86400000;
        interval = dayCount > 1 ? 86400000 : 3600000 * 4;
      } else {
        // 2. ОДИН ДЕНЬ: суворо від 00:00 до 23:59 обраної дати
        minX = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0).millisecondsSinceEpoch.toDouble();
        maxX = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59).millisecondsSinceEpoch.toDouble();
        interval = 3600000 * 4; // Мітки кожні 4 години
      }
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        // clipData обрізає лінії, що виходять за межі maxY (важливо для піків 9кВт)
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.9),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            // Встановлюємо великий відступ або фіксовану логіку,
            // щоб тултіп завжди був зверху
            tooltipMargin: 0,
            // Цей параметр змушує тултіп ігнорувати висоту конкретної точки
            // і орієнтуватися на межі контейнера
            maxContentWidth: 150,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null;
                final m = data[spot.spotIndex];
                final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).add(inverterOffset);

                String timeLabel = _currentMode == ViewMode.period
                    ? DateFormat('dd.MM HH:mm').format(date)
                    : DateFormat('HH:mm').format(date);

                return LineTooltipItem(
                  '$timeLabel\n',
                  const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  // Використовуємо textAlign для вирівнювання тексту всередині
                  children: [
                    _span("Solar: ", "${(m.solarPower / 1000.0).toStringAsFixed(2)} kW\n", Colors.blue),
                    _span("Home: ", "${(m.homePower / 1000.0).toStringAsFixed(2)} kW\n", Colors.red),
                    _span("SOC: ", "${m.bmsSoc.toStringAsFixed(1)} %\n", Colors.green),
                    _span("Grid: ", "${(m.gridPower / 1000.0).toStringAsFixed(2)} kW", Colors.orange),
                  ],
                );
              }).toList();
            },
          ),
          // Налаштування "лінії-покажчика" (vertical line)
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.grey.withValues(alpha: 0.5), strokeWidth: 1),
                FlDotData(show: true), // Точка на самій лінії все одно залишиться
              );
            }).toList();
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true).add(inverterOffset);

                // Якщо період — показуємо "День.Місяць", якщо день — "Година:00"
                String text = (_currentMode == ViewMode.period && date.hour == 0)
                    ? "${date.day}.${date.month}"
                    : "${date.hour}:00";

                return SideTitleWidget(meta: meta, child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.grey)));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (v, m) => Text(v.toStringAsFixed(v < 1 ? 2 : 1), style: const TextStyle(fontSize: 8))
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
            show: true,
            verticalInterval: interval,
            getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 0.5)
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lines,
      ),
    );
  }

  // РОЗДІЛЕННЯ ГРАФІКІВ ПО КАТЕГОРІЯХ
  Widget _buildCombinedCharts(List<AnalyticModel> data, bool isLandscape) {
    if (data.isEmpty) return const Center(child: Text("Дані відсутні"));

    // Шукаємо динамічний максимум для kW
    double maxPowerkW = 0.5;
    for (var m in data) {
      if (m.solarPower / 1000.0 > maxPowerkW) maxPowerkW = m.solarPower / 1000.0;
      if (m.homePower / 1000.0 > maxPowerkW) maxPowerkW = m.homePower / 1000.0;
      if (m.gridPower / 1000.0 > maxPowerkW) maxPowerkW = m.gridPower / 1000.0;
    }
    double powerMaxY = maxPowerkW * 1.15;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.only(top: 20, left: 10, right: 15),
            child: _buildBaseChart(
              data: data,
              isLandscape: isLandscape,
              maxY: powerMaxY,
              yAxisLabel: "kW",
              lines: [
                _buildLineData(data, (m) => m.solarPower / 1000.0, Colors.blue, hasArea: true),
                _buildLineData(data, (m) => m.homePower / 1000.0, Colors.red),
                _buildLineData(data, (m) => m.gridPower / 1000.0, Colors.orange),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 15),
            child: _buildBaseChart(
              data: data,
              isLandscape: isLandscape,
              maxY: 105,
              yAxisLabel: "%",
              lines: [
                _buildLineData(data, (m) => m.bmsSoc, Colors.green, hasArea: true, opacity: 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLineData(List<AnalyticModel> data, double Function(AnalyticModel) getValue, Color color, {bool hasArea = false, double opacity = 0.1}) {
    return LineChartBarData(
      spots: data.map((m) {
        double xValue;
        if (_currentMode == ViewMode.month) {
          xValue = DateTime.fromMillisecondsSinceEpoch(m.timestamp).day.toDouble();
        } else if (_currentMode == ViewMode.year) {
          xValue = DateTime.fromMillisecondsSinceEpoch(m.timestamp).month.toDouble();
        } else {
          xValue = m.timestamp.toDouble();
        }
        return FlSpot(xValue, getValue(m));
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: hasArea, color: color.withValues(alpha: opacity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.location.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(
              _currentMode == ViewMode.day
                  ? DateFormat('dd.MM.yyyy').format(_selectedDate)
                  : _currentMode == ViewMode.month
                  ? DateFormat('MMMM yyyy', 'uk').format(_selectedDate)
                  : _currentMode == ViewMode.year
                  ? "Рік: ${_selectedDate.year}"
                  : "${DateFormat('dd.MM').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}",
              style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today, size: 20, color: Colors.black), onPressed: _pickDate),
          PopupMenuButton<ViewMode>(
            icon: const Icon(Icons.tune, size: 20, color: Colors.black),
            onSelected: (val) async {
              switch (val) {
                case ViewMode.period: await _pickPeriod(); break;
                case ViewMode.month: await _pickMonth(); break;
                case ViewMode.year: await _pickYear(); break;
                default: break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: ViewMode.month, child: Text("Місяць")),
              const PopupMenuItem(value: ViewMode.year, child: Text("Рік")),
              const PopupMenuItem(value: ViewMode.period, child: Text("Період")),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 20, color: Colors.black), onPressed: _fetchData),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_currentMode == ViewMode.month || _currentMode == ViewMode.year)
                  ? _buildBarChart(_allData)
                  : _buildCombinedCharts(_allData, isLandscape),
            ),
            if (!isLandscape && _allData.isNotEmpty) _buildStats(_allData.last),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(AnalyticModel last) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem("Solar Daily", "${last.solarDailyPower.toStringAsFixed(2)} kWh", Colors.orange),
            _statItem("Home Daily", "${last.homeDailyPower.toStringAsFixed(2)} kWh", Colors.red),
            _statItem("BMS Daily Discharge", "${last.bmsDailyDischarge.toStringAsFixed(2)} kWh", Colors.red),
            _statItem("BMS Daily Charge", "${last.bmsDailyCharge.toStringAsFixed(2)} kWh", Colors.blue),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem("Grid Daily Day", "${last.gridDailyDayPower.toStringAsFixed(2)} kWh", Colors.orange),
            _statItem("Grid Daily Night", "${last.gridDailyNightPower.toStringAsFixed(2)} kWh", Colors.blue),
            _statItem("Grid Daily Total", "${last.gridDailyTotalPower.toStringAsFixed(2)} kWh", Colors.deepPurple),
          ]),
        ],
      ),
    );
  }

  Widget _statItem(String l, String v, Color c) => Column(children: [Text(l, style: TextStyle(color: c, fontSize: 9)), Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]);
  TextSpan _span(String label, String val, Color col) => TextSpan(text: label, style: const TextStyle(color: Colors.black54, fontSize: 9), children: [TextSpan(text: val, style: TextStyle(color: col, fontWeight: FontWeight.bold))]);

  void _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) { setState(() { _selectedDate = d; _currentMode = ViewMode.day; }); _fetchData(); }
  }

  Future<void> _pickPeriod() async {
    final DateTimeRange? r = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
    if (r != null) { setState(() { _startDate = r.start; _endDate = r.end; _currentMode = ViewMode.period; }); _fetchData(); }
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDatePickerMode: DatePickerMode.year);
    if (picked != null) { setState(() { _selectedDate = DateTime(picked.year, picked.month, 1); _currentMode = ViewMode.month; }); _fetchData(); }
  }

  Future<void> _pickYear() async {
    int tempYear = _selectedDate.year;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Оберіть рік"),
        content: SizedBox(width: 300, height: 300, child: YearPicker(firstDate: DateTime(2020), lastDate: DateTime(2030), selectedDate: _selectedDate, onChanged: (dt) { tempYear = dt.year; Navigator.pop(context); })),
      ),
    );
    setState(() { _selectedDate = DateTime(tempYear, 1, 1); _currentMode = ViewMode.year; }); _fetchData();
  }

  Widget _buildBarChart(List<AnalyticModel> rawData) {
    if (rawData.isEmpty) return const Center(child: Text("Дані відсутні"));
    Map<int, AnalyticModel> grouped = {};
    for (var m in rawData) {
      final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).add(inverterOffset);
      int key = _currentMode == ViewMode.month ? date.day : date.month;
      if (!grouped.containsKey(key) || m.solarDailyPower > grouped[key]!.solarDailyPower) { grouped[key] = m; }
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return Container(
      padding: const EdgeInsets.only(top: 25, left: 10, right: 15, bottom: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround, maxY: 125,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
              if (_currentMode == ViewMode.year) {
                const mo = ['', 'С', 'Л', 'Б', 'К', 'Т', 'Ч', 'Л', 'С', 'В', 'Ж', 'Л', 'Г'];
                return Text(mo[v.toInt() % 13], style: const TextStyle(fontSize: 10));
              }
              return (v % 5 == 0 || v == 1) ? Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)) : const SizedBox();
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: sortedKeys.map((k) {
            final m = grouped[k]!;
            return BarChartGroupData(x: k, barRods: [
              BarChartRodData(toY: m.solarDailyPower, color: Colors.blue, width: 8),
              BarChartRodData(toY: m.homeDailyPower, color: Colors.red, width: 8),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}