import 'dart:async';
import 'package:floor_front/page/data_home/сomet_flow_painter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floor_front/page/LocationType.dart';
import '../../config/app_config.dart';
import 'data_home_model.dart';

class HomePage extends StatefulWidget {
  final LocationType location;
  const HomePage({super.key, required this.location});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  DataHome? _dataHome;
  bool _loading = true;
  Timer? _refreshTimer;
  AnimationController? _animController;

  static const double solarY = -0.85;
  static const double inverterY = -0.15;
  static const double gridY = 0.85;
  static const double bottomNodesY = 0.5;
  static const double sideNodesX = 0.82;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(minutes: AppConfig.refreshIntervalMinutes), (timer) => _fetchData());
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      setState(() { _loading = true; _dataHome = null; });
      _fetchData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    String apiUrl = widget.location == LocationType.dacha
        ? '${EnvironmentConfig.backendUrl}${AppConfig.apiPathHome}${AppConfig.pathDacha}'
        : '${EnvironmentConfig.backendUrl}${AppConfig.apiPathHome}${AppConfig.pathGolego}';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _dataHome = DataHome.fromJson(json.decode(response.body));
          _loading = false;
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dataHome == null) return const Center(child: CircularProgressIndicator());

    final double batW = _dataHome!.batteryVol * _dataHome!.batteryCurrent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.55,
                constraints: const BoxConstraints(minHeight: 380),
                child: AnimatedBuilder(
                  animation: _animController!,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CometFlowPainter(
                              progress: _animController!.value,
                              solarPower: _dataHome!.solarPower,
                              batteryPower: batW,
                              gridActive: _dataHome!.gridStatusRealTime,
                              gridPower: _dataHome!.gridPower, // Передаємо потужність мережі
                              loadPower: _dataHome!.homePower,
                              solarY: solarY,
                              inverterY: inverterY,
                              gridY: gridY,
                              bottomNodesY: bottomNodesY,
                              sideNodesX: sideNodesX,
                            ),
                          ),
                        ),
                        _buildNode(0, solarY, "lib/assets/data_home/solar-panel-100.png", "Сонячний", "${_dataHome!.solarPower.toInt()} w"),
                        _buildNode(0, inverterY, "lib/assets/data_home/solar-inverter.png", "", ""),
                        _buildNode(-sideNodesX, bottomNodesY, "lib/assets/data_home/accumulator-64.png", "Батарея", "${batW.toInt()} w · ${_dataHome!.batterySoc.toInt()}%"),
                        _buildNode(0, gridY, "lib/assets/data_home/electric-pole-64.png", "Мережа", _dataHome!.gridStatusRealTime ? "${_dataHome!.gridPower.toInt()} w" : "Off", isGrid: true, status: _dataHome!.gridStatusRealTime),
                        _buildNode(sideNodesX, bottomNodesY, "lib/assets/data_home/smarthome-64.png", "Споживання", "${_dataHome!.homePower.toInt()} w"),
                      ],
                    );
                  },
                ),
              ),
              _buildBottomStats(_dataHome!),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNode(double x, double y, String assetPath, String label, String val, {bool isGrid = false, bool status = true}) {
    return Align(
      alignment: Alignment(x, y),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: (isGrid && !status) ? 0.4 : 1.0,
            child: Image.asset(assetPath, width: 48, height: 48, errorBuilder: (c, e, s) => const Icon(Icons.error)),
          ),
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (val.isNotEmpty) Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (isGrid && !status) ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildBottomStats(DataHome data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
        children: [
          _buildStatCard("${data.dailyProductionSolarPower.toStringAsFixed(1)} kWh", "Виробництво", Icons.wb_sunny_outlined),
          _buildStatCard("${data.dailyConsumptionPower.toStringAsFixed(1)} kWh", "Споживання", Icons.home_outlined),
          _buildStatCard("${data.dailyBatteryCharge.toStringAsFixed(1)} kWh", "Заряд АКБ", Icons.battery_charging_full),
          _buildStatCard("${data.dailyBatteryDischarge.toStringAsFixed(1)} kWh", "Розряд АКБ", Icons.battery_std),
          _buildStatCard("${data.dailyGridPower.toStringAsFixed(1)} kWh", "Мережа (день)", Icons.electrical_services),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon) {
    return LayoutBuilder(builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width;
      double cardWidth = screenWidth > 600 ? 180 : (screenWidth / 2) - 20;
      return Container(
        width: cardWidth, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Row(children: [
          Icon(icon, size: 22, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );
    });
  }
}