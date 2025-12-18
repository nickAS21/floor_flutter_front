import 'dart:math' as math;
import 'package:flutter/material.dart';

class CometFlowPainter extends CustomPainter {
  final double progress;
  final double solarPower, batteryPower, loadPower;
  final bool gridActive;
  final double solarY, inverterY, gridY, bottomNodesY, sideNodesX;

  CometFlowPainter({
    required this.progress,
    required this.solarPower,
    required this.batteryPower,
    required this.loadPower,
    required this.gridActive,
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

    final defaultRoutePaint = Paint()..color = Colors.blueGrey.withOpacity(0.6);

    final gridRoutePaint = Paint()
      ..color = gridActive
          ? Colors.green.withOpacity(0.8) // Зелені крапочки, якщо є мережа
          : Colors.red.withOpacity(0.8);  // Червоні крапочки, якщо немає

    Offset getOffset(double x, double y) {
      return Offset((x + 1) * size.width / 2, (y + 1) * size.height / 2);
    }

    final solarC = getOffset(0, solarY);
    final invC = getOffset(0, inverterY);
    final batC = getOffset(-sideNodesX, bottomNodesY);
    final gridC = getOffset(0, gridY);
    final loadC = getOffset(sideNodesX, bottomNodesY);

    final routePaint = Paint()..color = Colors.blueGrey.withOpacity(0.6);

    _drawStraightRoute(canvas, solarC, invC, defaultRoutePaint, nodeRadius, invRadius, step);
    _drawStraightRoute(canvas, gridC, invC, gridRoutePaint, nodeRadius, invRadius, step);
    _drawRoundedRoute(canvas, invC, batC, defaultRoutePaint, true, invRadius, nodeRadius, cornerR, step, hOffset);
    _drawRoundedRoute(canvas, invC, loadC, defaultRoutePaint, false, invRadius, nodeRadius, cornerR, step, hOffset);

    if (solarPower > 5) {
      _drawStraightComet(canvas, solarC, invC, progress, false, nodeRadius, invRadius);
    }

    if (batteryPower.abs() > 5) {
      // power < 0 (розрядка) -> енергія ВІД батареї ДО інвертора (toInv = true)
      _drawRoundedComet(canvas, invC, batC, progress, batteryPower < 0, true, invRadius, nodeRadius, cornerR, hOffset);
    }

    if (loadPower > 5) {
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
      canvas.drawCircle(Offset(
          pivotX + (isLeft ? -rCurve * math.sin(a) : rCurve * math.sin(a)),
          start.dy + rCurve * (1 - math.cos(a))
      ), 1.5, paint);
    }
    double finalX = pivotX + (isLeft ? -rCurve : rCurve);
    for (double i = start.dy + rCurve; i <= end.dy - rEnd; i += step) {
      canvas.drawCircle(Offset(finalX, i), 1.5, paint);
    }
  }

  void _drawStraightComet(Canvas canvas, Offset start, Offset end, double t, bool rev, double r1, double r2) {
    double dist = (end - start).distance;
    double effT = rev ? (1.0 - t) : t;
    double curPos = r1 + (dist - r1 - r2) * effT;
    for (int i = 0; i < 20; i++) {
      double tailShift = rev ? (i * 4.5) : -(i * 4.5);
      double d = curPos + tailShift;
      if (d < r1 || d > dist - r2) continue;
      Offset pos = Offset.lerp(start, end, d / dist)!;
      double opacity = (1.0 - (i / 20)).clamp(0, 1);
      canvas.drawCircle(pos, 4.0 * opacity, Paint()..color = Colors.blue.withOpacity(opacity * 0.7));
      if (i == 0) _drawArrowHead(canvas, pos, (end - start).direction + (rev ? math.pi : 0));
    }
  }

  void _drawRoundedComet(Canvas canvas, Offset start, Offset end, double t, bool toInv, bool isLeft, double rStart, double rEnd, double rCurve, double hOffset) {
    double horizLen = (end.dx - start.dx).abs() - rCurve + hOffset;
    double vertLen = (end.dy - start.dy).abs() - rCurve;
    double curveLen = (math.pi / 2) * rCurve;
    double totalLen = horizLen + vertLen + curveLen;

    double effT = toInv ? (1.0 - t) : t;
    double curD = rStart + (totalLen - rStart - rEnd) * effT;

    // Допоміжна функція для отримання точки на маршруті в будь-якій дистанції d
    Offset getPointAt(double d) {
      if (d < horizLen) {
        return Offset(start.dx + d * (isLeft ? -1 : 1), start.dy);
      } else if (d < horizLen + curveLen) {
        double a = ((d - horizLen) / curveLen) * (math.pi / 2);
        double pivotX = start.dx + horizLen * (isLeft ? -1 : 1);
        return Offset(
            pivotX + (isLeft ? -rCurve * math.sin(a) : rCurve * math.sin(a)),
            start.dy + rCurve * (1 - math.cos(a))
        );
      } else {
        double pivotX = start.dx + horizLen * (isLeft ? -1 : 1);
        double finalX = pivotX + (isLeft ? -rCurve : rCurve);
        return Offset(finalX, start.dy + rCurve + (d - horizLen - curveLen));
      }
    }

    for (int i = 0; i < 20; i++) {
      // Хвіст слідує за головою
      double tailShift = toInv ? (i * 4.5) : -(i * 4.5);
      double d = curD + tailShift;
      if (d < rStart || d > totalLen - rEnd) continue;

      Offset pos = getPointAt(d);
      double opacity = (1.0 - (i / 20)).clamp(0, 1);
      canvas.drawCircle(pos, 4.0 * opacity, Paint()..color = Colors.blue.withOpacity(opacity * 0.7));

      if (i == 0) {
        // Векторна логіка: порівнюємо поточну точку з точкою на мить попереду
        double delta = toInv ? -0.5 : 0.5;
        Offset nextPos = getPointAt(d + delta);
        double angle = (nextPos - pos).direction;
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
  bool shouldRepaint(covariant CometFlowPainter oldDelegate) => true;
}