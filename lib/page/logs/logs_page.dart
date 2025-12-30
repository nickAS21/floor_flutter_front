import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';

class LogsPage extends StatefulWidget {
  final LocationType location;
  const LogsPage({super.key, required this.location});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String _dachaLogs = "Завантаження...";
  List<dynamic> _golegoLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void didUpdateWidget(covariant LogsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _resetAndFetch();
  }

  void _resetAndFetch() {
    setState(() {
      _isLoading = true;
      _dachaLogs = "Оновлення...";
      _golegoLogs = [];
    });
    _fetchLogs();
  }

  String _getApiUrl() {
    String path = widget.location == LocationType.dacha ? AppHelper.pathDacha : AppHelper.pathGolego;
    return '${ApiServerHelper.backendUrl}${AppHelper.apiPathLogs}$path';
  }

  Future<void> _fetchLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(_getApiUrl()),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          if (widget.location == LocationType.dacha) {
            // Оптимізація: обрізаємо занадто старі дані для економії пам'яті
            _dachaLogs = response.body;
          } else {
            _golegoLogs = jsonDecode(response.body)['data'] ?? [];
          }
          _isLoading = false;
        });
      } else {
        throw Exception("Server status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _dachaLogs = "Помилка: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logs: ${widget.location == LocationType.dacha ? 'Дача' : 'Golego'}"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _resetAndFetch)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.location == LocationType.golego
          ? _buildGolegoTable()
          : _buildDachaTerminal(),
    );
  }

  Widget _buildDachaTerminal() {
    final List<String> lines = _dachaLogs.split('\n');

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.black),
      child: SelectionArea(
        child: ListView.builder(
          reverse: true, // Нові записи внизу, скрол починається знизу
          itemCount: lines.length,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            final line = lines[lines.length - 1 - index];
            if (line.trim().isEmpty) return const SizedBox.shrink();
            return Text(
              line,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.3,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGolegoTable() {
    if (_golegoLogs.isEmpty) return const Center(child: Text("Дані відсутні"));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('P/A')),
            DataColumn(label: Text('SOC')),
            DataColumn(label: Text('V/A')),
          ],
          rows: _golegoLogs.map((item) => DataRow(cells: [
            DataCell(Text(item['timestamp']?.substring(11, 19) ?? '--')),
            DataCell(Text("${item['port']}/${item['addr']}")),
            DataCell(Text("${item['soc']}%")),
            DataCell(Text("${item['v']}V / ${item['a']}A")),
          ])).toList(),
        ),
      ),
    );
  }
}