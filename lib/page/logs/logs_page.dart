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
  bool _isExporting = false;

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

  Future<void> _exportLogsToFile(String period) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      String? contentToSave;
      String fileTag = period;
      String? fetchError;

      // 1. Намагаємося отримати логи з нового API (/app/current або /app/previous)
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken') ?? '';

        final url = '${_getApiUrl()}/$period';
        final response = await http.get(
          Uri.parse(url),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 &&
            response.body.trim().isNotEmpty &&
            response.body.trim() != 'null') {
          contentToSave = response.body;
        } else if (response.statusCode != 200) {
          fetchError = "Статус сервера: ${response.statusCode}";
        }
      } catch (e) {
        debugPrint("Export API ($period) error: $e");
        fetchError = e.toString();
      }

      // 2. Якщо повернувся null, порожньо або сталася помилка — пропонуємо зберегти з буфера
      if (contentToSave == null) {
        if (!mounted) return;
        final useBuffer = await _askFallbackToBuffer(period, fetchError);
        if (!useBuffer) return;

        if (_appLogs.trim().isEmpty ||
            _appLogs == "Завантаження..." ||
            _appLogs == "Оновлення...") {
          throw Exception("Оперативний буфер також порожній");
        }
        contentToSave = _appLogs;
        fileTag = 'buffer';
      }

      // 3. Зберігаємо файл у Downloads
      final dir = await _getDownloadsDirectory();
      if (dir == null) {
        throw Exception("Не вдалося визначити папку Downloads");
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'logs_${widget.location.name}_${fileTag}_$timestamp.log';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(contentToSave);

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
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<bool> _askFallbackToBuffer(String period, [String? errorDetails]) async {
    final periodLabel = period == 'previous' ? 'попередній день' : 'поточний день';
    final Color statusColor = errorDetails != null ? Colors.red : Colors.orange;
    final String reasonText = errorDetails != null
        ? "Не вдалося отримати логи за $periodLabel ($errorDetails)."
        : "Логи за $periodLabel відсутні (повернувся null або порожній файл).";

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: statusColor, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Файл логів відсутній",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                reasonText,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Вивантажити логи з поточного буфера (по-старому)?",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Закрити"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.download, size: 18),
            label: const Text("Зберегти з буфера"),
          ),
        ],
      ),
    );
    return result ?? false;
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
                _isExporting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : PopupMenuButton<String>(
                  onSelected: _exportLogsToFile,
                  tooltip: "Export logs",
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'current',
                      child: Row(
                        children: [
                          Icon(Icons.today, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Current (Поточний)"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'previous',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text("Previous (Попередній)"),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Export to file",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
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