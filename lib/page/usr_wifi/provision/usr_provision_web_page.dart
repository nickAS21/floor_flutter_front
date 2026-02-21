import 'package:flutter/material.dart';
import 'client/usr_client_helper.dart';

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
            const SizedBox(height: 10),
            // Кнопка для WiFi232 (10.10.100.254)
            _buildWebButton(
              label: UsrClientHelper.openHttp232On10_10_100_254,
              onPressed: () => UsrClientHelper.openDeviceWeb(isS100: false),
            ),
            const SizedBox(height: 12),
            // Кнопка для S100 (192.168.1.1)
            _buildWebButton(
              label: UsrClientHelper.openHttpS100On168_8_1_1,
              onPressed: () => UsrClientHelper.openDeviceWeb(isS100: true),
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

  // Допоміжний метод для кнопок
  Widget _buildWebButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}