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

  Widget _buildChart(List<AnalyticModel> data, bool isLandscape) {
    if (data.isEmpty) return const Center(child: Text("Дані відсутні"));

    double minX;
    double maxX;
    double interval;

    // Визначаємо межі та інтервали сітки залежно від режиму
    if (_currentMode == ViewMode.period && data.isNotEmpty) {
      minX = data.first.timestamp.toDouble();
      maxX = data.last.timestamp.toDouble();
      interval = (maxX - minX) / 6; // Розподіляємо на 6 частин для періоду
    } else if (_currentMode == ViewMode.month) {
      minX = 1;
      maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day.toDouble();
      interval = 5; // Кожні 5 днів
    } else if (_currentMode == ViewMode.year) {
      minX = 1;
      maxX = 12;
      interval = 1; // Кожен місяць
    } else {
      // Режим ДЕНЬ (ваш стандартний)
      minX = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0)
          .millisecondsSinceEpoch.toDouble();
      maxX = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59)
          .millisecondsSinceEpoch.toDouble();
      interval = 3600000 * 4; // 4 години
    }

    return Container(
      padding: EdgeInsets.only(top: 25, left: 10, right: isLandscape ? 85 : 15, bottom: 10),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 125,
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.white.withOpacity(0.9),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipBorder: const BorderSide(color: Colors.transparent),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 10,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  if (spot.barIndex != 0) return null;
                  if (spot.spotIndex >= data.length) return null;

                  final m = data[spot.spotIndex];
                  final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).add(inverterOffset);

                  // Форматуємо час: додаємо дату лише для ПЕРІОДУ
                  String timeLabel = _currentMode == ViewMode.period
                      ? DateFormat('dd.03 HH:mm').format(date)
                      : DateFormat('HH:mm').format(date);

                  return LineTooltipItem(
                    '$timeLabel\n',
                    const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    children: [
                      _span("Solar: ", "${m.solarPower.toInt()} W\n", Colors.blue),
                      _span("Home: ", "${m.homePower.toInt()} W\n", Colors.red),
                      _span("SOC: ", "${m.bmsSoc.toInt()} %\n", Colors.green),
                      _span("Grid: ", "${m.gridPower.toInt()} W", Colors.orange),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.grey.withOpacity(0.5), strokeWidth: 1),
                  FlDotData(show: true),
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
                  // Логіка підписів для різних режимів
                  if (_currentMode == ViewMode.month) {
                    if (value % 5 == 0 || value == 1) {
                      return SideTitleWidget(meta: meta, child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 8, color: Colors.grey)));
                    }
                  } else if (_currentMode == ViewMode.year) {
                    const months = ['', 'Січ', 'Лют', 'Бер', 'Квіт', 'Трав', 'Черв', 'Лип', 'Серп', 'Вер', 'Жов', 'Лис', 'Груд'];
                    if (value >= 1 && value <= 12) {
                      return SideTitleWidget(meta: meta, child: Text(months[value.toInt()], style: const TextStyle(fontSize: 8, color: Colors.grey)));
                    }
                  } else {
                    // Для ДНЯ та ПЕРІОДУ використовуємо час
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true).add(inverterOffset);
                    String text = _currentMode == ViewMode.period && date.hour == 0
                        ? "${date.day}.${date.month}"
                        : "${date.hour}:00";
                    return SideTitleWidget(meta: meta, child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.grey)));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 8)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
              show: true,
              verticalInterval: interval,
              getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 0.5)
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _buildLineData(data, (m) => m.solarPower, Colors.blue, hasArea: true),
            _buildLineData(data, (m) => m.homePower, Colors.red),
            _buildLineData(data, (m) => m.bmsSoc, Colors.green, hasArea: true, opacity: 0.05),
            _buildLineData(data, (m) => m.gridPower, Colors.orange),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(List<AnalyticModel> data, double Function(AnalyticModel) getValue, Color color, {bool hasArea = false, double opacity = 0.1}) {
    return LineChartBarData(
      spots: data.map((m) {
        double xValue;
        // Визначаємо X залежно від режиму
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
      belowBarData: BarAreaData(show: hasArea, color: color.withOpacity(opacity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        elevation: 0,
        backgroundColor: Colors.white, // Світлий фон як на скрині
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.location.label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)
            ),
            // ДАТА: Темно-сірий колір, який видно на білому фоні
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
                case ViewMode.period:
                  await _pickPeriod();
                  break;
                case ViewMode.month:
                  await _pickMonth();
                  break;
                case ViewMode.year:
                  await _pickYear();
                  break;
                default:
                  break;
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
                  ? _buildBarChart(_allData) // Стовпчики для дискретних періодів
                  : _buildChart(_allData, isLandscape), // Лінії для Дня та Періоду
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
      color: Colors.grey.withOpacity(0.05),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem("Solar Daily", "${last.solarDailyPower.toStringAsFixed(2)} kWh", Colors.orange),
            _statItem("Home Daily", "${last.homeDailyPower.toStringAsFixed(2) }kWh", Colors.red),
            _statItem("BMS Daily Discharge", "${last.bmsDailyDischarge.toStringAsFixed(2)} kWhh", Colors.red),
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

  Future<void> _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final models = _service.processExcelData(bytes: bytes, location: widget.location);
        if (models.isNotEmpty) {
          final s = await _service.importXmlsData(models);
          if (s) await _fetchData();
        }
      } catch (e) { debugPrint("Import error: $e"); }
      finally { if (mounted) setState(() => _isLoading = false); }
    }
  }

  Widget _buildBarChart(List<AnalyticModel> rawData) {
    if (rawData.isEmpty) return const Center(child: Text("Дані за цей період відсутні"));

    // 1. АГРЕГАЦІЯ: створюємо карту, де ключ — це номер дня або місяця
    // Це гарантує, що для кожної координати X буде лише ОДИН стовпчик
    Map<int, AnalyticModel> aggregatedData = {};

    for (var m in rawData) {
      final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).add(inverterOffset);
      // Ключ: день (1-31) для місяця, або номер місяця (1-12) для року
      int key = _currentMode == ViewMode.month ? date.day : date.month;

      if (!aggregatedData.containsKey(key)) {
        aggregatedData[key] = m;
      } else {
        // Якщо за цей день/місяць вже є запис, беремо той, де більше генерація (DailyPower)
        if (m.solarDailyPower > aggregatedData[key]!.solarDailyPower) {
          aggregatedData[key] = m;
        }
      }
    }

    // Перетворюємо карту в відсортований список для побудови груп
    final sortedKeys = aggregatedData.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.only(top: 25, left: 10, right: 15, bottom: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 125,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.white.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final m = aggregatedData[group.x.toInt()]!;
                final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).add(inverterOffset);
                String label = _currentMode == ViewMode.month
                    ? DateFormat('dd.MM').format(date)
                    : DateFormat('MMMM').format(date);

                return BarTooltipItem(
                  '$label\n',
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: "Solar: ${m.solarDailyPower.toStringAsFixed(1)} kWh\n", style: const TextStyle(color: Colors.blue)),
                    TextSpan(text: "Home: ${m.homeDailyPower.toStringAsFixed(1)} kWh", style: const TextStyle(color: Colors.red)),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (_currentMode == ViewMode.year) {
                    const months = ['', 'С', 'Л', 'Б', 'К', 'Т', 'Ч', 'Л', 'С', 'В', 'Ж', 'Л', 'Г'];
                    if (value >= 1 && value <= 12) {
                      return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                    }
                  } else {
                    if (value % 5 == 0 || value == 1) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    }
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          // Побудова груп на основі агрегованих даних
          barGroups: sortedKeys.map((key) {
            final m = aggregatedData[key]!;
            return BarChartGroupData(
              x: key,
              barRods: [
                BarChartRodData(
                    toY: m.solarDailyPower,
                    color: Colors.blue,
                    width: _currentMode == ViewMode.year ? 16 : 8,
                    borderRadius: BorderRadius.circular(4)
                ),
                BarChartRodData(
                    toY: m.homeDailyPower,
                    color: Colors.red,
                    width: _currentMode == ViewMode.year ? 16 : 8,
                    borderRadius: BorderRadius.circular(4)
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickPeriod() async {
    final DateTimeRange? r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: "ОБЕРІТЬ ПЕРІОД",
    );

    if (r != null) {
      setState(() {
        _startDate = r.start;
        _endDate = r.end;
        _currentMode = ViewMode.period;
      });
      _fetchData();
    }
  }

  Future<void> _pickMonth() async {
    // Викликаємо календар, де за замовчуванням зручно обрати місяць
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "ОБЕРІТЬ МІСЯЦЬ",
      initialDatePickerMode: DatePickerMode.year, // Спочатку вибір року/місяця
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
        _currentMode = ViewMode.month;
      });
      _fetchData();
    }
  }

  Future<void> _pickYear() async {
    int tempYear = _selectedDate.year;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Оберіть рік"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            selectedDate: _selectedDate,
            onChanged: (DateTime dateTime) {
              tempYear = dateTime.year;
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );

    if (tempYear != _selectedDate.year || _currentMode != ViewMode.year) {
      setState(() {
        _selectedDate = DateTime(tempYear, 1, 1);
        _currentMode = ViewMode.year;
      });
      _fetchData();
    }
  }
}