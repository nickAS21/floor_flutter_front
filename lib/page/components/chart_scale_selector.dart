import 'package:flutter/material.dart';

class ChartScaleSelector extends StatelessWidget {
  final double currentScale;
  final ValueChanged<double> onScaleChanged;

  const ChartScaleSelector({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Форматуємо масштаб у відсотки (наприклад, 1.0 -> "100%", 1.5 -> "150%")
    final String scalePercent = "${(currentScale * 100).toInt()}%";

    return PopupMenuButton<double>(
      initialValue: currentScale,
      onSelected: onScaleChanged,
      // Відображаємо лупу та текст масштабу в одній кнопці
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.zoom_in, size: 20),
            const SizedBox(width: 2),
            Text(
              scalePercent,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<double>>[
        const PopupMenuItem<double>(value: 1.0, child: Text('100%')),
        const PopupMenuItem<double>(value: 1.2, child: Text('120%')),
        const PopupMenuItem<double>(value: 1.5, child: Text('150%')),
        const PopupMenuItem<double>(value: 2.0, child: Text('200%')),
        const PopupMenuItem<double>(value: 3.0, child: Text('300%')),
      ],
    );
  }
}