import 'dart:math' as math;
import 'package:flutter/material.dart';

class DataHomePainter extends CustomPainter {
  static const double _powerThreshold = 5.0;
  final double progress;
  final double solarPower, batteryPower, loadPower, gridPower;
  final bool gridActive;
  final bool gridSwitch;
  final String timestampLastUpdateGridStatus;
  final double solarY, inverterY, gridY, bottomNodesY, sideNodesX;

  DataHomePainter({
    required this.progress,
    required this.solarPower,
    required this.batteryPower,
    required this.loadPower,
    required this.gridActive,
    required this.gridSwitch,
    required this.timestampLastUpdateGridStatus,
    required this.gridPower,
    required this.solarY,
    required this.inverterY,
    required this.gridY,
    required this.bottomNodesY,
    required this.sideNodesX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double nodeRadius = 60.0;
    const double invRadius = 25.0;
    const double cornerR = 40.0;
    const double step = 15.0;
    const double hOffset = -30.0;

    Offset getOffset(double x, double y) => Offset((x + 1) * size.width / 2, (y + 1) * size.height / 2);

    final solarC = getOffset(0, solarY);
    final invC = getOffset(0, inverterY);
    final batC = getOffset(-sideNodesX, bottomNodesY);
    final gridC = getOffset(0, gridY);
    final loadC = getOffset(sideNodesX, bottomNodesY);

    final defaultPaint = Paint()..color = Colors.blueGrey.withValues(alpha:0.6);
    final gridPaint = Paint()..color = gridActive ? Colors.green.withValues(alpha:0.8) : Colors.red.withValues(alpha:0.8);

    // Маршрути (лінії з крапок)
    _drawStraightRoute(canvas, solarC, invC, defaultPaint, nodeRadius, invRadius, step);
    _drawStraightRoute(canvas, gridC, invC, gridPaint, nodeRadius, invRadius, step);
    _drawRoundedRoute(canvas, invC, batC, defaultPaint, true, invRadius, nodeRadius, cornerR, step, hOffset);
    _drawRoundedRoute(canvas, invC, loadC, defaultPaint, false, invRadius, nodeRadius, cornerR, step, hOffset);

    // Анімація комет зі стрілками
    if (solarPower > _powerThreshold) {
      _drawStraightComet(canvas, solarC, invC, progress, false, nodeRadius, invRadius);
    }

    if (gridSwitch && gridActive && gridPower > _powerThreshold) {
      _drawStraightComet(canvas, gridC, invC, progress, false, nodeRadius, invRadius);
    }

    if (batteryPower.abs() > _powerThreshold) {
      _drawRoundedComet(canvas, invC, batC, progress, batteryPower < 0, true, invRadius, nodeRadius, cornerR, hOffset);
    }

    if (loadPower > _powerThreshold) {
      _drawRoundedComet(canvas, invC, loadC, progress, false, false, invRadius, nodeRadius, cornerR, hOffset);
    }

    if (!gridActive) _drawX(canvas, Offset.lerp(gridC, invC, 0.5)!);
  }

  void _drawStraightRoute(Canvas canvas, Offset p1, Offset p2, Paint paint, double r1, double r2, double step) {
    double dist = (p2 - p1).distance;
    for (double i = r1; i <= dist - r2; i += step) {
      canvas.drawCircle(Offset.lerp(p1, p2, i / dist)!, 1.5, paint);
    }
  }

  void _drawRoundedRoute(Canvas canvas, Offset start, Offset end, Paint paint, bool isLeft, double rStart, double rEnd, double rCurve, double step, double hOffset) {
    double horizLen = (end.dx - start.dx).abs() - rCurve + hOffset;
    double curveLen = (math.pi / 2) * rCurve;
    double pivotX = start.dx + horizLen * (isLeft ? -1 : 1);
    for (double i = rStart; i < horizLen; i += step) {
      canvas.drawCircle(Offset(start.dx + i * (isLeft ? -1 : 1), start.dy), 1.5, paint);
    }
    int curvePts = (curveLen / step).floor();
    for (int i = 0; i <= curvePts; i++) {
      double a = (i * step / curveLen) * (math.pi / 2);
      canvas.drawCircle(Offset(pivotX + (isLeft ? -rCurve * math.sin(a) : rCurve * math.sin(a)), start.dy + rCurve * (1 - math.cos(a))), 1.5, paint);
    }
    double finalX = pivotX + (isLeft ? -rCurve : rCurve);
    for (double i = start.dy + rCurve; i <= end.dy - rEnd; i += step) {
      canvas.drawCircle(Offset(finalX, i), 1.5, paint);
    }
  }

  void _drawStraightComet(Canvas canvas, Offset start, Offset end, double t, bool rev, double r1, double r2) {
    double dist = (end - start).distance;
    double curPos = r1 + (dist - r1 - r2) * (rev ? 1.0 - t : t);
    for (int i = 0; i < 20; i++) {
      double d = curPos + (rev ? i * 4.5 : -i * 4.5);
      if (d < r1 || d > dist - r2) continue;
      Offset pos = Offset.lerp(start, end, d / dist)!;
      double opacity = (1.0 - (i / 20)).clamp(0, 1);
      canvas.drawCircle(pos, 4.0 * opacity, Paint()..color = Colors.blue.withValues(alpha: opacity * 0.7));
      if (i == 0) _drawArrowHead(canvas, pos, (end - start).direction + (rev ? math.pi : 0));
    }
  }

  void _drawRoundedComet(Canvas canvas, Offset start, Offset end, double t, bool toInv, bool isLeft, double rStart, double rEnd, double rCurve, double hOffset) {
    double hL = (end.dx - start.dx).abs() - rCurve + hOffset;
    double cL = (math.pi / 2) * rCurve;
    double vL = (end.dy - start.dy).abs() - rCurve;
    double total = hL + cL + vL;
    double cD = rStart + (total - rStart - rEnd) * (toInv ? 1.0 - t : t);

    Offset getPoint(double d) {
      if (d < hL) return Offset(start.dx + d * (isLeft ? -1 : 1), start.dy);
      if (d < hL + cL) {
        double a = ((d - hL) / cL) * (math.pi / 2);
        return Offset(start.dx + hL * (isLeft ? -1 : 1) + (isLeft ? -rCurve * math.sin(a) : rCurve * math.sin(a)), start.dy + rCurve * (1 - math.cos(a)));
      }
      return Offset(start.dx + (hL + rCurve) * (isLeft ? -1 : 1), start.dy + rCurve + (d - hL - cL));
    }

    for (int i = 0; i < 20; i++) {
      double d = cD + (toInv ? i * 4.5 : -i * 4.5);
      if (d < rStart || d > total - rEnd) continue;
      Offset pos = getPoint(d);
      double opacity = (1.0 - (i / 20)).clamp(0, 1);
      canvas.drawCircle(pos, 4.0 * opacity, Paint()..color = Colors.blue.withValues(alpha: opacity * 0.7));
      if (i == 0) {
        double angle = (getPoint(d + (toInv ? -1 : 1)) - pos).direction;
        _drawArrowHead(canvas, pos, angle);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset pos, double angle) {
    final path = Path();
    path.moveTo(pos.dx - 10 * math.cos(angle - 0.5), pos.dy - 10 * math.sin(angle - 0.5));
    path.lineTo(pos.dx, pos.dy);
    path.lineTo(pos.dx - 10 * math.cos(angle + 0.5), pos.dy - 10 * math.sin(angle + 0.5));
    canvas.drawPath(path, Paint()..color = Colors.blue..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  void _drawX(Canvas canvas, Offset pos) {
    final p = Paint()..color = Colors.red..strokeWidth = 3;
    canvas.drawLine(pos + const Offset(-8, -8), pos + const Offset(8, 8), p);
    canvas.drawLine(pos + const Offset(8, -8), pos + const Offset(-8, 8), p);
  }

  @override
  bool shouldRepaint(covariant DataHomePainter oldDelegate) => true;
}