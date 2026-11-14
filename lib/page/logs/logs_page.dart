import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import '../refreshable_state.dart';

class LogsPage extends StatefulWidget {
  final LocationType location;
  const LogsPage({super.key, required this.location});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends RefreshableState<LogsPage> {
  String _appLogs = "Завантаження...";
  bool _isLoading = true;

  @override
  void refresh() {
    debugPrint("Manual refresh triggered for LogsPage");
    setState(() => _isLoading = true);
    _fetchData();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
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
    _fetchData();
  }

  String _getApiUrl() {
    return '${ApiServerHelper.backendUrl}${AppHelper.apiPathLogs}${AppHelper.pathApp}';
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(_getApiUrl()),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _appLogs = response.body;
          });
        }
      } else {
        throw Exception("Статус сервера: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Logs fetch error: $e");
      if (mounted) {
        setState(() {
          _appLogs = "Помилка завантаження: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isLinux) {
      return await getDownloadsDirectory();
    } else if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        return dir;
      }
      return await getExternalStorageDirectory();
    }
    return await getDownloadsDirectory();
  }

  Future<void> _exportLogsToFile() async {
    if (_appLogs.trim().isEmpty ||
        _appLogs == "Завантаження..." ||
        _appLogs == "Оновлення...") {
      return;
    }

    try {
      final dir = await _getDownloadsDirectory();
      if (dir == null) {
        throw Exception("Не вдалося визначити папку Downloads");
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'logs_${widget.location.name}_$timestamp.log';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(_appLogs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Збережено: ${file.path}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Export logs error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Помилка збереження: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Logs (${_appLogs.split('\n').where((l) => l.trim().isNotEmpty).length} рядків)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _exportLogsToFile,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Export to file", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildAppTerminal()),
        ],
      ),
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
          reverse: true,
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