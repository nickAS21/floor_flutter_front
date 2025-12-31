import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';

class AlarmPage extends StatefulWidget {
  final LocationType location;
  const AlarmPage({super.key, required this.location});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  bool _isLoading = true;
  List<dynamic> _alarms = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant AlarmPage oldWidget) {
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
        ? '${ApiServerHelper.backendUrl}${AppHelper.apiPathAlarm}${AppHelper.pathDacha}'
        : '${ApiServerHelper.backendUrl}${AppHelper.apiPathAlarm}${AppHelper.pathGolego}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        setState(() {
          _alarms = jsonDecode(response.body);
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  "SYSTEM ALARMS",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
            const SizedBox(height: 16),
            const Text(
              "Критичних помилок не виявлено",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text(
                alarm['message'] ?? 'Невідома помилка',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                alarm['timestamp'] ?? '',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alarm['code'] ?? 'ERR',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}