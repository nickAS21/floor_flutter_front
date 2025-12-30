import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'battery_info_model.dart';
import 'unit_model.dart';

class UnitPage extends StatefulWidget {
  final LocationType location;
  const UnitPage({super.key, required this.location});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  UnitModel? _unitModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnitData();
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
        setState(() {
          _unitModel = UnitModel.fromJson(jsonDecode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception("Server status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Помилка завантаження Unit: $e")),
      );
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
          ? const Center(child: CircularProgressIndicator())
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

  Widget _buildBatteryExpansion(List<BatteryInfoModel> list) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text("Акумулятори (BMS)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      children: list.map((b) {
        // Оскільки на беку intToHex, перевіряємо рядок
        bool hasError = b.errorInfoDataHex != '0x00' && b.errorInfoDataHex.isNotEmpty;

        return Column(
          children: [
            ListTile(
              leading: Icon(Icons.battery_charging_full,
                  color: b.isActive ? Colors.green : Colors.grey),
              title: Text("Battery ${b.port}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${b.socPercent}% | ${b.voltageCurV}V | ${b.currentCurA}A | ${b.bmsStatusStr}"),
                  Text("Оновлено: ${b.timestamp}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: hasError ? const Icon(Icons.warning, color: Colors.red) : null,
              onTap: () => _showCellDetails(b),
            ),
            if (hasError && b.errorOutput.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Text("BMS Error: ${b.errorOutput}",
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  void _showCellDetails(BatteryInfoModel battery) {
    // Поріг для підсвітки (0.1V або за бажанням)
    bool isCriticalDelta = battery.deltaMv >= 0.100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Battery ${battery.port}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Delta: ", style: TextStyle(fontSize: 14)),
                Text("${battery.deltaMv.toStringAsFixed(3)} V",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCriticalDelta ? Colors.red : Colors.green
                    )),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: battery.cellVoltagesV.entries.map((e) {
              int cellIdx = e.key;
              double voltage = e.value;

              // Визначаємо колір акценту
              Color? accentColor;
              if (isCriticalDelta) {
                if (cellIdx == battery.minCellIdx) accentColor = Colors.red;
                if (cellIdx == battery.maxCellIdx) accentColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  // Замість opacity використовуємо тонку рамку для проблемних комірок
                  border: accentColor != null
                      ? Border.all(color: accentColor.withOpacity(0.5), width: 1)
                      : Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  // Додаємо кольоровий маркер зліва
                  leading: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor ?? Colors.blueGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text("Комірка $cellIdx"),
                  trailing: Text(
                    "${voltage.toStringAsFixed(3)} V",
                    style: TextStyle(
                      fontWeight: accentColor != null ? FontWeight.bold : FontWeight.normal,
                      color: accentColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Закрити")
          )
        ],
      ),
    );
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
    // Тут твій POST запит
  }
}