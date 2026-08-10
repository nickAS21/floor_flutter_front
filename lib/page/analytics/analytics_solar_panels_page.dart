import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data_home/data_location_type.dart';
import '../refreshable_state.dart';
import 'analitic_model.dart';
import 'anaytic_connect_service.dart';

class AnalyticsSolarPanelsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsSolarPanelsPage({super.key, required this.location});

  @override
  State<AnalyticsSolarPanelsPage> createState() => _AnalyticsSolarPanelsPageState();
}

class _AnalyticsSolarPanelsPageState extends RefreshableState<AnalyticsSolarPanelsPage> {
  final AnalyticConnectService _service = AnalyticConnectService();
  List<AnalyticModel> _allData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  int _touchedGroupIndex = -1;
  final ScrollController _scrollController = ScrollController();

  // 4 фіксовані кольори для панелей
  final List<Color> _panelColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
  ];

  @override
  void dispose() {
    _scrollController.dispose();
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
  void didUpdateWidget(covariant AnalyticsSolarPanelsPage oldWidget) {
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

  List<String> _getUniquePanelKeys() {
    final Set<String> keys = {};
    for (var m in _allData) {
      if (m.panelInfoDtos?.panels != null) {
        keys.addAll(m.panelInfoDtos!.panels.keys);
      }
    }
    final list = keys.toList();
    list.sort();
    return list;
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

            // РЯДОК 2: ПОКАЗНИКИ (В 2 РЯДКИ)
            _buildCombinedChartsHeader(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("kWt", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text("kWt", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
    final panelKeys = _getUniquePanelKeys();

    Widget statRow(String label, dynamic val, Color col, [String unit = ""]) {
      String display = (val is num) ? val.toStringAsFixed(1) : val.toString();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w400)),
          Text(display, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
          if (unit.isNotEmpty)
            Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w400)),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1-Й РЯДОК: Time + Загальне Solar (ЖИРНИМ ЧОРНИМ)
          Row(
            children: [
              Text("Time: $timeStr", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              statRow("Solar", last.solarPower, Colors.black, " W"),
            ],
          ),
          const SizedBox(height: 4),

          // 2-Й РЯДОК: ПАНЕЛІ ЗІ СКРОЛОМ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < panelKeys.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                      () {
                    final key = panelKeys[i];
                    final valW = last.panelInfoDtos?.panels[key]?.pvPowerCurW ?? 0.0;
                    final col = _panelColors[i % _panelColors.length];
                    return statRow(key, valW, col);
                  }(),
                ],
              ],
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

    double minX = _allData.first.timestamp.toDouble();
    double maxX = _allData.last.timestamp.toDouble();

    final DateTime dayStart = DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    double targetMinX = dayStart.millisecondsSinceEpoch.toDouble();
    double targetMaxX = dayStart.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();

    if (minX > targetMinX) minX = targetMinX;
    if (maxX < targetMaxX) maxX = targetMaxX;

    // --- РОЗРАХУНОК МАКСИМУМУ ШКАЛИ ПО ПАНЕЛЯХ ---
    double maxPowerW = 0.0;
    for (var m in _allData) {
      if (m.panelInfoDtos?.panels != null) {
        for (var p in m.panelInfoDtos!.panels.values) {
          if (p.pvPowerCurW > maxPowerW) {
            maxPowerW = p.pvPowerCurW;
          }
        }
      }
    }

    if (maxPowerW <= 0) maxPowerW = 100.0;

    double chartMaxY = (maxPowerW / 50.0).ceil() * 50.0;
    if (chartMaxY <= maxPowerW) chartMaxY += 50.0;

    double yInterval = chartMaxY / 5.0;
    if (yInterval < 10) yInterval = 10;

    final panelKeys = _getUniquePanelKeys();
    List<LineChartBarData> lines = [];

    for (int i = 0; i < panelKeys.length; i++) {
      final key = panelKeys[i];
      final col = _panelColors[i % _panelColors.length];
      lines.add(
        _buildLineData(
          _allData,
              (m) => m.panelInfoDtos?.panels[key]?.pvPowerCurW ?? 0.0,
          col,
        ),
      );
    }

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // У портреті беремо доступну висоту, в ландшафті даємо фіксовані 320px для скролу
          double targetHeight = isLandscape ? 320 : constraints.maxHeight;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical, // 1. ВЕРТИКАЛЬНИЙ СКРОЛ
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal, // 2. ГОРИЗОНТАЛЬНИЙ СКРОЛ
                child: SizedBox(
                  width: chartWidth,
                  height: targetHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 30, bottom: 15),
                    child: LineChart(
                      LineChartData(
                        minX: minX,
                        maxX: maxX,
                        minY: 0,
                        maxY: chartMaxY,
                        clipData: const FlClipData.all(),
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          enabled: true,
                          touchCallback: (event, res) {
                            if (res == null || res.lineBarSpots == null || res.lineBarSpots!.isEmpty) {
                              if (_touchedGroupIndex != -1) setState(() => _touchedGroupIndex = -1);
                              return;
                            }
                            int newIndex = res.lineBarSpots!.first.spotIndex;
                            if (_touchedGroupIndex != newIndex) {
                              setState(() => _touchedGroupIndex = newIndex);
                            }
                          },
                          getTouchedSpotIndicator: (barData, spotIndexes) {
                            return spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                FlLine(color: Colors.grey.withValues(alpha: 0.4), strokeWidth: 2),
                                FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 3.0,
                                    color: Colors.white,
                                    strokeColor: barData.color ?? Colors.black,
                                    strokeWidth: 1.5,
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
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (v) => FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              interval: yInterval,
                              getTitlesWidget: (v, m) {
                                final double kWt = v / 1000.0;
                                return Text(
                                  kWt.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 8),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 3600000,
                              getTitlesWidget: (v, m) {
                                final date = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
                                if ((v - maxX).abs() < 1000) {
                                  return SideTitleWidget(meta: m, child: const Text("24:00", style: TextStyle(fontSize: 8)));
                                }
                                if (date.minute != 0 || date.hour % 4 != 0) return const SizedBox();
                                if (date.hour == 0 && date.minute == 0) {
                                  return SideTitleWidget(
                                    meta: m,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        DateFormat('dd.MM').format(date),
                                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                                return SideTitleWidget(
                                  meta: m,
                                  child: Text("${date.hour}:00", style: const TextStyle(fontSize: 8)),
                                );
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
              ),
            ),
          );
        },
      ),
    );
  }

  LineChartBarData _buildLineData(
      List<AnalyticModel> data,
      double Function(AnalyticModel) getValue,
      Color color,
      ) {
    return LineChartBarData(
      spots: data.map((m) => FlSpot(m.timestamp.toDouble(), getValue(m))).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}