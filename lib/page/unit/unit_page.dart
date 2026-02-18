import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'battery_info_model.dart';
import 'device_model.dart';
import 'unit_model.dart';
import 'unit_helper.dart';
import 'inverter_model.dart';

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

  // --- Helpers ---

  IconData _getConnectionIcon(String? status) {
    if (status == null) return Icons.cloud_off;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'ONLINE':
        return Icons.cloud_done;
      case 'STANDBY':
        return Icons.access_time_filled;
      case 'OFFLINE':
      default:
        return Icons.cloud_off;
    }
  }

  Color _getConnectionColor(String? status) {
    if (status == null) return Colors.red;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'ONLINE':
        return Colors.green;
      case 'STANDBY':
        return Colors.orange;
      case 'OFFLINE':
      default:
        return Colors.red;
    }
  }

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

  // --- Data Fetching ---

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

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
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
        // 1. Інвертор
        if (_unitModel!.inverter != null)
          _buildInverterCard(_unitModel!.inverter!),

        // 2. Акумулятори (Expansion у стилі картки)
        if (_unitModel!.batteries.isNotEmpty)
          _buildBatteryExpansion(_unitModel!.batteries),

        // 3. Мережа
        if (grid.isNotEmpty) ..._buildDeviceSection("Мережа (Grid)", grid),

        // 4. Тепла підлога
        if (floors.isNotEmpty)
          _buildFloorExpansion(floors),

        // 5. Інші пристрої
        if (others.isNotEmpty) ..._buildDeviceSection("Інші пристрої", others),
      ],
    );
  }

  // --- Inverter Widgets ---

  Widget _buildInverterCard(InverterModel inverter) {
    final info = inverter.inverterInfo;
    final Color statusColor = inverter.statusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Інвертор"),
        Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => info != null ? _showInverterDetails(inverter) : null,
            leading: Icon(
              _getConnectionIcon(inverter.connectionStatus),
              color: statusColor,
              size: 40,
            ),
            title: Text(
              "${info?.productName ?? 'Inverter'} (Port ${inverter.port ?? 'N/A'})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${info?.manufacturer ?? 'N/A'} | ${info?.ratedPower} kW"),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      inverter.statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.info_outline, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  // --- Battery Widgets (Expansion in Inverter Style) ---

  Widget _buildBatteryExpansion(List<BatteryInfoModel> list) {
    // 1. Сортуємо список за номером порту перед рендерингом
    final sortedList = List<BatteryInfoModel>.from(list)
      ..sort((a, b) => a.port.compareTo(b.port));

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          Icons.battery_charging_full,
          // Використовуємо вже відсортований список для перевірки помилок
          color: sortedList.any((b) => UnitHelper.hasRealError(b.errorInfoDataHex)) ? Colors.red : Colors.blue,
          size: 40,
        ),
        title: const Text("Система акумуляторів", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Модулів: ${sortedList.length}"),
        // 2. Ітеруємося по sortedList замість оригінального list
        children: sortedList.map((b) => ListTile(
          leading: Icon(
            UnitHelper.getConnectionIcon(b.connectionStatus),
            color: UnitHelper.hasRealError(b.errorInfoDataHex) ? Colors.red : UnitHelper.getConnectionColor(b.connectionStatus),
          ),
          title: Text("Battery ${b.port}"),
          subtitle: Text("${b.socPercent.toInt()}% | ${b.voltageCurV.toStringAsFixed(2)}V"),
          onTap: () => _showBatteryDetails(b),
        )).toList(),
      ),
    );
  }

  // --- Common Widgets ---

  void _showInverterDetails(InverterModel inverter) {
    if (inverter.inverterInfo == null) return;
    final info = inverter.inverterInfo!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(info.productName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("Номер порту", "${inverter.port}", Colors.blueGrey),
              _buildDetailRow("Статус порту", inverter.statusText, inverter.statusColor),
              _buildDetailRow("Виробник", info.manufacturer, null),
              _buildDetailRow("Модель", info.modelName, null),
              _buildDetailRow("Потужність", "${info.ratedPower} kW", Colors.blue),
              _buildDetailRow("Вольтаж", "${info.inputVoltage}V", null),
              _buildDetailRow("Фазність", info.phaseType, null),
              _buildDetailRow("Тип", info.isHybrid ? "Hybrid" : "Off-grid", Colors.orange),
              _buildDetailRow("MPPT", info.mpptControllerName, null),
              _buildDetailRow("Комісія", info.commissioningDate, Colors.grey),
              if (inverter.timestamp != null)
                _buildDetailRow("Оновлено", inverter.timestamp!, Colors.grey),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрити"))
        ],
      ),
    );
  }

  void _showBatteryDetails(BatteryInfoModel battery) {
    bool isError = _hasRealError(battery.errorInfoDataHex);
    // Використовуємо UnitHelper для перевірки критичної дельти
    bool isCriticalDelta = battery.deltaMv >= UnitHelper.cellsCriticalDeltaMin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(widget.location == LocationType.dacha ? "Акумулятор" : "Battery ${battery.port}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDetailRow("Зв'язок", battery.connectionStatus, _getConnectionColor(battery.connectionStatus)),
              _buildDetailRow("Оновлено", battery.timestamp, Colors.grey),
              _buildDetailRow("Напруга", "${battery.voltageCurV.toStringAsFixed(2)} V", null),
              _buildDetailRow("Заряд (SOC)", "${battery.socPercent.toStringAsFixed(1)}%", Colors.blue),
              _buildDetailRow("Струм", "${battery.currentCurA} A", null),
              _buildDetailRow("Статус BMS", battery.bmsStatusStr, _getStatusColor(battery.bmsStatusStr)),
              if (battery.bmsTempValue != null)
                _buildDetailRow("Температура BMS", "${battery.bmsTempValue!.toStringAsFixed(2)}°C", null),
              _buildDetailRow(
                  "Помилка (HEX)",
                  _formatHex(battery.errorInfoDataHex),
                  isError ? Colors.red : (isCriticalDelta ? Colors.orange : Colors.green)
              ),
              const Divider(),
              _buildDetailRow(
                  "Delta",
                  "${battery.deltaMv.toStringAsFixed(3)} V",
                  isCriticalDelta ? Colors.red : Colors.green
              ),
              const SizedBox(height: 8),
              const Text("Напруга по комірках:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              ...battery.cellVoltagesV.entries.map((e) {
                Color? cellColor;
                FontWeight fontWeight = FontWeight.normal;

                // Якщо дельта критична, підсвічуємо екстремальні значення
                if (isCriticalDelta) {
                  if (e.key == battery.maxCellIdx) {
                    cellColor = Colors.red; // Максимальна - червоний
                    fontWeight = FontWeight.bold;
                  } else if (e.key == battery.minCellIdx) {
                    cellColor = Colors.blue; // Мінімальна - синій
                    fontWeight = FontWeight.bold;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Комірка ${e.key}",
                        style: TextStyle(color: cellColor, fontWeight: fontWeight),
                      ),
                      Text(
                        "${e.value.toStringAsFixed(3)} V",
                        style: TextStyle(color: cellColor, fontWeight: fontWeight),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
      title: const Text("Тепла підлога", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
      children: list.map((d) => ListTile(
        title: Text(d.name),
        subtitle: Text("Поточна: ${d.currentValue}°C"),
        trailing: Text("${d.settingValue}°C", style: const TextStyle(fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Future<void> _toggleDevice(DeviceModel device, bool newValue) async {}
}