import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/usr_provision_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';

class UsrProvisionWidgets {
  final UsrProvisionBasePage state; // Посилання на базу для доступу до даних

  UsrProvisionWidgets(this.state);

  // Спільна форма для обох сторінок
  Widget buildCommonForm({required Widget actionButtons, Widget? networkSelector}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ДОДАНО: Показуємо підказку, якщо MAC ще не визначено
          if (state.detectedMac == null || state.detectedMac!.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                state.provision.getHint(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent
                ),
                textAlign: TextAlign.center,
              ),
            ),

          state.buildMacStatus(), // Виклик існуючого методу з бази
          const SizedBox(height: 10),

          // Рядок: ID + Префікс + SSID модуля
          Row(
            children: [
              SizedBox(
                  width: 55,
                  child: state.buildCompactField(state.idController, "ID", isNumber: true)
              ),
              const SizedBox(width: 6),
              state.buildPrefixSelector(), // Вибір префікса B2/A2
              const SizedBox(width: 6),
              Expanded(child: state.buildCompactField(state.ssidNameController, "Module SSID")),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: "Мережа призначення (куди підключиться модуль)",
                  preferBelow: false, // ТЕПЕР ВІДМАЛЬОВУЄТЬСЯ ЗВЕРХУ
                  verticalOffset: 25, // Відступ від поля до хмарки підказки
                  child: state.buildCompactField(state.targetSsidController, "Target WiFi SSID"),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Tooltip(
                  message: "Не очищувати дані мережі для наступного модуля",
                  preferBelow: false,
                  child: Checkbox(
                    value: state.keepTargetSettings,
                      onChanged: state.toggleKeepSettings,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          state.buildCompactField(
            state.passController,
            "WiFi Password",
            obscure: state.obscurePassword,
            suffix: IconButton(
              icon: Icon(state.obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
              onPressed: state.togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: 10),
          // Нове поле для BitRate
          state.buildCompactField(state.bitrateController, "Bit Rate (Baud)", isNumber: true),
          const SizedBox(height: 10),
          // Поля серверів та портів
          _buildIpPortRow(state.ipAController, state.portAController, "Server IP A"),
          const SizedBox(height: 10),
          _buildIpPortRow(state.ipBController, state.portBController, "Server IP B"),

          if (networkSelector != null) ...[
            const SizedBox(height: 16),
            networkSelector,
          ],

          const SizedBox(height: 24),

          // Блок кнопок
          state.isLoading ? const CircularProgressIndicator() : actionButtons,

          const SizedBox(height: 12),
          Text(
            "Статус: ${state.status}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  // Допоміжний метод для рядка IP+Port
  Widget _buildIpPortRow(TextEditingController ip, TextEditingController port, String label) {
    return Row(
      children: [
        Expanded(flex: 3, child: state.buildCompactField(ip, label)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: state.buildCompactField(port, "Port", readOnly: true)),
      ],
    );
  }

// У вашому класі UsrProvisionWidgets
  Widget buildActionButtons({required VoidCallback onSave, required String saveLabel}) {
    return Column(
      children: [
        // Кнопка для перегляду сторінки модуля на Linux
        if (Platform.isLinux) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // Виклик статичного методу утиліт замість методу стану
              onPressed: () => UsrProvisionUtils.openDeviceWeb(),
              icon: const Icon(Icons.open_in_new),
              label: const Text(UsrProvisionUtils.openHttpOn254),
            ),
          ),
        ],

        // Кнопка Factory Reset
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (state.detectedMac != null) ? state.onLoadDefault : null,
            icon: const Icon(Icons.factory, color: Colors.red, size: 18),
            label: const Text("FACTORY RESET"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: (state.detectedMac != null) ? Colors.red : Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Основна кнопка збереження
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            // Не активна при ID=0 або помилках валідації
            onPressed: state.isFormValid ? onSave : null,
            child: Text(saveLabel),
          ),
        ),
      ],
    );
  }

  void openExternalChrome() {
    // Пряме посилання з паролем, щоб не було "червоного" в браузері
    const url = "http://admin:admin@10.10.100.254";

    // Просто запуск Chrome у Linux. Без перевірок Platform, щоб не глючило.
    Process.run('google-chrome', [url]);
  }
}