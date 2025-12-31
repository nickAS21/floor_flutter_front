import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';

class AnalyticsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsPage({super.key, required this.location});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = false;
  String _selectedMetric = "Voltage";
  List<dynamic> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant AnalyticsPage oldWidget) {
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

    // ВИКОРИСТОВУЄМО ТІЛЬКИ ЗАТВЕРДЖЕНИЙ ФОРМАТ URL
    String apiUrl = widget.location == LocationType.dacha
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathAnalytics}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathAnalytics}${AppHelper.pathGolego}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        setState(() {
          _chartData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Час очікування вичерпано (60 сек)");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Помилка завантаження: $e");
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMetric,
                    isExpanded: true,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87),
                    items: ["Voltage", "Capacity", "Power", "Temp"].map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMetric = val);
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blueGrey.shade600, size: 22),
                onPressed: _fetchData,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.show_chart,
                      size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  const Text(
                    "Аналітичні графіки",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Метрика: $_selectedMetric",
                    style: TextStyle(
                        color: Colors.blue.shade700, fontSize: 16),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    child: Text(
                      "Тут буде візуалізація за останні 48 годин на основі отриманих даних.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}