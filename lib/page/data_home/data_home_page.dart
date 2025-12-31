import 'dart:async';
import 'package:floor_front/page/data_home/data_home_painter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floor_front/page/data_home/data_location_type.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../../l10n/app_localizations.dart';
import 'data_home_model.dart';

class HomePage extends StatefulWidget {
  final LocationType location;
  const HomePage({super.key, required this.location});

  @override
  State<HomePage> createState() => _HomePageState();
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
    _refreshTimer = Timer.periodic(const Duration(minutes: AppHelper.refreshIntervalMinutes), (timer) => _fetchData());
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
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathHome}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathHome}${AppHelper.pathGolego}';

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

    // 1. Оголошуємо змінні тут, перед версткою
    String timePart = _dataHome!.timestampLastUpdateGridStatus.isNotEmpty
        ? "${_dataHome!.timestampLastUpdateGridStatus}\n"
        : "";

    String powerPart = _dataHome!.gridStatusRealTimeOnLine
        ? "${_dataHome!.gridPower.toInt()} W"
        : "Off";

    String gridInfo = timePart + powerPart;

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
                            painter: DataHomePainter(
                              progress: _animController!.value,
                              solarPower: _dataHome!.solarPower,
                              batteryPower: batW,
                              gridActive: _dataHome!.gridStatusRealTimeOnLine,
                              timestampLastUpdateGridStatus: _dataHome!.timestampLastUpdateGridStatus,
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
                        _buildNode(0, solarY, "lib/assets/data_home/solar-panel-100.png", AppLocalizations.of(context)!.solarPanel, "${_dataHome!.solarPower.toInt()} W"),
                        _buildNode(0, inverterY, "lib/assets/data_home/solar-inverter.png", "", ""),
                        _buildNode(-sideNodesX, bottomNodesY, "lib/assets/data_home/accumulator-64.png", AppLocalizations.of(context)!.battery, " · ${_dataHome!.batteryCurrent.toDouble().toStringAsFixed(2)} A · ${_dataHome!.batteryVol.toDouble().toStringAsFixed(2)} V\n · ${batW.toInt()} W · ${_dataHome!.batterySoc.toDouble().toStringAsFixed(2)} %"),
                        _buildNode(
                          0,
                          gridY,
                          _dataHome!.gridStatusRealTimeOnLine
                              ? "lib/assets/data_home/electric-pole-64_green.png"
                              : "lib/assets/data_home/electric-pole-64_red.png",
                          AppLocalizations.of(context)!.grid,
                          gridInfo,
                          isGrid: true,
                          status: _dataHome!.gridStatusRealTimeOnLine,
                        ),
                        _buildNode(sideNodesX, bottomNodesY, "lib/assets/data_home/smarthome-64.png", AppLocalizations.of(context)!.load, "${_dataHome!.homePower.toInt()} W"),
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
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (val.isNotEmpty)
            Text(
              val,
              textAlign: TextAlign.center, // Центрує час і W
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (isGrid && !status) ? Colors.red : Colors.black,
                height: 1.2, // Відступ між рядками
              ),
            ),
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
          _buildStatCard("${data.dailyProductionSolarPower.toStringAsFixed(1)} kWh", AppLocalizations.of(context)!.dailySolarPanel, Icons.wb_sunny_outlined),
          _buildStatCard("${data.dailyConsumptionPower.toStringAsFixed(1)} kWh", AppLocalizations.of(context)!.dailyLoad, Icons.home_outlined),
          _buildStatCard("${data.dailyBatteryCharge.toStringAsFixed(1)} kWh", AppLocalizations.of(context)!.dailyBatteryCharge, Icons.battery_charging_full),
          _buildStatCard("${data.dailyBatteryDischarge.toStringAsFixed(1)} kWh", AppLocalizations.of(context)!.dailyBatteryDischarge, Icons.battery_std),
          _buildStatCard("${data.dailyGridPower.toStringAsFixed(1)} kWh", AppLocalizations.of(context)!.dailyGrid, Icons.electrical_services),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
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