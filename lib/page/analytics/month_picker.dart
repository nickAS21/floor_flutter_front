

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const MonthPicker({super.key, required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final List<String> months = [
      "Січ", "Лют", "Бер", "Квіт", "Трав", "Чер",
      "Лип", "Серп", "Вер", "Жовт", "Лист", "Груд"
    ];

    return Column(
      children: [
        // Вибір року всередині місячного пікера
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => onChanged(DateTime(selectedDate.year - 1, selectedDate.month)),
            ),
            Text("${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => onChanged(DateTime(selectedDate.year + 1, selectedDate.month)),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final isSelected = selectedDate.month == index + 1;
              return InkWell(
                onTap: () => onChanged(DateTime(selectedDate.year, index + 1)),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    months[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}