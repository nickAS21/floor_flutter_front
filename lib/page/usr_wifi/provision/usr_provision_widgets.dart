import 'dart:io';
import 'package:floor_front/helpers/app_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../esp/provision/ble_client_node.dart';
import 'client/usr_client_node_type.dart';
import 'client/usr_client_helper.dart';
import 'client/connect_interface_type.dart';
import 'usr_provision_base_page.dart';
import '../../../esp/info/data_esp_bms_info.dart';

class UsrProvisionWidgets {
  final UsrProvisionBasePage state; // Посилання на базу для доступу до даних

  UsrProvisionWidgets(this.state);

  // Спільна форма для обох сторінок
  Widget buildCommonForm({required Widget actionButtons, Widget? networkSelector}) {
    final bool isConnectedToModule = state.macController.text.isNotBlank;
    final nodeType = UsrClientNodeType.fromPrefix(state.selectedPrefix);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnectedToModule ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isConnectedToModule ? Colors.green.shade200 : Colors.blue.shade200),
            ),
            child: Text(
              (isConnectedToModule)
                  ? "Підключено до MAC: ${state.macController.text}"
                  : (nodeType.isBleSupported
                  ? state.provision.getHintBle()
                  : state.provision.getHintHttp()),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueAccent
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // Рядок: ID + Префікс + SSID модуля
          Row(
            children: [
              SizedBox(
                  width: 55,
                  child: state.buildCompactField(state.idController, "ID", isNumber: true)
              ),
              const SizedBox(width: 6),
              state.buildPrefixSelector(), // Вибір префікса B2/A2/ESP
              const SizedBox(width: 6),
              Expanded(child: state.buildCompactField(state.ssidNameController, "Module SSID")),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: "Мережа призначення (куди підключиться модуль)",
                  preferBelow: false,
                  verticalOffset: 15,
                  child: state.buildCompactField(state.targetSsidController, "Target WiFi SSID"),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 20,
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
          const SizedBox(height: 6),
          state.buildCompactField(
            state.passController,
            "WiFi Password",
            obscure: state.obscurePassword,
            suffix: IconButton(
              icon: Icon(state.obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
              onPressed: state.togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: 6),

          // Одне поле для BitRate (швидкість апаратної шини)
          state.buildCompactField(state.bitrateController, "Bit Rate (Baud)", isNumber: true),
          const SizedBox(height: 6),

          // Сервер A та порт
          _buildIpPortRow(state.ipAController, state.portAController, "Server IP A"),
          const SizedBox(height: 6),

          // Сервер B та порт
          _buildIpPortRow(state.ipBController, state.portBController, "Server IP B"),
          const SizedBox(height: 6),

          // Секція підключених девайсів (для BLE-нод) або перемикач UART (для USR)
          buildDevicesSection(state),

          if (networkSelector != null) ...[
            const SizedBox(height: 6),
            networkSelector,
          ],

          const SizedBox(height: 6),

          // Блок кнопок
          state.isLoading ? const CircularProgressIndicator() : actionButtons,

          const SizedBox(height: 6),
          Text(
            "Статус: ${state.status}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  // Уніфікований рядок IP + Port для серверів A та B
  Widget _buildIpPortRow(TextEditingController ip, TextEditingController port, String label) {
    return Row(
      children: [
        Expanded(flex: 3, child: state.buildCompactField(ip, label)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: state.buildCompactField(port, "Port", readOnly: true)),
      ],
    );
  }

  // Блок пристроїв для BLE-нод або вибір режиму шини для USR
  Widget buildDevicesSection(UsrProvisionBasePage pageState) {
    final deviceType = UsrClientNodeType.fromPrefix(pageState.selectedPrefix);

    // Якщо це старий USR без підтримки BLE — показуємо звичайний селектор UART
    if (!deviceType.isBleSupported) {
      return buildUartModeSelector(pageState);
    }

    final client = pageState.nodeClient;
    final List<DataEspBmsInfo> devices = (client is BleClientNode) ? client.bmsList : [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    "Підключені пристрої (${devices.length}):",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // TODO: Відкрити діалог/сторінку сканування або вибору цільових BMS
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 15, color: Colors.blueAccent),
                      SizedBox(width: 4),
                      Text(
                        "Додати",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  "Пристроїв не підключено (RS-485 / BLE BMS)",
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: devices.map((dev) {
                final isBle = dev.interfaceType == ConnectInterfaceType.ble;
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isBle ? Colors.purple.shade50 : Colors.orange.shade50,
                  side: BorderSide(
                    color: isBle ? Colors.purple.shade200 : Colors.orange.shade200,
                  ),
                  avatar: Icon(
                    isBle ? Icons.bluetooth : Icons.settings_ethernet,
                    size: 14,
                    color: isBle ? Colors.purple : Colors.deepOrange,
                  ),
                  label: Text(
                    isBle
                        ? "${dev.name} (BLE)"
                        : "${dev.name} [Addr: ${dev.addressRs485 ?? 1}]",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    pageState.setState(() {
                      devices.remove(dev);
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Перемикач режиму UART для USR A2 / B2
  Widget buildUartModeSelector(UsrProvisionBasePage pageState) {
    final deviceType = UsrClientNodeType.fromPrefix(pageState.selectedPrefix);
    if (deviceType == UsrClientNodeType.s100) {
      return const SizedBox.shrink();
    }

    final allowedTypes = [
      ConnectInterfaceType.rs485,
      ConnectInterfaceType.rxTx,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Інтерфейс зв’язку node з пристроєм:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Row(
            children: allowedTypes.map((type) {
              return Expanded(
                child: RadioListTile<ConnectInterfaceType>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(type.label, style: const TextStyle(fontSize: 12)),
                  value: type,
                  groupValue: pageState.selectedUartType,
                  onChanged: (val) {
                    if (val != null) {
                      pageState.setState(() {
                        pageState.selectedUartType = val;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons({required VoidCallback onSave, required String saveLabel}) {
    final isDevisesActivated = state.nodeClient.mac.isNotBlank;
    const activeColorOnSave = Color(0xFF00897B);
    final nodeType = UsrClientNodeType.fromPrefix(state.selectedPrefix);
    return Column(
      children: [
        if (Platform.isLinux && !nodeType.isBleSupported) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isDevisesActivated
                  ? () {
                final bool isS100 = state.selectedPrefix.contains("S100");
                UsrClientHelper.openDeviceWeb(isS100: isS100);
              }
                  : null,
              icon: const Icon(Icons.open_in_new),
              label: Text(state.selectedPrefix.contains("S100")
                  ? UsrClientHelper.openHttpS100On168_8_1_1
                  : UsrClientHelper.openHttp232On10_10_100_254),
            ),
          ),
        ],

        // Кнопка Factory Reset
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (isDevisesActivated) ? state.onLoadDefault : null,
            icon: const Icon(Icons.factory, color: Colors.red, size: 18),
            label: const Text("FACTORY RESET"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: (isDevisesActivated) ? Colors.red : Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Основна кнопка збереження
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            style: state.isFormValid
                ? ElevatedButton.styleFrom(
              backgroundColor: activeColorOnSave.withValues(alpha: 0.2),
              foregroundColor: activeColorOnSave,
              side: const BorderSide(color: activeColorOnSave, width: 2),
              elevation: 0,
            )
                : null,
            onPressed: state.isFormValid ? onSave : null,
            child: Text(
              saveLabel.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void openExternalChrome() {
    const url = "http://admin:admin@${UsrClientHelper.baseIpAtHttpWiFi232}";
    Process.run('google-chrome', [url]);
  }
}