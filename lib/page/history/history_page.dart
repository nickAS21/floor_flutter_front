import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
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
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    // Твій затверджений формат URL
    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathHistory}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathHistory}${AppHelper.pathGolego}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        setState(() {
          _allRecords = jsonData.map((json) => HistoryModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } on TimeoutException catch (_) {
      _showSnackBar("Час очікування вичерпано (60 сек)");
    } catch (e) {
      _showSnackBar("Помилка завантаження: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  List<HistoryModel> _filterByDay(bool isToday) {
    if (_allRecords.isEmpty) return [];
    final now = DateTime.now();
    final targetStr = (isToday ? now : now.subtract(const Duration(days: 1))).toString().split(' ')[0];
    return _allRecords.where((r) => r.timestamp.startsWith(targetStr)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                indicatorWeight: 3,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [Tab(text: "TODAY"), Tab(text: "YESTERDAY")],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blueGrey.shade600, size: 22),
              onPressed: _fetchData,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [_buildList(true), _buildList(false)],
      ),
    );
  }

  Widget _buildList(bool isToday) {
    final records = _filterByDay(isToday);
    if (records.isEmpty) {
      return const Center(child: Text("Немає даних", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildCard(records[index]),
    );
  }

  Widget _buildCard(HistoryModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 72,
              color: Colors.grey.shade50,
              alignment: Alignment.center,
              child: Text(
                record.timeOnly,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              record.isGridOnline ? Icons.power : Icons.power_off,
                              size: 15,
                              color: record.isGridOnline ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              record.gridStatus.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: record.isGridOnline ? Colors.green.shade700 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        if (record.gridDuration != null)
                          Text(record.gridDuration!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 12, thickness: 0.5),

                    // Ітерація по списку батарей (Unit)
                    ...record.batteries.map((battery) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _dataBox("V", "${battery.voltageCurV}V"),
                          _dataBox("SoC", "${battery.socPercent.toInt()}%"),
                          _dataBox("A", "${battery.currentCurA}A"),
                          _dataBox("T", "${battery.bmsTempValue ?? '--'}°"),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.blueGrey)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}