import 'package:floor_front/page/analytics/panels/base_panel_chart_page.dart';
import 'package:floor_front/page/analytics/panels/panel_current_chart_page.dart';
import 'package:floor_front/page/analytics/panels/panel_power_chart_page.dart';
import 'package:floor_front/page/analytics/panels/panel_voltage_chart_page.dart';
import 'package:floor_front/page/components/chart_scale_selector.dart';
import 'package:flutter/material.dart';
import '../data_home/data_location_type.dart';

class AnalyticsSolarPanelsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsSolarPanelsPage({super.key, required this.location});

  @override
  State<AnalyticsSolarPanelsPage> createState() => _AnalyticsSolarPanelsPageState();
}

class _AnalyticsSolarPanelsPageState extends State<AnalyticsSolarPanelsPage>
    with TickerProviderStateMixin {
  final Set<PanelMetricType> _selectedMetrics = {PanelMetricType.power};
  late TabController _tabController;
  PanelMetricType _currentMetric = PanelMetricType.power;

  // Єдина методика збереження параметрів кожної метрики
  final Map<PanelMetricType, double> _metricScales = {
    PanelMetricType.power: 1.0,
    PanelMetricType.voltage: 1.0,
    PanelMetricType.current: 1.0,
  };

  final Map<PanelMetricType, DateTime> _metricDates = {
    PanelMetricType.power: DateTime.now(),
    PanelMetricType.voltage: DateTime.now(),
    PanelMetricType.current: DateTime.now(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    final activeList = _getActiveMetricsList();
    if (_tabController.index < activeList.length) {
      _currentMetric = activeList[_tabController.index];
    }
  }

  List<PanelMetricType> _getActiveMetricsList() {
    List<PanelMetricType> list = [];
    if (_selectedMetrics.contains(PanelMetricType.power)) list.add(PanelMetricType.power);
    if (_selectedMetrics.contains(PanelMetricType.voltage)) list.add(PanelMetricType.voltage);
    if (_selectedMetrics.contains(PanelMetricType.current)) list.add(PanelMetricType.current);
    return list;
  }

  void _toggleMetric(PanelMetricType metric) {
    bool isAdding = !_selectedMetrics.contains(metric);

    if (!isAdding && _selectedMetrics.length <= 1) return;

    setState(() {
      if (isAdding) {
        _selectedMetrics.add(metric);
        // Скидання параметрів до дефолтних при повторному додаванні
        _metricScales[metric] = 1.0;
        _metricDates[metric] = DateTime.now();
        _currentMetric = metric;
      } else {
        _selectedMetrics.remove(metric);
      }

      final activeListAfter = _getActiveMetricsList();

      if (!activeListAfter.contains(_currentMetric)) {
        _currentMetric = activeListAfter.isNotEmpty ? activeListAfter[0] : PanelMetricType.power;
      }

      int newIndex = activeListAfter.indexOf(_currentMetric);
      if (newIndex == -1) newIndex = 0;

      final oldController = _tabController;
      oldController.removeListener(_handleTabSelection);

      _tabController = TabController(
        length: activeListAfter.length,
        vsync: this,
        initialIndex: newIndex,
      );
      _tabController.addListener(_handleTabSelection);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeMetricsList = _getActiveMetricsList();
    List<Widget> activeTabs = [];
    List<Widget> activePages = [];

    for (var metric in activeMetricsList) {
      switch (metric) {
        case PanelMetricType.power:
          activeTabs.add(const Tab(height: 36, child: Text("Power (kWt)", style: TextStyle(fontSize: 11))));
          activePages.add(PanelPowerChartPage(
            location: widget.location,
            chartScale: _metricScales[PanelMetricType.power]!,
            selectedDate: _metricDates[PanelMetricType.power]!,
            onDateChanged: (newDate) {
              setState(() => _metricDates[PanelMetricType.power] = newDate);
            },
          ));
          break;
        case PanelMetricType.voltage:
          activeTabs.add(const Tab(height: 36, child: Text("Voltage (V)", style: TextStyle(fontSize: 11))));
          activePages.add(PanelVoltageChartPage(
            location: widget.location,
            chartScale: _metricScales[PanelMetricType.voltage]!,
            selectedDate: _metricDates[PanelMetricType.voltage]!,
            onDateChanged: (newDate) {
              setState(() => _metricDates[PanelMetricType.voltage] = newDate);
            },
          ));
          break;
        case PanelMetricType.current:
          activeTabs.add(const Tab(height: 36, child: Text("Current (A)", style: TextStyle(fontSize: 11))));
          activePages.add(PanelCurrentChartPage(
            location: widget.location,
            chartScale: _metricScales[PanelMetricType.current]!,
            selectedDate: _metricDates[PanelMetricType.current]!,
            onDateChanged: (newDate) {
              setState(() => _metricDates[PanelMetricType.current] = newDate);
            },
          ));
          break;
      }
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Вибір графіків:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<PanelMetricType>(
                icon: const Icon(Icons.tune, size: 20),
                onSelected: _toggleMetric,
                itemBuilder: (BuildContext context) {
                  return PanelMetricType.values.map((PanelMetricType metric) {
                    final isSelected = _selectedMetrics.contains(metric);
                    return CheckedPopupMenuItem<PanelMetricType>(
                      value: metric,
                      checked: isSelected,
                      child: Text(metric.title),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      tabs: activeTabs,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final currentIndex = _tabController.index < activeMetricsList.length
                          ? _tabController.index
                          : 0;
                      final currentMetric = activeMetricsList.isNotEmpty
                          ? activeMetricsList[currentIndex]
                          : PanelMetricType.power;

                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ChartScaleSelector(
                          currentScale: _metricScales[currentMetric] ?? 1.0,
                          onScaleChanged: (double newScale) {
                            setState(() {
                              _metricScales[currentMetric] = newScale;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: activePages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}