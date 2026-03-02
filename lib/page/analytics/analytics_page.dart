import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../helpers/app_helper.dart';
import '../data_home/data_location_type.dart';
import 'analitic_model.dart';
import 'analytic_enums.dart';
import 'anaytic_connect_service.dart';

class AnalyticsPage extends StatefulWidget {
  final LocationType location;
  const AnalyticsPage({super.key, required this.location});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticConnectService _service = AnalyticConnectService();

  List<AnalyticModel> _allData = [];
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  ViewMode _currentMode = ViewMode.day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<AnalyticModel> data = [];

      if (_currentMode == ViewMode.period) {
        data = await _service.getAnalyticDays(
          dateStart: _startDate,
          dateFinish: _endDate,
          location: widget.location,
          powerType: PowerType.GRID,
        );
      } else {
        switch (_currentMode) {
          case ViewMode.day:
            data = await _service.getAnalyticDay(
              date: _selectedDate,
              location: widget.location,
              powerType: PowerType.GRID,
            );
            break;
          case ViewMode.month:
            data = await _service.getAnalyticMonth(
              date: _selectedDate,
              location: widget.location,
              powerType: PowerType.GRID,
            );
            break;
          case ViewMode.year:
            data = await _service.getAnalyticYear(
              year: _selectedDate.year,
              location: widget.location,
              powerType: PowerType.GRID,
            );
            break;
          default: break;
        }
      }

      if (mounted) {
        setState(() {
          _allData = data..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ДІАЛОГ ВИБОРУ ПЕРІОДУ ---
  Future<void> _selectRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        DateTime tempStart = _startDate;
        DateTime tempEnd = _endDate;
        bool selectingStart = true; // Стан вибору

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Column(
                children: [
                  const Text(
                      "Оберіть період",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => setDialogState(() => selectingStart = true),
                        child: _buildDateBox(tempStart, isActive: selectingStart),
                      ),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      GestureDetector(
                        onTap: () => setDialogState(() => selectingStart = false),
                        child: _buildDateBox(tempEnd, isActive: !selectingStart),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectingStart ? tempStart : tempEnd,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (date) {
                      setDialogState(() {
                        if (selectingStart) {
                          tempStart = date;
                          selectingStart = false; // Авто-перемикання
                          if (tempEnd.isBefore(tempStart)) {
                            tempEnd = tempStart.add(const Duration(days: 1));
                          }
                        } else {
                          if (date.isBefore(tempStart)) {
                            tempStart = date;
                          } else {
                            tempEnd = date;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("СКАСУВАТИ", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, DateTimeRange(start: tempStart, end: tempEnd)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white
                  ),
                  child: const Text("ЗАСТОСУВАТИ"),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentMode = ViewMode.period;
      });
      _fetchData();
    }
  }

  Widget _buildDateBox(DateTime date, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.deepPurple : Colors.deepPurple.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.deepPurple.withValues(alpha: 0.02),
      ),
      child: Text(
        DateFormat(AppHelper.paternYYYYMMDD).format(date),
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.deepPurple : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        actions: [
          Tooltip(
            message: "Імпортувати дані з Excel",
            child: IconButton(icon: const Icon(Icons.upload_file), onPressed: _importExcel),
          ),
          Tooltip(
            message: "Оновити дані",
            child: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          ),
          Tooltip(
            message: "Обрати конкретний день",
            child: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _currentMode = ViewMode.day;
                  });
                  _fetchData();
                }
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSelectors(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allData.isEmpty
                  ? const Center(child: Text("Дані відсутні за цей період"))
                  : _buildChart(_allData),
            ),
            if (_allData.isNotEmpty) _buildStats(_allData.last),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    String subTitle = _currentMode == ViewMode.period
        ? "${DateFormat(AppHelper.paternMMDD).format(_startDate)} - ${DateFormat(AppHelper.paternMMDD).format(_endDate)}"
        : DateFormat(AppHelper.paternYYYYMMDD).format(_selectedDate);

    return GestureDetector(
      onTap: () {
        if (_currentMode == ViewMode.period) _selectRange();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Аналітика: ${widget.location.label}"),
          Row(
            children: [
              Text(subTitle, style: const TextStyle(fontSize: 12)),
              if (_currentMode == ViewMode.period)
                const Icon(Icons.edit, size: 12, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return SegmentedButton<ViewMode>(
      segments: const [
        ButtonSegment(value: ViewMode.day, label: Text('День')),
        ButtonSegment(value: ViewMode.month, label: Text('Місяць')),
        ButtonSegment(value: ViewMode.year, label: Text('Рік')),
        ButtonSegment(value: ViewMode.period, label: Text('Період')),
      ],
      selected: {_currentMode},
      onSelectionChanged: (newSelection) async {
        final mode = newSelection.first;
        if (mode == ViewMode.period) {
          await _selectRange();
        } else {
          setState(() => _currentMode = mode);
          _fetchData();
        }
      },
    );
  }

  // --- Методи Excel та Графіку ---
  Future<void> _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx']
    );

    if (result != null) {
      // 1. Вмикаємо лоадер
      setState(() => _isLoading = true);

      // 2. ДАЄМО ПАУЗУ! Це критично, щоб Flutter встиг показати кружочок
      // перед тим, як почнеться важкий парсинг
      await Future.delayed(const Duration(milliseconds: 150));

      try {
        final bytes = await File(result.files.single.path!).readAsBytes();

        // Виклик твого сервісу
        final models = _service.processExcelData(bytes: bytes, location: widget.location);

        if (models.isNotEmpty) {
          final success = await _service.importXmlsData(models);
          if (success) {
            await _fetchData();
            _showSnackBar("Успішно імпортовано ${models.length} записів");
          } else {
            _showSnackBar("Помилка на стороні сервера", isError: true);
          }
        } else {
          // Якщо таблиці порожні, ми тепер хоча б кажемо про це
          _showSnackBar("У файлі не знайдено таблиць. Перевірте, чи це точно .xlsx", isError: true);
        }
      } catch (e) {
        _showSnackBar("Помилка парсингу: $e", isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null),
    );
  }

  Widget _buildChart(List<AnalyticModel> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(toY: e.value.powerDay, color: Colors.orange, width: 6),
              BarChartRodData(toY: e.value.powerNight, color: Colors.blue, width: 6),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats(AnalyticModel m) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol("DAY", m.powerDay, Colors.orange),
          _statCol("NIGHT", m.powerNight, Colors.blue),
          _statCol("TOTAL", m.powerTotal, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _statCol(String l, double v, Color c) => Column(
    children: [
      Text(l, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
      Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ],
  );
}