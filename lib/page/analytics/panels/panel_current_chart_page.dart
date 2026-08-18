import 'package:flutter/material.dart';
import '../panel_info_model.dart';
import 'base_panel_chart_page.dart';

class PanelCurrentChartPage extends BasePanelChartPage {
  const PanelCurrentChartPage({
    super.key,
    required super.location,
    required super.chartScale,
    required super.selectedDate,
    required super.onDateChanged,
  });

  @override
  State<PanelCurrentChartPage> createState() => _PanelCurrentChartPageState();
}

class _PanelCurrentChartPageState extends BasePanelChartPageState<PanelCurrentChartPage> {
  @override
  PanelMetricType get metricType => PanelMetricType.current;

  @override
  double getPanelValue(PanelInfoModel? panel) => panel?.pvCurrentCurA ?? 0.0;

  @override
  double get yStep => 10.0;
}