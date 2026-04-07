import 'package:flutter/material.dart';
import '../data_home/data_location_type.dart';
import '../refreshable_state.dart';
import 'analytics_soc_power_page.dart';
import 'analytics_temperature_page.dart';

class AnalyticsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsPage({super.key, required this.location});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends RefreshableState<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabNames = ["Power & SOC", "Temperature", "L & H"];

  final List<GlobalKey<RefreshableState>> _innerKeys = [
    GlobalKey<RefreshableState>(),
    GlobalKey<RefreshableState>(),
    GlobalKey<RefreshableState>(),
  ];

  @override
  void refresh() {
    String currentTabName = _tabNames[_tabController.index];
    debugPrint("AnalyticsPage: прокидаю refresh до таба: $currentTabName");
    _innerKeys[_tabController.index].currentState?.refresh();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

// analytics_page.dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Приховуємо верхню частину (заголовок), залишаємо тільки таби
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabNames.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          AnalyticsSocPowerPage(key: _innerKeys[0], location: widget.location),
          AnalyticsTemperaturePage(key: _innerKeys[1], location: widget.location, isTemperature: true),
          AnalyticsTemperaturePage(key: _innerKeys[2], location: widget.location, isTemperature: false),
        ],
      ),
    );
  }
}