import 'package:flutter/material.dart';

abstract class RefreshableState<T extends StatefulWidget> extends State<T> {
  void refresh();

  // Глобальний масштаб для всіх сторінок
  double chartScale = 1.0;

  // Універсальний селектор масштабу
  Widget buildScaleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // Використовуємо modern alpha замість opacity
        color: Colors.black.withValues(alpha: 0.05),
      ),
      child: DropdownButton<double>(
        value: chartScale,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
        icon: const Icon(Icons.zoom_in, size: 16, color: Colors.black),
        items: [1.0, 1.2, 1.5, 2.0, 3.0].map((double value) {
          return DropdownMenuItem<double>(
            value: value,
            child: Text("${(value * 100).toInt()}%"),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() => chartScale = newValue);
          }
        },
      ),
    );
  }
}