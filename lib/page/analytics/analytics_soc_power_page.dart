import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data_home/data_location_type.dart';
import '../refreshable_state.dart';
import 'analitic_model.dart';
import 'analytic_enums.dart';
import 'anaytic_connect_service.dart';
import 'month_picker.dart';

class AnalyticsSocPowerPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsSocPowerPage({super.key, required this.location});

  @override
  State<AnalyticsSocPowerPage> createState() => _AnalyticsSocPowerPageState();
}

class _AnalyticsSocPowerPageState extends RefreshableState<AnalyticsSocPowerPage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  ViewMode _currentMode = ViewMode.day;
  int _touchedGroupIndex = -1;

  final ScrollController _horizontalScroll = ScrollController();

  @override
  void refresh() {
    setState(() => _isLoading = true);
    _fetchData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void didUpdateWidget(AnalyticsSocPowerPage oldWidget) {
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
    // 1. Отримуємо першу точку даних як базу
    var firstDate = DateTime.fromMillisecondsSinceEpoch(data.first.timestamp, isUtc: true);
    var lastDate = DateTime.fromMillisecondsSinceEpoch(data.last.timestamp, isUtc: true);

    // 2. Встановлюємо minX чітко на 00:00:00
    if (_currentMode == ViewMode.period) {
      firstDate = _startDate;
      lastDate = _endDate;
    }
    minX = DateTime
        .utc(firstDate.year, firstDate.month, firstDate.day)
        .millisecondsSinceEpoch
        .toDouble();
    maxX = DateTime
        .utc(lastDate.year, lastDate.month, lastDate.day + 1)
        .millisecondsSinceEpoch
        .toDouble();

    return LineChart(
      LineChartData(
        minX: minX, maxX: maxX, minY: 0, maxY: maxY,
        clipData: const FlClipData.all(),

        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null) {
              // Якщо прибрали палець — не скидаємо індекс відразу, або скидаємо на -1
              return;
            }
            // Отримуємо індекс точки, на яку навів користувач
            setState(() => _touchedGroupIndex = touchResponse.lineBarSpots!.first.spotIndex);
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent, // Ховаємо плаваючий тултіп
            getTooltipItems: (spots) => spots.map((s) => null).toList(), // Прибираємо текст з ліній
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              // Малюємо таку саму сіру риску, як у стовпчиках
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.grey.withValues(alpha: 0.4), strokeWidth: 2),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3.0,               // Радіус кола
                      color: Colors.white,       // Колір середини (зроби білим або прозорим)
                      strokeColor: barData.color ?? Colors.black,        // Колір лінії по краю (твій колір графіка)
                      strokeWidth: 1.5,          // Товщина цієї лінії
                    );
                  },
                ),
              );
            }).toList();
          },
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
              interval: 3600000, // Перевіряємо кожну годину
              getTitlesWidget: (v, m) {
                // 1. Створюємо об'єкт часу суворо Local
                final date = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);

                // 2. Жорстка перевірка на 24:00 (кінець доби)
                if ((v - maxX).abs() < 1000) {
                  return SideTitleWidget(meta: m, child: const Text("24:00", style: TextStyle(fontSize: 8)));
                }

                // 3. Фільтруємо мітки: тільки початок години і кожні 4 години
                // Це прибере зсув -1 година на Android
                if (date.minute != 0 || date.hour % 4 != 0) {
                  return const SizedBox();
                }

                // 4. Малюємо дату для першої точки (00:00)
                if (date.hour == 0 && date.minute == 0) {
                  return SideTitleWidget(
                    meta: m,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(6), color: Colors.white),
                      child: Text(DateFormat('dd.MM').format(date), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  );
                }

                // 5. Для всіх інших точок (4:00, 8:00...) просто час
                return SideTitleWidget(
                    meta: m,
                    child: Text("${date.hour}:00", style: const TextStyle(fontSize: 8))
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          // Перевіряємо кожну годину
          verticalInterval: 3600000,
          checkToShowVerticalLine: (value) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
            return date.hour % 4 == 0; // Лінія кожні 4 години
          },
          getDrawingVerticalLine: (value) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
            if (date.hour == 0) {
              return FlLine(color: Colors.black, strokeWidth: 1.5); // Жирна північ
            }
            return FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 0.5);
          },
          horizontalInterval: 50,
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
    double screenWidth = MediaQuery.of(context).size.width;
    for (var m in data) {
      if (m.solarPower / 1000.0 > maxPowerkW) maxPowerkW = m.solarPower / 1000.0;
      if (m.homePower / 1000.0 > maxPowerkW) maxPowerkW = m.homePower / 1000.0;
      if (m.gridPower / 1000.0 > maxPowerkW) maxPowerkW = m.gridPower / 1000.0;
    }
    double powerMaxY = maxPowerkW * 1.15;
    double ratio = 100 / powerMaxY;

    double chartWidth = (_currentMode == ViewMode.period
        ? (_endDate.difference(_startDate).inDays + 1) * screenWidth
        : (isLandscape ? screenWidth * 1.5 : screenWidth)) * chartScale;

    final selectedData = (_touchedGroupIndex != -1 && _touchedGroupIndex < data.length)
        ? data[_touchedGroupIndex]
        : null;

    return Column(
      children: [
// ВЕРХНЯ ПАНЕЛЬ
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: isLandscape ? 2 : 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: selectedData == null
              ? const Text("Оберіть точку на графіку", style: TextStyle(fontSize: 10, color: Colors.grey))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Дозволяємо горизонтальний скрол
            child: Row(
              children: [
                Text(
                  "Time: ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(selectedData.timestamp, isUtc: true))}",
                  style: TextStyle(fontSize: isLandscape ? 9 : 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12), // Фіксований відступ замість spaceBetween
                statRow("Sol", selectedData.solarPower / 1000.0, Colors.blue, " kW"),
                const SizedBox(width: 10),
                statRow("Load", selectedData.homePower / 1000.0, Colors.red, " kW"),
                const SizedBox(width: 10),
                statRow("SOC", selectedData.bmsSoc, Colors.green, "%"),
                const SizedBox(width: 10),
                statRow("Grid", selectedData.gridPower / 1000.0, Colors.orange, " kW"),
              ],
            ),
          ),
        ),

        // ГРАФІК
        Expanded(
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: chartWidth,
                padding: EdgeInsets.only(left: 10, right: 30, bottom: isLandscape ? 5 : 15),
                child: _buildBaseChart(
                  data: data,
                  isLandscape: isLandscape,
                  maxY: 115,
                  powerMaxY: powerMaxY,
                  yAxisLabel: "kW / %",
                  lines: [
                    _buildLineData(data, (m) => m.bmsSoc, Colors.green, hasArea: true, opacity: 0.1),
                    _buildLineData(data, (m) => (m.solarPower / 1000.0) * ratio, Colors.blue, hasArea: true, opacity: 0.1),
                    _buildLineData(data, (m) => (m.homePower / 1000.0) * ratio, Colors.red, hasArea: true, opacity: 0.1),
                    _buildLineData(data, (m) => (m.gridPower / 1000.0) * ratio, Colors.orange, hasArea: true, opacity: 0.1),
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
          xValue = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).day.toDouble();
        } else if (_currentMode == ViewMode.year) {
          xValue = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true).month.toDouble();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // 1. ПАНЕЛЬ КЕРУВАННЯ (завжди зверху, фіксована висота)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.location.label,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(
                          _currentMode == ViewMode.day
                              ? DateFormat('dd.MM.yyyy').format(_selectedDate)
                              : _currentMode == ViewMode.month
                              ? DateFormat('MMMM yyyy', 'uk').format(_selectedDate)
                              : _currentMode == ViewMode.year
                              ? "Рік: ${_selectedDate.year}"
                              : "${DateFormat('dd.MM').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.upload_file, size: 20, color: Colors.black), onPressed: _importExcel),
                  IconButton(icon: const Icon(Icons.calendar_today, size: 20, color: Colors.black), onPressed: _pickDate),

                  buildScaleSelector(), // Твій селектор масштабу

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
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: (_currentMode == ViewMode.month || _currentMode == ViewMode.year)
                  ? _buildBarChart(_allData)
                  : _buildCombinedCharts(_allData, isLandscape),
            ),

            if (_allData.isNotEmpty)
              _buildStats(_allData.last),
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

  void _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) { setState(() { _selectedDate = d; _currentMode = ViewMode.day; }); _fetchData(); }
  }

  Future<void> _pickPeriod() async {
    final DateTimeRange? r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      saveText: 'ОК', // <--- ОСЬ ТУТ МІНЯЄМО ТЕКСТ КНОПКИ
      helpText: 'Оберіть період', // Можна також змінити заголовок зверху
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
    DateTime tempDate = _selectedDate; // Локальна змінна для діалогу

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Це дозволяє діалогу "оживати" при кліках
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Оберіть місяць"),
              content: SizedBox(
                width: 300,
                height: 250,
                child: MonthPicker(
                  selectedDate: tempDate,
                  onChanged: (dt) {
                    // Оновлюємо стан ВСЕРЕДИНІ діалогу
                    setDialogState(() => tempDate = dt);
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Відміна")),
                TextButton(
                  onPressed: () {
                    // При натисканні ОК оновлюємо головний екран
                    setState(() {
                      _selectedDate = DateTime(tempDate.year, tempDate.month, 1);
                      _currentMode = ViewMode.month;
                    });
                    Navigator.pop(context);
                    _fetchData();
                  },
                  child: const Text("ОК"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickYear() async {
    DateTime tempDate = _selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Оберіть рік"),
              content: SizedBox(
                width: 300,
                height: 250,
                child: YearPicker(
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  selectedDate: tempDate,
                  onChanged: (dt) {
                    // Оновлюємо колір виділеного року в діалозі
                    setDialogState(() => tempDate = dt);
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Відміна")),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(tempDate.year, 1, 1);
                      _currentMode = ViewMode.year;
                    });
                    Navigator.pop(context);
                    _fetchData();
                  },
                  child: const Text("ОК"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBarChart(List<AnalyticModel> rawData) {
    // 1. ДЕБАГ-ЛОГИ ВХІДНИХ ДАНИХ
    // debugPrint("--- BAR CHART DEBUG START ---");
    // debugPrint("Всього точок від бека: ${rawData.length}");
    // if (rawData.isNotEmpty) {
    //   debugPrint("Перша точка: ${DateTime.fromMillisecondsSinceEpoch(rawData.first.timestamp, isUtc: true)}");
    //   debugPrint("Остання точка: ${DateTime.fromMillisecondsSinceEpoch(rawData.last.timestamp, isUtc: true)}");
    // }

    double minX = 1;
    double maxX;
    if (_currentMode == ViewMode.year) {
      maxX = 12;
    } else {
      maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day.toDouble();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = screenWidth * chartScale;

    // 2. ГРУПУВАННЯ З ЛОГУВАННЯМ
    Map<int, AnalyticModel> grouped = {};
    for (var m in rawData) {
      final date = DateTime.fromMillisecondsSinceEpoch(m.timestamp, isUtc: true);
      int key = _currentMode == ViewMode.month ? date.day : date.month;

      // Лог для кожної точки (можна закоментувати, якщо точок забагато)
      // debugPrint("Парсинг: точка ${date.toIso8601String()} -> ключ $key");

      if (!grouped.containsKey(key)) {
        grouped[key] = m;
      } else {
        // Вибираємо запис з найбільшою генерацією як репрезентативний для стовпчика
        if (m.solarDailyPower > grouped[key]!.solarDailyPower) {
          grouped[key] = m;
        }
      }
    }

    debugPrint("Згруповано ключів (стовпчиків): ${grouped.keys.toList()}");
    debugPrint("--- BAR CHART DEBUG END ---");

    // РОЗРАХУНОК МАКСИМУМУ
    double maxVal = 1.0;
    for (var m in grouped.values) {
      List<double> values = [
        m.solarDailyPower, m.homeDailyPower, m.gridDailyTotalPower,
        m.gridDailyDayPower, m.gridDailyNightPower,
        m.bmsDailyDischarge, m.bmsDailyCharge
      ];
      for (var v in values) {
        if (v > maxVal) maxVal = v;
      }
    }
    double chartMaxY = maxVal * 1.15;

    int displayIndex = _touchedGroupIndex;
    if (displayIndex == -1 && grouped.isNotEmpty) {
      displayIndex = grouped.keys.reduce((a, b) => a > b ? a : b) - 1;
    }
    final selectedData = grouped[displayIndex + 1];

    // РОЗУМНЕ ФОРМАТУВАННЯ ЧИСЕЛ
    Widget _smartStat(String label, double val, Color col) {
      bool isLarge = val.abs() > 999;
      double displayVal = isLarge ? val / 1000 : val;
      String unitSuffix = isLarge ? "k" : "";

      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 9, color: Colors.black),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w300)),
            TextSpan(
                text: "${displayVal.toStringAsFixed(displayVal.abs() > 100 ? 1 : 2)}$unitSuffix",
                style: TextStyle(fontWeight: FontWeight.bold, color: col)
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: selectedData == null
              ? const Text("Дані відсутні", style: TextStyle(fontSize: 10, color: Colors.grey))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${_currentMode == ViewMode.month ? 'Д:' : 'М:'} ${displayIndex + 1}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    _smartStat("Sol:", selectedData.solarDailyPower, Colors.blue),
                    const SizedBox(width: 8),
                    _smartStat("Hm:", selectedData.homeDailyPower, Colors.red),
                    const SizedBox(width: 8),
                    _smartStat("Bms-D:", selectedData.bmsDailyDischarge, Colors.red),
                    const SizedBox(width: 8),
                    _smartStat("Bms-C:", selectedData.bmsDailyCharge, Colors.blue),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    _smartStat("G-Day:", selectedData.gridDailyDayPower, Colors.orange),
                    const SizedBox(width: 8),
                    _smartStat("G-Night:", selectedData.gridDailyNightPower, Colors.blue),
                    const SizedBox(width: 8),
                    _smartStat("G-Total:", selectedData.gridDailyTotalPower, Colors.deepPurple),
                  ],
                ),
              ],
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text("kWh", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),

        Expanded(
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: chartWidth,
                padding: const EdgeInsets.only(top: 15, left: 10, right: 15, bottom: 10),
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    alignment: BarChartAlignment.center,
                    groupsSpace: (_currentMode == ViewMode.year ? 12.0 : 8.0) * chartScale,
                    barTouchData: BarTouchData(
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                          return;
                        }
                        setState(() {
                          _touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
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
                            if (chartScale > 1.5 || _currentMode == ViewMode.year || val == 1 || val == maxX || val % 5 == 0) {
                              return SideTitleWidget(
                                meta: m,
                                child: Text(val.toString(), style: const TextStyle(fontSize: 8)),
                              );
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
                      getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(maxX.toInt(), (index) {
                      int key = index + 1;
                      final double withCol = 2.0 * (chartScale > 2.0 ? 1.5 : 1.0);
                      final double minH = chartMaxY * 0.005;
                      final m = grouped[key];
                      bool isActive = (displayIndex == index);

                      return BarChartGroupData(
                        x: key,
                        barsSpace: 1,
                        barRods: [
                          BarChartRodData(
                            toY: chartMaxY,
                            color: Colors.grey.withValues(alpha: isActive ? 0.35 : 0.05),
                            width: withCol / 2,
                            borderRadius: BorderRadius.zero,
                          ),
                          BarChartRodData(toY: (m?.solarDailyPower ?? 0) <= 0 ? minH : m!.solarDailyPower, color: Colors.blue, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.homeDailyPower ?? 0) <= 0 ? minH : m!.homeDailyPower, color: Colors.red, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.gridDailyTotalPower ?? 0) <= 0 ? minH : m!.gridDailyTotalPower, color: Colors.deepPurple, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.gridDailyDayPower ?? 0) <= 0 ? minH : m!.gridDailyDayPower, color: Colors.orange, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.gridDailyNightPower ?? 0) <= 0 ? minH : m!.gridDailyNightPower, color: Colors.indigo, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.bmsDailyDischarge ?? 0) <= 0 ? minH : m!.bmsDailyDischarge, color: Colors.brown, width: withCol, borderRadius: BorderRadius.circular(2)),
                          BarChartRodData(toY: (m?.bmsDailyCharge ?? 0) <= 0 ? minH : m!.bmsDailyCharge, color: Colors.lightBlue, width: withCol, borderRadius: BorderRadius.circular(2)),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget statRow(String label, dynamic val, Color col, [String unit = ""]) {
    String display;
    if (val is num) {
      // Якщо значення менше 1 (наприклад 0.05 kW), показуємо 3 знаки (0.050)
      // Якщо більше (наприклад 230V або 77% SOC), показуємо 1 або 2
      if (val.abs() < 1.0 && val.abs() > 0) {
        display = val.toStringAsFixed(3);
      } else {
      display = val.abs() < 20 ? val.toStringAsFixed(1) : val.toStringAsFixed(2);
    }
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

  Future<void> _importExcel() async {
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
        List<AnalyticModel> detailedPoints = await _service.processExcelData(
          bytes: bytes,
          location: widget.location,
        );

        if (detailedPoints.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Файл порожній або невірний формат")),
            );
          }
          return;
        }

        // 2. Відправляємо запит.
        // Тепер success — це об'єкт ImportResult (або перевіряємо через результат сервісу)
        final importResponse = await _service.importXmlsData(detailedPoints);

        if (mounted) {
          if (importResponse.isSuccess) {
            // Успіх
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(importResponse.message),
                  backgroundColor: Colors.green
              ),
            );
            await _fetchData(); // Оновлюємо графік
          } else {
            // ПОМИЛКА (тут вилетить твоє повідомлення про 413)
            _showErrorDialog(importResponse.message);
          }
        }

      } catch (e) {
        debugPrint("Import error: $e");
        if (mounted) {
          _showErrorDialog("Критична помилка: $e");
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

// Допоміжний метод для гарного діалогу
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Помилка імпорту"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Зрозуміло"),
          ),
        ],
      ),
    );
  }
}