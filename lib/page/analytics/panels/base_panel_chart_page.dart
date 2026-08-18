import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data_home/data_location_type.dart';
import '../../refreshable_state.dart';
import '../analytic_connect_service.dart';
import '../analytic_model.dart';
import '../panel_info_model.dart';

enum PanelMetricType {
  power('Power (kWt)', 'kWt'),
  voltage('Voltage (V)', 'V'),
  current('Current (A)', 'A');

  final String title;
  final String unit;
  const PanelMetricType(this.title, this.unit);
}

abstract class BasePanelChartPage extends StatefulWidget {
  final LocationType location;
  final double chartScale;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const BasePanelChartPage({
    super.key,
    required this.location,
    required this.chartScale,
    required this.selectedDate,
    required this.onDateChanged,
  });
}

abstract class BasePanelChartPageState<T extends BasePanelChartPage> extends RefreshableState<T> {
  final AnalyticConnectService service = AnalyticConnectService();
  List<AnalyticModel> allData = [];
  bool isLoading = true;

  int touchedGroupIndex = -1;
  final ScrollController scrollController = ScrollController();

  final List<Color> panelColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
  ];

  PanelMetricType get metricType;
  double getPanelValue(PanelInfoModel? panel);
  double get yStep;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void refresh() => fetchData();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location || oldWidget.selectedDate != widget.selectedDate) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await service.getAnalyticDay(date: widget.selectedDate, location: widget.location);
      if (mounted) {
        setState(() {
          allData = data..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Оберіть дату',
    );

    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }

  List<String> getUniquePanelKeys() {
    final Set<String> keys = {};
    for (var m in allData) {
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
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ВЕРХНЯ ЧАСТИНА (Керування)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.location.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd.MM.yyyy').format(widget.selectedDate), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.calendar_today, size: 18), onPressed: pickDate),
                  ],
                ),
              ),
              const Divider(height: 1),

              // РЯДОК ПОКАЗНИКІВ
              _buildCombinedChartsHeader(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(metricType.unit, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text(metricType.unit, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),

              // ГРАФІК З ЧІТКОЮ ВИСОТОЮ ДЛЯ УНИКНЕННЯ OVERFLOW
              SizedBox(
                height: isLandscape ? 280.0 : 380.0,
                child: _buildMainChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedChartsHeader() {
    if (allData.isEmpty) return const SizedBox.shrink();

    final index = (touchedGroupIndex == -1 || touchedGroupIndex >= allData.length)
        ? allData.length - 1
        : touchedGroupIndex;
    final last = allData[index];

    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(last.timestamp, isUtc: true),
    );
    final panelKeys = getUniquePanelKeys();

    final Map<String, List<String>> groupedKeys = {};
    for (var key in panelKeys) {
      final prefix = key.contains('_') ? key.split('_').first : 'P';
      groupedKeys.putIfAbsent(prefix, () => []).add(key);
    }

    final groupEntries = groupedKeys.entries.toList();

    int maxCols = 0;
    for (var e in groupEntries) {
      if (e.value.length > maxCols) maxCols = e.value.length;
    }

    Widget buildStatCell(String key) {
      final panel = last.panelInfoDtos?.panels[key];
      final rawVal = getPanelValue(panel);
      final displayVal = metricType == PanelMetricType.power ? rawVal / 1000.0 : rawVal;
      final colorIndex = panelKeys.indexOf(key);
      final col = panelColors[colorIndex % panelColors.length];

      return Padding(
        padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$key: ",
              style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w400),
            ),
            Text(
              displayVal.toStringAsFixed(1),
              style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              " ${metricType.unit}",
              style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      );
    }

    List<TableRow> tableRows = [];
    for (var entry in groupEntries) {
      final keys = entry.value;
      List<Widget> rowCells = [];

      for (int c = 0; c < maxCols; c++) {
        if (c < keys.length) {
          rowCells.add(buildStatCell(keys[c]));
        } else {
          rowCells.add(const SizedBox());
        }
      }

      tableRows.add(TableRow(children: rowCells));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // СТРОКА 1: Time + Solar
          Row(
            children: [
              Text("Time: $timeStr", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              if (metricType == PanelMetricType.power) ...[
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Solar: ", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w400)),
                    Text(last.solarPower.toStringAsFixed(1), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Text(" W", style: TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ],
          ),

          // СТРОКИ 2+: M1, S2, S3... Обмежені за висотою, щоб не ламати верстку
          if (tableRows.isNotEmpty) ...[
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 65),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    children: tableRows,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    if (allData.isEmpty) return const Center(child: Text("Немає даних"));

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    double baseWidth = isLandscape ? screenWidth * 1.5 : screenWidth;

    double chartWidth = baseWidth * widget.chartScale;

    double minX = allData.first.timestamp.toDouble();
    double maxX = allData.last.timestamp.toDouble();

    final DateTime dayStart = DateTime.utc(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    double targetMinX = dayStart.millisecondsSinceEpoch.toDouble();
    double targetMaxX = dayStart.add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();

    if (minX > targetMinX) minX = targetMinX;
    if (maxX < targetMaxX) maxX = targetMaxX;

    double maxVal = 0.0;
    for (var m in allData) {
      if (m.panelInfoDtos?.panels != null) {
        for (var p in m.panelInfoDtos!.panels.values) {
          final val = getPanelValue(p);
          if (val > maxVal) maxVal = val;
        }
      }
    }

    if (maxVal <= 0) maxVal = 10.0;

    double chartMaxY = (maxVal / yStep).ceil() * yStep;
    if (chartMaxY <= maxVal) chartMaxY += yStep;

    double yInterval = chartMaxY / 5.0;
    if (yInterval < 1) yInterval = 1;

    final panelKeys = getUniquePanelKeys();
    List<LineChartBarData> lines = [];

    for (int i = 0; i < panelKeys.length; i++) {
      final key = panelKeys[i];
      final col = panelColors[i % panelColors.length];
      lines.add(
        LineChartBarData(
          spots: allData.map((m) => FlSpot(m.timestamp.toDouble(), getPanelValue(m.panelInfoDtos?.panels[key]))).toList(),
          isCurved: true,
          color: col,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: col.withValues(alpha: 0.08)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double targetHeight = isLandscape ? 300.0 : constraints.maxHeight;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: targetHeight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 30, bottom: 10),
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
                            if (touchedGroupIndex != -1) setState(() => touchedGroupIndex = -1);
                            return;
                          }
                          int newIndex = res.lineBarSpots!.first.spotIndex;
                          if (touchedGroupIndex != newIndex) {
                            setState(() => touchedGroupIndex = newIndex);
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
                              final double displayVal = metricType == PanelMetricType.power ? v / 1000.0 : v;
                              return Text(displayVal.toStringAsFixed(1), style: const TextStyle(fontSize: 8));
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
    );
  }
}