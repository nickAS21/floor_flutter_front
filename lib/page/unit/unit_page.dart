import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'battery_info_model.dart';
import 'unit_model.dart';
import 'unit_helper.dart';

class UnitPage extends StatefulWidget {
  final LocationType location;
  const UnitPage({super.key, required this.location});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  UnitModel? _unitModel;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchUnitData();
    // Використання хелпера для автоматичного оновлення
    _refreshTimer = AppHelper.startRefreshTimer(_fetchUnitData);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _resetAndFetch();
    }
  }

  void _resetAndFetch() {
    setState(() {
      _isLoading = true;
      _unitModel = null;
    });
    _fetchUnitData();
  }

  // Визначення кольору для статусу BMS
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'charging':
        return Colors.green;
      case 'discharging':
        return Colors.red;
      case 'static':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatHex(String hex) {
    if (hex.isEmpty) return "0x0000";
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    cleanHex = cleanHex.padLeft(4, '0');
    return "0x${cleanHex.toUpperCase()}";
  }

  bool _hasRealError(String hex) {
    if (hex.isEmpty) return false;
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    final val = int.tryParse(cleanHex, radix: 16);
    return val != null && val > 0;
  }

  String _getApiUrl() {
    String path = widget.location == LocationType.dacha
        ? AppHelper.pathDacha
        : AppHelper.pathGolego;
    return '${ApiServerHelper.backendUrl}${AppHelper.apiPathUnit}$path';
  }

  Future<void> _fetchUnitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(_getApiUrl()),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _unitModel = UnitModel.fromJson(jsonDecode(response.body));
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server status: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка завантаження Unit: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Керування: ${widget.location == LocationType.dacha ? 'Дача' : 'Golego'}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetAndFetch)
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      )
          : _unitModel == null
          ? const Center(child: Text("Дані відсутні"))
          : RefreshIndicator(
        onRefresh: _fetchUnitData,
        child: _buildUnitList(),
      ),
    );
  }

  Widget _buildUnitList() {
    final devices = _unitModel!.devices;
    final grid = devices.where((d) => d.type == 'grid').toList();
    final floors = devices.where((d) => d.type == 'floor').toList();
    final others = devices.where((d) => !['grid', 'floor'].contains(d.type)).toList();

    return ListView(
      children: [
        if (grid.isNotEmpty) ..._buildDeviceSection("Мережа (Grid)", grid),
        if (_unitModel!.batteries.isNotEmpty)
          _buildBatteryExpansion(_unitModel!.batteries),
        if (floors.isNotEmpty)
          _buildFloorExpansion(floors),
        if (others.isNotEmpty) ..._buildDeviceSection("Інші пристрої", others),
      ],
    );
  }

  Widget _buildBatteryExpansion(List<BatteryInfoModel> list) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text("Акумулятори (BMS)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      children: list.map((b) {
        bool isError = _hasRealError(b.errorInfoDataHex);
        bool isWarning = !isError && (b.deltaMv >= UnitHelper.cellsCriticalDeltaMin);

        IconData statusIcon = Icons.check_circle_outline;
        Color statusColor = Colors.green;

        if (isError) {
          statusIcon = Icons.warning;
          statusColor = Colors.red;
        } else if (isWarning) {
          statusIcon = Icons.report_problem;
          statusColor = Colors.orange;
        }

        return Column(
          children: [
            ListTile(
              leading: Icon(
                b.isActive ? Icons.check_circle : Icons.remove_circle,
                color: b.isActive ? Colors.green : Colors.red,
              ),
              title: Row(
                children: [
                  Text("Battery ${b.port}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      children: [
                        TextSpan(text: "${b.socPercent}% | ${b.voltageCurV.toStringAsFixed(2)}V | ${b.currentCurA}A | "),
                        TextSpan(
                          text: b.bmsStatusStr,
                          style: TextStyle(color: _getStatusColor(b.bmsStatusStr), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text("Оновлено: ${b.timestamp}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              onTap: () => _showBatteryDetails(b),
            ),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  void _showBatteryDetails(BatteryInfoModel battery) {
    bool isError = _hasRealError(battery.errorInfoDataHex);
    bool isCriticalDelta = battery.deltaMv >= UnitHelper.cellsCriticalDeltaMin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Battery ${battery.port}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDetailRow("Активна", battery.isActive ? "Так" : "Ні", battery.isActive ? Colors.green : Colors.red),
              _buildDetailRow("Оновлено", battery.timestamp, Colors.grey),
              _buildDetailRow("Напруга", "${battery.voltageCurV.toStringAsFixed(2)} V", null),
              _buildDetailRow("Заряд (SOC)", "${battery.socPercent}%", Colors.blue),
              _buildDetailRow("Струм", "${battery.currentCurA} A", null),
              _buildDetailRow("Статус BMS", battery.bmsStatusStr, _getStatusColor(battery.bmsStatusStr)),
              _buildDetailRow(
                  "Помилка (HEX)",
                  _formatHex(battery.errorInfoDataHex),
                  isError ? Colors.red : (isCriticalDelta ? Colors.orange : Colors.green)
              ),
              const Divider(),
              _buildDetailRow("Delta", "${battery.deltaMv.toStringAsFixed(3)} V", isCriticalDelta ? Colors.red : Colors.green),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Напруга комірок:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ),
              ...battery.cellVoltagesV.entries.map((e) {
                Color? accentColor;
                if (isCriticalDelta) {
                  if (e.key == battery.minCellIdx) accentColor = Colors.red;
                  if (e.key == battery.maxCellIdx) accentColor = Colors.orange;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Комірка ${e.key}"),
                      Text("${e.value.toStringAsFixed(3)} V",
                          style: TextStyle(color: accentColor, fontWeight: accentColor != null ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрити"))
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceSection(String title, List<DeviceModel> list) {
    return [
      _buildHeader(title),
      ...list.map((d) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ListTile(
          leading: Icon(Icons.power, color: d.isOn ? Colors.green : Colors.grey),
          title: Text(d.name),
          subtitle: Text(d.isOnline ? "Online" : "Offline"),
          trailing: Switch(
            value: d.isOn,
            onChanged: d.isOnline ? (v) => _toggleDevice(d, v) : null,
          ),
        ),
      )),
    ];
  }

  Widget _buildFloorExpansion(List<DeviceModel> list) {
    return ExpansionTile(
      title: const Text("Тепла підлога",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
      children: list
          .map((d) => ListTile(
        title: Text(d.name),
        subtitle: Text("Поточна: ${d.currentValue}°C"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Ціль", style: TextStyle(fontSize: 10)),
            Text("${d.settingValue}°C", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Future<void> _toggleDevice(DeviceModel device, bool newValue) async {
    // POST запит
  }
}