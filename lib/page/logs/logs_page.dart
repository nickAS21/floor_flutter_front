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
  String _appLogs = "Завантаження...";
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
      _appLogs = "Оновлення...";
    });
    _fetchLogs();
  }

  String _getApiUrl() {
    return '${ApiServerHelper.backendUrl}${AppHelper.apiPathLogs}${AppHelper.pathApp}';
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
          _appLogs = response.body;
          _isLoading = false;
        });
      } else {
        throw Exception("Server status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _appLogs = "Помилка: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAppTerminal(),
    );
  }

  Widget _buildAppTerminal() {
    final List<String> lines = _appLogs.split('\n');

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.black),
      child: SelectionArea(
        child: ListView.builder(
          reverse: true, // Нові записи внизу
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
}