import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void didUpdateWidget(AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      setState(() => _isLoading = true);
      _fetchData();
    }
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
    required double powerMaxY,
    required List<LineChartBarData> lines,
    required bool isLandscape,
    required String yAxisLabel,
  }) {
    double minX;
    double maxX;
    double interval = 3600000 * 4;

    if (data.isEmpty) {
      minX = 0; maxX = 1;
    } else {
      // Час беремо як він є — бек вже все порахував
      if (_currentMode == ViewMode.period) {
        // Використовуємо .utc(), щоб межі графіка збігалися з UTC-таймстампами бека
        minX = DateTime.utc(_startDate.year, _startDate.month, _startDate.day, 0, 0).millisecondsSinceEpoch.toDouble();
        maxX = DateTime.utc(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59).millisecondsSinceEpoch.toDouble();
      } else {
        minX = DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0).millisecondsSinceEpoch.toDouble();
        maxX = DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59).millisecondsSinceEpoch.toDouble();
      }
    }

    return LineChart(
      LineChartData(
        minX: minX, maxX: maxX, minY: 0, maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(4),
            tooltipBorder: const BorderSide(color: Colors.black12, width: 1),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null;
                final m = data[spot.spotIndex];
                // Чистий локальний час з бека
                final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: false);

                return LineTooltipItem(
                  "${DateFormat('dd.MM HH:mm').format(date)}\n",
                  const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: "Solar: ${(m.solarPower / 1000.0).toStringAsFixed(2)} kW\n", style: const TextStyle(color: Colors.blue, fontSize: 9)),
                    TextSpan(text: "Home: ${(m.homePower / 1000.0).toStringAsFixed(2)} kW\n", style: const TextStyle(color: Colors.red, fontSize: 9)),
                    TextSpan(text: "Grid Day: ${m.gridDailyDayPower.toStringAsFixed(2)} kWh\n", style: const TextStyle(color: Colors.orange, fontSize: 9)),
                    TextSpan(text: "Grid Night: ${m.gridDailyNightPower.toStringAsFixed(2)} kWh\n", style: const TextStyle(color: Colors.indigo, fontSize: 9)),
                    TextSpan(text: "SOC: ${m.bmsSoc.toInt()}%", style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((index) => TouchedSpotIndicatorData(
            FlLine(color: Colors.black12, strokeWidth: 1),
            const FlDotData(show: false),
          )).toList(),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v, m) {
            if (v > 100) return const SizedBox();
            return Text((v * powerMaxY / 100).toStringAsFixed(1), style: const TextStyle(fontSize: 8));
          })),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) {
            if (v % 50 == 0 || v == 100) return Text("${v.toInt()}%", style: const TextStyle(fontSize: 8, color: Colors.green));
            return const SizedBox();
          })),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (v, m) {
                final date = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: false);
                bool isMidnight = date.hour == 0 && date.minute == 0;
                bool isEdge = (v - m.min).abs() < 1000 || (v - m.max).abs() < 1000;

                // Малюємо рамку тільки один раз, щоб не було накладки на 11.03
                if (isMidnight || (isEdge && !isMidnight)) {
                  return SideTitleWidget(
                    meta: m,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: Text(DateFormat('dd.MM').format(date),
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  );
                }
                return SideTitleWidget(meta: m, child: Text("${date.hour}:00", style: const TextStyle(fontSize: 8, color: Colors.grey)));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: interval,
          horizontalInterval: 50,
          getDrawingVerticalLine: (value) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: false);
            if (date.hour == 0 && date.minute == 0) {
              return FlLine(color: Colors.black, strokeWidth: 1.5); // Чітко о 00:00
            }
            return FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 0.5, dashArray: [4, 4]);
          },
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
        lineBarsData: lines,
      ),
    );
  }

  // РОЗДІЛЕННЯ ГРАФІКІВ ПО КАТЕГОРІЯХ
  Widget _buildCombinedCharts(List<AnalyticModel> data, bool isLandscape) {
    if (data.isEmpty) return const Center(child: Text("Дані відсутні"));

    double maxPowerkW = 0.5;
    for (var m in data) {
      if (m.solarPower / 1000.0 > maxPowerkW) maxPowerkW = m.solarPower / 1000.0;
      if (m.homePower / 1000.0 > maxPowerkW) maxPowerkW = m.homePower / 1000.0;
    }
    double powerMaxY = maxPowerkW * 1.15;
    double ratio = 100 / powerMaxY;

    double chartWidth = _currentMode == ViewMode.period
        ? (_endDate.difference(_startDate).inDays + 1) * 1000.0
        : (isLandscape ? 1500 : 1000);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("kW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Text("%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar( // ДОДАЄМО ВИДИМИЙ СКРОЛ
            controller: _horizontalScroll,
            thumbVisibility: true, // Смужка буде завжди видимою
            trackVisibility: true, // Доріжка скролу теж видима
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: chartWidth, // Наприклад, 2000 пікселів для 2 днів
                padding: const EdgeInsets.only(left: 10, right: 30, bottom: 15), // Місце для смужки скролу
                child: _buildBaseChart(
                  data: data,
                  isLandscape: isLandscape,
                  maxY: 115,
                  powerMaxY: powerMaxY,
                  yAxisLabel: "kW / %",
                  lines: [
                    _buildLineData(data, (m) => m.bmsSoc, Colors.green, hasArea: true, opacity: 0.1), // SOC
                    _buildLineData(data, (m) => (m.solarPower / 1000.0) * ratio, Colors.blue, hasArea: true, opacity: 0.2), // Solar
                    _buildLineData(data, (m) => (m.homePower / 1000.0) * ratio, Colors.red), // Home
                    _buildLineData(data, (m) => (m.gridDailyDayPower / 1000.0) * ratio, Colors.orange), // Grid Day
                    _buildLineData(data, (m) => (m.gridDailyNightPower / 1000.0) * ratio, Colors.indigo), // Grid Night
                  ],
                ),
              ),
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
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20, color: Colors.black),
            onPressed: _importExcel, // Викликає ваш існуючий метод
            tooltip: "Імпорт даних з Excel/XML",
          ),
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
    double minX = 1;
    double maxX;
    double interval = 1;

    if (_currentMode == ViewMode.year) {
      maxX = 12;
    } else {
      maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day.toDouble();
    }

    Map<int, AnalyticModel> grouped = {};
    for (var m in rawData) {
      // Жодних add(inverterOffset), тільки чистий UTC
      final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: false);
      int key = _currentMode == ViewMode.month ? date.day : date.month;
      if (!grouped.containsKey(key) || m.solarDailyPower > grouped[key]!.solarDailyPower) {
        grouped[key] = m;
      }
    }

    // Розрахунок максимуму залишаємо як був
    double maxVal = 1.0;
    for (var m in grouped.values) {
      if (m.solarDailyPower > maxVal) maxVal = m.solarDailyPower;
      if (m.homeDailyPower > maxVal) maxVal = m.homeDailyPower;
    }
    double chartMaxY = maxVal * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, top: 10),
          child: Text("kWh", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 15, left: 10, right: 15, bottom: 10),
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMaxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.white,
                    tooltipBorder: const BorderSide(color: Colors.black12, width: 1),
                    tooltipBorderRadius: BorderRadius.circular(4),
                    maxContentWidth: 150,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (rodIndex != 0) return null;
                      final m = grouped[group.x.toInt()];
                      if (m == null) return null;

                      return BarTooltipItem(
                        "${_currentMode == ViewMode.month ? 'День' : 'Місяць'} ${group.x}\n",
                        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        children: [
                          _barSpan("Solar: ", "${m.solarDailyPower.toStringAsFixed(2)} kWh\n", Colors.blue),
                          _barSpan("Home: ", "${m.homeDailyPower.toStringAsFixed(2)} kWh\n", Colors.red),
                          _barSpan("Grid Total: ", "${m.gridDailyTotalPower.toStringAsFixed(2)} kWh\n", Colors.deepPurple),
                          _barSpan("Grid Day: ", "${m.gridDailyDayPower.toStringAsFixed(2)} kWh\n", Colors.orange),
                          _barSpan("Grid Night: ", "${m.gridDailyNightPower.toStringAsFixed(2)} kWh", Colors.indigo),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 8)),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, m) {
                        int val = v.toInt();
                        if (val < minX || val > maxX) return const SizedBox();
                        if (_currentMode == ViewMode.year) {
                          return Text(val.toString(), style: const TextStyle(fontSize: 8));
                        } else {
                          if (val == 1 || val == maxX || val % 5 == 0) {
                            return Text(val.toString(), style: const TextStyle(fontSize: 8));
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY > 0 ? chartMaxY / 5 : 1,
                  // ПРАВКА: Використовуємо alpha
                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(maxX.toInt(), (index) {
                  int key = index + 1;
                  final m = grouped[key];
                  return BarChartGroupData(
                    x: key,
                    barRods: [
                      BarChartRodData(toY: m?.solarDailyPower ?? 0, color: Colors.blue, width: 6, borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: m?.homeDailyPower ?? 0, color: Colors.red, width: 6, borderRadius: BorderRadius.circular(2)),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _importExcel() async {
    // Вибір файлу .xlsx
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        File file = File(result.files.single.path!);
        var bytes = await file.readAsBytes();

        // 1. Парсимо Excel у список моделей
        List<AnalyticModel> detailedPoints = _service.processExcelData(
          bytes: bytes,
          location: widget.location,);

        if (detailedPoints.isNotEmpty) {
          // 2. Відправляємо POST запит на сервер (імпорт XML/Data)
          bool success = await _service.importXmlsData(detailedPoints);

          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Імпорт завершено успішно"), backgroundColor: Colors.green),
              );
            }
            // Оновлюємо графік після імпорту
            await _fetchData();
          }
        }
      } catch (e) {
        debugPrint("Import error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Помилка імпорту: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  TextSpan _barSpan(String label, String val, Color col) {
    return TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.normal),
      children: [
        TextSpan(text: val, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }
}