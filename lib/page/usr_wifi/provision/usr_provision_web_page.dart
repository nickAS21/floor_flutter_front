import 'package:flutter/material.dart';
import 'usr_provision_utils.dart';

class UsrProvisionWebPage extends StatefulWidget {
  final dynamic selectedLocation; // Тип dynamic, щоб не було конфліктів

  const UsrProvisionWebPage({
    super.key,
    required this.selectedLocation,
  });

  @override
  State<UsrProvisionWebPage> createState() => _UsrProvisionWebPageState();
}

class _UsrProvisionWebPageState extends State<UsrProvisionWebPage> {
  String status = "Отримання даних...";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Column тепер займає лише стільки місця, скільки потрібно кнопці та тексту
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            // КНОПКА (Єдина, що залишилась на малюнку)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => UsrProvisionUtils.openDeviceWeb(),
                icon: const Icon(Icons.open_in_new),
                // Прибираємо const тут, щоб не було помилок компіляції
                label: Text(UsrProvisionUtils.openHttpOn254),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // СТАТУС (як на малюнку внизу)
            if (status.isNotEmpty)
              Center(
                child: Text(
                  "Статус: $status",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}