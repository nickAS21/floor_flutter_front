import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'history_model.dart';
import 'history_card.dart';
import 'history_details_sheet.dart';
import '../unit/unit_helper.dart';

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
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _resetAndFetch();
    }
  }

  void _resetAndFetch() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _allRecords = [];
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    // Завжди вмикаємо лоадер перед початком
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

        // Використовуємо try-catch всередині map для безпеки
        final records = jsonData.map((json) {
          try {
            return HistoryModel.fromJson(json);
          } catch (e) {
            debugPrint("History row parse error: $e");
            return null;
          }
        }).whereType<HistoryModel>().toList();

        records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (mounted) {
          setState(() {
            _allRecords = records;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка зв'язку: $e")),
        );
      }
    } finally {
      // Ключовий момент: вимикаємо лоадер у будь-якому випадку
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Спільний метод діалогу для батареї (викликається з Sheet)
  void _showBatteryDialog(Map<String, dynamic> b) {
    // 1. Отримуємо дані про комірки з Map
    final cellVoltages = b['cellVoltagesV'] as Map<String, dynamic>? ?? {};

    // 2. Сортуємо ключі комірок по порядку (1, 2, 3...)
    final sortedKeys = cellVoltages.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

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
              _dialogRow("Зв'язок", b['connectionStatus'], UnitHelper.getConnectionColor(b['connectionStatus'])),
              _dialogRow("Напруга", "${(b['voltageCurV'] ?? 0.0).toStringAsFixed(2)} V", null),
              _dialogRow("Заряд", "${(b['socPercent'] ?? 0.0).toInt()}%", Colors.blue),
              _dialogRow("Статус BMS", b['bmsStatusStr'], UnitHelper.getStatusColor(b['bmsStatusStr'] ?? '')),
              _dialogRow("Помилка", UnitHelper.formatHex(b['errorInfoDataHex']),
                  UnitHelper.hasRealError(b['errorInfoDataHex']) ? Colors.red : Colors.green),
              const Divider(),
              _dialogRow("Delta", "${(b['deltaMv'] ?? 0.0).toStringAsFixed(3)} V",
                  (b['deltaMv'] ?? 0.0) >= UnitHelper.cellsCriticalDeltaMin ? Colors.red : Colors.green),

              // --- НОВИЙ БЛОК: Список комірок ---
              if (sortedKeys.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Напруга комірок (V):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: sortedKeys.map((key) {
                      return Text(
                        "C$key: ${(cellVoltages[key] as num).toStringAsFixed(3)}",
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрити"))
        ],
      ),
    );
  }

  Widget _dialogRow(String l, String? v, Color? c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(fontSize: 14)),
        Text(v ?? '--', style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 14)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: "СЬОГОДНІ"), Tab(text: "ВЧОРА")]
          )
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: _allRecords.isEmpty
            ? const Center(child: Text("Дані відсутні"))
            : ListView.builder(
          itemCount: _allRecords.length,
          itemBuilder: (context, i) => HistoryCard(
            record: _allRecords[i],
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => HistoryDetailsSheet(
                record: _allRecords[i],
                location: widget.location,
                onBatteryTap: _showBatteryDialog,
              ),
            ),
          ),
        ),
      ),
    );
  }
}