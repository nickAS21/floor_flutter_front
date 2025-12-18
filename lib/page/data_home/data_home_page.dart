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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fetchData();
    _refreshTimer = Timer.periodic(
        const Duration(minutes: AppConfig.refreshIntervalMinutes),
            (timer) => _fetchData()
    );
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
    final double consumption = _dataHome!.solarPower + (batW > 0 ? batW : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                            loadPower: consumption,
                            solarY: solarY,
                            inverterY: inverterY,
                            gridY: gridY,
                            bottomNodesY: bottomNodesY,
                            sideNodesX: sideNodesX,
                          ),
                        ),
                      ),
                      // 1. Сонячна панель
                      _buildNode(0, solarY, "lib/assets/data_home/solar-panel-100.png", "Сонячний", "${_dataHome!.solarPower.toInt()} w", isCustomIcon: true),

                      // 2. Інвертор
                      _buildNode(0, inverterY, "lib/assets/data_home/solar-inverter.png", "", "", isCustomIcon: true),

                      // 3. Акумулятор (Батарея)
                      _buildNode(-sideNodesX, bottomNodesY, "lib/assets/data_home/accumulator-64.png", "Батарея", "${batW.toInt()} w · ${_dataHome!.batterySoc.toInt()}%", isCustomIcon: true),

                      // 4. Мережа (Електроопора)
                      _buildNode(0, gridY, "lib/assets/data_home/electric-pole-64.png", "Мережа", _dataHome!.gridStatusRealTime ? "0 w" : "Off", isGrid: true, status: _dataHome!.gridStatusRealTime, isCustomIcon: true),

                      // 5. Споживання (Smart Home)
                      _buildNode(sideNodesX, bottomNodesY, "lib/assets/data_home/smarthome-64.png", "Споживання", "${consumption.toInt()} w", isCustomIcon: true),
                    ],
                  );
                },
              ),
            ),
            _buildBottomStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(double x, double y, dynamic iconSource, String label, String val, {bool isGrid = false, bool status = true, bool isCustomIcon = false}) {
    return Align(
      alignment: Alignment(x, y),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isCustomIcon
              ? Opacity(
            opacity: (isGrid && !status) ? 0.4 : 1.0, // Напівпрозорість, якщо мережа Off
            child: Image.asset(
              iconSource as String,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
            ),
          )
              : Icon(iconSource as IconData, size: 45, color: (isGrid && !status) ? Colors.red : const Color(0xFF2D3436)),
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (val.isNotEmpty)
            Text(
                val,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (isGrid && !status) ? Colors.red : Colors.black, // Текст "Off" стає червоним
                )
            ),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.0,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatCard("100 wh", "Виробництво", Icons.wb_sunny_outlined),
          _buildStatCard("1.8 kwh", "Споживання", Icons.home_outlined),
          _buildStatCard("0 wh", "Підключення", Icons.electrical_services),
          _buildStatCard("0 wh", "Покупка", Icons.shopping_cart_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ]),
        ],
      ),
    );
  }
}