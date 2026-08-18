import 'package:flutter/material.dart';
import '../panel_info_model.dart';
import 'base_panel_chart_page.dart';

class PanelVoltageChartPage extends BasePanelChartPage {
  const PanelVoltageChartPage({
    super.key,
    required super.location,
    required super.chartScale,
    required super.selectedDate,
    required super.onDateChanged,
  });

  @override
  State<PanelVoltageChartPage> createState() => _PanelVoltageChartPageState();
}

class _PanelVoltageChartPageState extends BasePanelChartPageState<PanelVoltageChartPage> {
  @override
  PanelMetricType get metricType => PanelMetricType.voltage;

  @override
  double getPanelValue(PanelInfoModel? panel) => panel?.pvVoltageCurV ?? 0.0;

  @override
  double get yStep => 20.0;
}