import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = true;
  ViewMode _viewMode = ViewMode.day;
  PowerType _selectedPowerType = PowerType.GRID;
  DateTime _selectedDate = DateTime.now();
  List<AnalyticModel> _data = [];

  final AnalyticConnectService _analyticService = AnalyticConnectService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final result = await _analyticService.fetchData(
        mode: _viewMode,
        date: _selectedDate,
        location: widget.location,
        powerType: _selectedPowerType,
        token: token,
      );

      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red.shade900
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Analytics: ${widget.location.label}"), // Використовуємо label з твоєї моделі
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? const Center(child: Text("No data found for this period"))
                : _buildChartContainer(),
          ),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ViewMode>(
              segments: ViewMode.values
                  .map((v) => ButtonSegment(value: v, label: Text(v.name.toUpperCase())))
                  .toList(),
              selected: {_viewMode},
              onSelectionChanged: (Set<ViewMode> newSelection) {
                setState(() => _viewMode = newSelection.first);
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<PowerType>(
            value: _selectedPowerType,
            underline: const SizedBox(),
            icon: const Icon(Icons.bolt, color: Colors.orange),
            items: PowerType.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                .toList(),
            onChanged: (p) {
              if (p != null) {
                setState(() => _selectedPowerType = p);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: _buildChart(),
    );
  }

  Widget _buildChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        // Динамічний розрахунок максимуму для осі Y
        maxY: (_data.map((e) => e.powerTotal).reduce((a, b) => a > b ? a : b) * 1.3).clamp(5, 5000),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= _data.length) return const SizedBox();

                // Перетворюємо timestamp бекенда у дату для підпису осі
                DateTime dt = DateTime.fromMillisecondsSinceEpoch(_data[index].timestamp);
                String text = _viewMode == ViewMode.year
                    ? DateFormat('MMM').format(dt)
                    : DateFormat('dd').format(dt);

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _data.asMap().entries.map((entry) {
          final d = entry.value;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: d.powerTotal,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                rodStackItems: [
                  // Синій для ночі, Помаранчевий для дня
                  BarChartRodStackItem(0, d.powerNight, Colors.blue.shade800),
                  BarChartRodStackItem(d.powerNight, d.powerNight + d.powerDay, Colors.orange.shade400),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummary() {
    double total = _data.fold(0, (sum, item) => sum + item.powerTotal);
    double totalDay = _data.fold(0, (sum, item) => sum + item.powerDay);
    double totalNight = _data.fold(0, (sum, item) => sum + item.powerNight);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Day Zone", totalDay, Colors.orange),
              _buildSummaryItem("Night Zone", totalNight, Colors.blue.shade900),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Consumption", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${total.toStringAsFixed(2)} kWh", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        Text("${value.toStringAsFixed(2)} kWh", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }
}