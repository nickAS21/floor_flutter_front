import 'package:flutter/material.dart';
import '../data_home/data_location_type.dart';
import 'analytics_soc_power_page.dart';
import 'analytics_temperature_page.dart';

class AnalyticsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsPage({super.key, required this.location});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TabBar виносимо в AppBar основного контейнера
      appBar: AppBar(
        toolbarHeight: 48,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Power & SOC"),
            Tab(text: "Temperature"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AnalyticsSocPowerPage(location: widget.location),
          AnalyticsTemperaturePage(location: widget.location),
        ],
      ),
    );
  }
}