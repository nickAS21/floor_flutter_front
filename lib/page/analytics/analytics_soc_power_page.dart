import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../data_home/data_location_type.dart';
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

class _AnalyticsSocPowerPageState extends State<AnalyticsSocPowerPage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  ViewMode _currentMode = ViewMode.day;
  int _touchedGroupIndex = -1;

  final ScrollController _horizontalScroll = ScrollController();

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
    }
    double powerMaxY = maxPowerkW * 1.15;
    double ratio = 100 / powerMaxY;

    double chartWidth = _currentMode == ViewMode.period
        ? (_endDate.difference(_startDate).inDays + 1) * screenWidth
        : (isLandscape ? screenWidth * 1.5 : screenWidth);

// 1. Отримуємо дані для вибраної точки
    final selectedData = (_touchedGroupIndex != -1 && _touchedGroupIndex < data.length)
        ? data[_touchedGroupIndex]
        : null;

    return Column(
      children: [
        // ВЕРХНЯ ПАНЕЛЬ (точно як у гістограмах)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: selectedData == null
              ? const Text("Оберіть точку на графіку", style: TextStyle(fontSize: 10, color: Colors.grey))
              : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Дата та час точки
                  Text(
                    "Time:" + DateFormat('dd.MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(selectedData.timestamp, isUtc: true)),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  _topStat("Solar:", selectedData.solarPower / 1000.0, Colors.green),
                  _topStat("Home:", selectedData.homePower / 1000.0, Colors.red),
                  _topStat("SOC:", "${selectedData.bmsSoc.toInt()}%", Colors.blue), // Твій колір SOC
                  _topStat("Grid:", selectedData.gridPower / 1000.0,  Colors.orange),
                ],
              ),
            ],
          ),
        ),

        // Твій існуючий код далі
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("kW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Text("%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: chartWidth,
                padding: const EdgeInsets.only(left: 10, right: 30, bottom: 15),
                child: _buildBaseChart(
                  data: data,
                  isLandscape: isLandscape,
                  maxY: 115,
                  powerMaxY: powerMaxY,
                  yAxisLabel: "kW / %",
                  lines: [
                    _buildLineData(data, (m) => m.bmsSoc, Colors.blue, hasArea: true, opacity: 0.1),
                    _buildLineData(data, (m) => (m.solarPower / 1000.0) * ratio, Colors.green, hasArea: true, opacity: 0.1),
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
    double minX = 1;
    double maxX;
    // double interval = 1;

    if (_currentMode == ViewMode.year) {
      maxX = 12;
    } else {
      maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day
          .toDouble();
    }

    Map<int, AnalyticModel> grouped = {};
    for (var m in rawData) {
      // Жодних add(inverterOffset), тільки чистий UTC
      final date = DateTime.fromMillisecondsSinceEpoch(
          m.timestamp, isUtc: true);
      int key = _currentMode == ViewMode.month ? date.day : date.month;
      if (!grouped.containsKey(key) ||
          m.solarDailyPower > grouped[key]!.solarDailyPower) {
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

    // Знаходимо дані для підсвіченого індексу
    // 1. Знаходимо дані для підсвіченого індексу (як у тебе)
    final selectedData = _touchedGroupIndex != -1 ? grouped[_touchedGroupIndex +
        1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ВЕРХНЯ ПАНЕЛЬ (Замість плаваючого тултіпа)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: selectedData == null
              ? const Text("Оберіть день на графіку",
              style: TextStyle(fontSize: 10, color: Colors.grey))
              : Column( // Два рядки для компактності
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_currentMode == ViewMode.month
                        ? 'День'
                        : 'Місяць'} ${_touchedGroupIndex + 1}",
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  _topStat("Solar:", selectedData.solarDailyPower, Colors.green),
                  _topStat("Home:", selectedData.homeDailyPower, Colors.red),
                  _topStat("Bms Discharge:", selectedData.bmsDailyDischarge, Colors.red),
                  _topStat("Bms Charge:", selectedData.bmsDailyCharge, Colors.blue),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 35), // вирівнювання під дату
                  _topStat("Grid Day:", selectedData.gridDailyDayPower,  Colors.orange),
                  _topStat("Grid Night:", selectedData.gridDailyNightPower, Colors.blue),
                  _topStat("Grid Total:", selectedData.gridDailyTotalPower, Colors.deepPurple),
                ],
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text("kWh", style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(
                top: 15, left: 10, right: 15, bottom: 10),
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMaxY,
                alignment: BarChartAlignment.center,
                // 2. Встановлюємо відстань МІЖ днями/місяцями.
                // Якщо стовпчики напливають — збільш це число (наприклад, до 15 або 20)
                groupsSpace: _currentMode == ViewMode.year ? 12 : 8,

                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedGroupIndex = -1;
                        return;
                      }
                      _touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                  // ПОВНІСТЮ ВИМИКАЄМО ТЕКСТ НА ГРАФІКУ
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent, // Робимо фон невидимим
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => null, // ПОВЕРТАЄМО NULL, ЩОБ ЦИФРИ НЕ ПЛАВАЛИ
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                          v.toStringAsFixed(1), // ЖОРСТКЕ ОКРУГЛЕННЯ ОСІ
                          style: const TextStyle(fontSize: 8)
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, m) {
                        int val = v.toInt();
                        if (val < minX || val > maxX) return const SizedBox();
                        if (_currentMode == ViewMode.year) {
                          return Text(val.toString(),
                              style: const TextStyle(fontSize: 8));
                        } else {
                          if (val == 1 || val == maxX || val % 5 == 0) {
                            return Text(val.toString(),
                                style: const TextStyle(fontSize: 8));
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
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.withValues(alpha: 0.1),
                          strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(maxX.toInt(), (index) {
                  int key = index + 1;
                  final double withCol = 2;
                  final double minH = chartMaxY * 0.005;
                  final m = grouped[key];
                  bool isTouched = _touchedGroupIndex == index;

                  return BarChartGroupData(
                    x: key,
                    barsSpace: 1, // <--- Зменшуємо проміжок між палками до 1 пікселя
                    barRods: [
                      BarChartRodData(
                        toY: chartMaxY,
                        // Підсвічуємо вдвічі яскравіше при натисканні (як ти хотів)
                        color: Colors.grey.withValues(alpha: isTouched
                            ? 0.40
                            : 0.05),
                        width: withCol / 4,
                        borderRadius: BorderRadius.zero,
                      ),
                      BarChartRodData(toY: (m?.solarDailyPower ?? 0) <= 0
                          ? minH
                          : m!.solarDailyPower,
                          color: Colors.green,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.homeDailyPower ?? 0) <= 0
                          ? minH
                          : m!.homeDailyPower,
                          color: Colors.red,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.gridDailyTotalPower ?? 0) <= 0
                          ? minH
                          : m!.gridDailyTotalPower,
                          color: Colors.deepPurple,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.gridDailyDayPower ?? 0) <= 0
                          ? minH
                          : m!.gridDailyDayPower,
                          color: Colors.orange,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.gridDailyNightPower ?? 0) <= 0
                          ? minH
                          : m!.gridDailyNightPower,
                          color: Colors.indigo,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.bmsDailyDischarge ?? 0) <= 0
                          ? minH
                          : m!.bmsDailyDischarge,
                          color: Colors.brown,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(toY: (m?.bmsDailyCharge ?? 0) <= 0
                          ? minH
                          : m!.bmsDailyCharge,
                          color: Colors.lightBlue,
                          width: withCol,
                          borderRadius: BorderRadius.circular(2)),
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

  // Допоміжний метод для верхньої панелі
  Widget _topStat(String label, dynamic val, Color col) {
    String display;
    if (val is num) {
      display = val.toStringAsFixed(2); // ОКРУГЛЮЄМО ВСІ ЧИСЛА ДО 2 ЗНАКІВ
    } else {
      display = val.toString();
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 9, color: Colors.black),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w300)),
          TextSpan(text: display, style: TextStyle(fontWeight: FontWeight.bold, color: col)),
        ],
      ),
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
        List<AnalyticModel> detailedPoints = await _service.processExcelData(
          bytes: bytes,
          location: widget.location,
        );

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
}