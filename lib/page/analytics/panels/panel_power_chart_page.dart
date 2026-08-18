import 'package:flutter/material.dart';
import '../panel_info_model.dart';
import 'base_panel_chart_page.dart';

class PanelPowerChartPage extends BasePanelChartPage {
  const PanelPowerChartPage({
    super.key,
    required super.location,
    required super.chartScale,
    required super.selectedDate,
    required super.onDateChanged,
  });

  @override
  State<PanelPowerChartPage> createState() => _PanelPowerChartPageState();
}

class _PanelPowerChartPageState extends BasePanelChartPageState<PanelPowerChartPage> {
  @override
  PanelMetricType get metricType => PanelMetricType.power;

  @override
  double getPanelValue(PanelInfoModel? panel) => panel?.pvPowerCurW ?? 0.0;

  @override
  double get yStep => 50.0;
}