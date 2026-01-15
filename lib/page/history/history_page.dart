import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import '../unit/unit_helper.dart';
import 'history_model.dart';


class HistoryPage extends StatefulWidget {
  final LocationType location;
  const HistoryPage({super.key, required this.location});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<HistoryModel> _allRecords = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchData();
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Helpers (Логіка іконок та кольорів ідентична UnitPage) ---

  IconData _getConnIcon(String? status) {
    if (status?.toUpperCase() == 'ACTIVE' || status?.toUpperCase() == 'ONLINE') return Icons.cloud_done;
    if (status?.toUpperCase() == 'STANDBY') return Icons.access_time_filled;
    return Icons.cloud_off;
  }

  Color _getConnColor(String? status) {
    if (status?.toUpperCase() == 'ACTIVE' || status?.toUpperCase() == 'ONLINE') return Colors.green;
    if (status?.toUpperCase() == 'STANDBY') return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'charging': return Colors.green;
      case 'discharging': return Colors.red;
      case 'static': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatHex(String hex) {
    if (hex.isEmpty) return "0x0000";
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    return "0x${cleanHex.padLeft(4, '0').toUpperCase()}";
  }

  bool _hasRealError(String hex) {
    if (hex.isEmpty) return false;
    String cleanHex = hex.toLowerCase().replaceAll('0x', '');
    final val = int.tryParse(cleanHex, radix: 16);
    return val != null && val > 0;
  }

  // --- Завантаження даних ---

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      String loc = widget.location == LocationType.golego ? AppHelper.pathGolego : AppHelper.pathDacha;
      String day = _tabController.index == 0 ? AppHelper.pathToday : AppHelper.pathYesterday;
      String url = '${ApiServerHelper.backendUrl}${AppHelper.apiPathHistory}$loc$day';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _allRecords = jsonData.map((json) => HistoryModel.fromJson(json)).toList();
          _allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Діалогові вікна деталей ---

  void _showBatteryDetailsDialog(Map<String, dynamic> b) {
    bool isError = _hasRealError(b['errorInfoDataHex'] ?? '');
    double delta = (b['deltaMv'] ?? 0.0).toDouble();
    bool isCriticalDelta = delta >= UnitHelper.cellsCriticalDeltaMin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(widget.location == LocationType.dacha ? "Акумулятор" : "Battery ${b['port'] ?? '0'}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _detailRow("Зв'язок", b['connectionStatus'] ?? "N/A", valueColor: _getConnColor(b['connectionStatus'])),
              _detailRow("Оновлено", b['timestamp'] ?? '', valueColor: Colors.grey),
              _detailRow("Напруга", "${(b['voltageCurV'] ?? 0.0).toStringAsFixed(2)} V"),
              _detailRow("Заряд (SOC)", "${(b['socPercent'] ?? 0.0).toStringAsFixed(1)}%", valueColor: Colors.blue),
              _detailRow("Струм", "${b['currentCurA'] ?? 0.0} A"),
              _detailRow("Статус BMS", b['bmsStatusStr'] ?? '', valueColor: _getStatusColor(b['bmsStatusStr'] ?? '')),
              if (b['bmsTempValue'] != null)
                _detailRow("Температура BMS", "${(b['bmsTempValue'] as num).toStringAsFixed(2)}°C"),
              _detailRow(
                  "Помилка (HEX)",
                  _formatHex(b['errorInfoDataHex'] ?? ''),
                  valueColor: isError ? Colors.red : (isCriticalDelta ? Colors.orange : Colors.green)
              ),
              const Divider(),
              _detailRow("Delta", "${delta.toStringAsFixed(3)} V", valueColor: isCriticalDelta ? Colors.red : Colors.green),
              if (b['cellVoltagesV'] != null)
                ...(b['cellVoltagesV'] as Map).entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Комірка ${e.key}", style: const TextStyle(fontSize: 12)),
                      Text("${(e.value as num).toStringAsFixed(3)} V", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрити"))
        ],
      ),
    );
  }

  void _showDetails(HistoryModel record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final data = record.dataHome ?? {};
          final List<dynamic> batteries = record.batteries ?? [];

          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Запис за ${record.timeOnly}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _statusBadge(record.gridStatusRealTimeOnLine),
                  ],
                ),
                const Divider(height: 30),

                _detailRow("Заряд системи", "${record.batterySoc.toInt()}%", valueColor: Colors.orange),
                _detailRow("Напруга АКБ", "${record.batteryVol.toStringAsFixed(2)} V"),
                _detailRow("Статус роботи", record.batteryStatus, valueColor: _getStatusColor(record.batteryStatus)),

                if (batteries.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("СИСТЕМА АКУМУЛЯТОРІВ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                  ),
                  ...batteries.map((b) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => _showBatteryDetailsDialog(b), // Відкриття деталей модуля
                      leading: Icon(_getConnIcon(b['connectionStatus']), color: _getConnColor(b['connectionStatus']), size: 30),
                      title: Text(widget.location == LocationType.dacha ? "Акумулятор" : "Battery ${b['port'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("${(b['socPercent'] ?? 0).toInt()}% | ${(b['voltageCurV'] ?? 0).toStringAsFixed(2)}V | ${b['bmsStatusStr'] ?? ''}"),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    ),
                  )),
                ],

                const Divider(height: 30),
                const Text("ПОТУЖНІСТЬ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                _detailRow("Сонячна панель", "${data['solarPower'] ?? 0} W"),
                _detailRow("Споживання дому", "${data['homePower'] ?? 0} W"),
                _detailRow("Навантаження Grid", "${data['gridPower'] ?? 0} W"),

                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Напруга по фазах:", style: TextStyle(color: Colors.grey, fontSize: 13))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _phaseBox("L1", "${data['gridVoltageLs']?['1'] ?? 0}V"),
                  _phaseBox("L2", "${data['gridVoltageLs']?['2'] ?? 0}V"),
                  _phaseBox("L3", "${data['gridVoltageLs']?['3'] ?? 0}V"),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Базові компоненти інтерфейсу ---

  Widget _phaseBox(String label, String value) => Expanded(child: Column(children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]));

  Widget _detailRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? Colors.black87)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, backgroundColor: Theme.of(context).scaffoldBackgroundColor, bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "СЬОГОДНІ"), Tab(text: "ВЧОРА")])),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _allRecords.length,
          itemBuilder: (context, index) => _buildCard(_allRecords[index]),
        ),
      ),
    );
  }

  Widget _buildCard(HistoryModel record) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showDetails(record),
        child: IntrinsicHeight(child: Row(children: [
          Container(width: 65, alignment: Alignment.center, color: Colors.blueGrey.shade50, child: Text(record.timeOnly, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statusBadge(record.gridStatusRealTimeOnLine),
            Text("${record.batterySoc.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
            Text(record.batteryStatus, style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(record.batteryStatus), fontSize: 13)),
            Text("${record.batteryVol.toStringAsFixed(1)}V", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ]))),
        ])),
      ),
    );
  }

  Widget _statusBadge(bool online) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: online ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: online ? Colors.green : Colors.red, width: 0.5)),
    child: Text(online ? "GRID ONLINE" : "GRID OFFLINE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: online ? Colors.green : Colors.red)),
  );
}