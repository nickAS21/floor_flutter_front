import 'dart:async';
import 'dart:math' as math;
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
import 'package:floor_front/page/settings/settings_model.dart';

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
  bool _hasShownAlarmSnippet = false;

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
      // Використовуємо callback, щоб дочекатися завершення побудови кадру
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
        }
      });

      setState(() {
        _loading = true;
        _dataHome = null;
        _hasShownAlarmSnippet = false;
      });
      _fetchData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  // Розрахунок прозорості для ефекту блимання
  double get _batteryOpacity {
    if (_dataHome == null || _dataHome!.batterySoc >= BatteryStatus.alarm.value) return 1.0;
    return 0.2 + (0.8 * (math.sin(_animController!.value * math.pi * 2).abs()));
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    // ОРИГІНАЛЬНА ЛОГІКА URL
    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathHome}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathHome}${AppHelper.pathGolego}';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200 && mounted) {
        final dynamic decoded = json.decode(response.body);
        setState(() {
          if (decoded is List && decoded.isNotEmpty) {
            _dataHome = DataHome.fromJson(decoded.first);
          } else {
            _dataHome = DataHome.fromJson(decoded);
          }
          _loading = false;

          if (_dataHome!.batterySoc < BatteryStatus.alarm.value) {
            if (!_hasShownAlarmSnippet) {
              _hasShownAlarmSnippet = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Очищаємо чергу і показуємо нове повідомлення
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      // Використовуємо BatteryStatus.alarm.value замість 30
                      content: Text(
                          "УВАГА: Критичний рівень заряду акумулятора ${widget.location.label} (< ${BatteryStatus.alarm.value.toInt()}%!)"
                      ),
                      backgroundColor: Colors.red.shade900,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              });
            }
          } else {
            if (_hasShownAlarmSnippet) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              });
              setState(() {
                _hasShownAlarmSnippet = false;
              });
            }
          }
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dataHome == null) return const Center(child: CircularProgressIndicator());

    final double batW = _dataHome!.batteryVol * _dataHome!.batteryCurrent;
    final bool isBatteryAlarm = _dataHome!.batterySoc < BatteryStatus.alarm.value;

    String timePart = (_dataHome!.timestampLastUpdateGridStatus.isEmpty || _dataHome!.timestampLastUpdateGridStatus == "null")
        ? "null\n"
        : "${_dataHome!.timestampLastUpdateGridStatus}\n";

    String voltageInfo = "";
    if (_dataHome!.gridStatusRealTimeOnLine && _dataHome!.gridVoltageLs.isNotEmpty) {
      List<String> formattedVoltages = _dataHome!.gridVoltageLs.entries
          .map((e) => "L${e.key}: ${e.value.toInt()} V")
          .toList();

      if (formattedVoltages.length > 2) {
        String row1 = formattedVoltages.take(2).join(" | ");
        String row2 = formattedVoltages.skip(2).join(" | ");
        voltageInfo = "\n$row1\n$row2";
      } else {
        voltageInfo = "\n" + formattedVoltages.join(" | ");
      }
    }

    String powerPart = "";
    if (!_dataHome!.gridStatusRealTimeOnLine) {
      powerPart = "Offline$voltageInfo";
    } else if (!_dataHome!.gridStatusRealTimeSwitch) {
      powerPart = "Off$voltageInfo";
    } else {
      powerPart = "${_dataHome!.gridPower.toInt()} W$voltageInfo";
    }

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
                              gridSwitch: _dataHome!.gridStatusRealTimeSwitch,
                              timestampLastUpdateGridStatus: _dataHome!.timestampLastUpdateGridStatus,
                              gridPower: _dataHome!.gridPower,
                              loadPower: _dataHome!.homePower,
                              solarY: solarY, inverterY: inverterY, gridY: gridY,
                              bottomNodesY: bottomNodesY, sideNodesX: sideNodesX,
                            ),
                          ),
                        ),
                        _buildNode(0, solarY, "lib/assets/data_home/solar-panel-100.png", AppLocalizations.of(context)!.solarPanel, "${_dataHome!.solarPower.toInt()} W"),
                        _buildNode(0, inverterY, "lib/assets/data_home/solar-inverter.png", "", ""),

                        // АКУМУЛЯТОР З БЛИМАННЯМ ТА ЧЕРВОНИМ ТЕКСТОМ
                        _buildNode(
                          -sideNodesX,
                          bottomNodesY,
                          "lib/assets/data_home/accumulator-64.png",
                          AppLocalizations.of(context)!.battery,
                          " · ${_dataHome!.batteryCurrent.toStringAsFixed(2)} A · ${_dataHome!.batteryVol.toStringAsFixed(2)} V\n · ${batW.toInt()} W · ${_dataHome!.batterySoc.toStringAsFixed(2)} %",
                          isBattery: true,
                          isAlarm: isBatteryAlarm,
                        ),

                        _buildNode(0, gridY,
                            _dataHome!.gridStatusRealTimeOnLine ? "lib/assets/data_home/electric-pole-64_green.png" : "lib/assets/data_home/electric-pole-64_red.png",
                            AppLocalizations.of(context)!.grid, timePart + powerPart, isGrid: true, status: _dataHome!.gridStatusRealTimeOnLine),
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

  Widget _buildNode(double x, double y, String assetPath, String label, String val, {bool isGrid = false, bool status = true, bool isBattery = false, bool isAlarm = false}) {
    return Align(
      alignment: Alignment(x, y),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            // Застосовуємо геттер _batteryOpacity для акумулятора в режимі Alarm
            opacity: isBattery && isAlarm ? _batteryOpacity : ((isGrid && !status) ? 0.4 : 1.0),
            child: Image.asset(
              assetPath,
              width: 48,
              height: 48,
              errorBuilder: (c, e, s) => const Icon(Icons.error),
              color: isBattery && isAlarm ? Colors.red : null,
              colorBlendMode: isBattery && isAlarm ? BlendMode.srcIn : null,
            ),
          ),
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            val,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (isAlarm || (isGrid && !status)) ? Colors.red : Colors.black,
                height: 1.2
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
    double cardWidth = MediaQuery.of(context).size.width > 600 ? 180 : (MediaQuery.of(context).size.width / 2) - 20;
    return Container(
      width: cardWidth, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4)]),
      child: Row(children: [
        Icon(icon, size: 22, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}