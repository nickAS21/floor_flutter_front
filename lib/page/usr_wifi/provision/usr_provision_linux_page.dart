import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floor_front/page/usr_wifi/provision/client/usr_client_node_type.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import '../../../esp/provision/ble_client_node.dart';
import '../../../esp/provision/ble_client_node_scanner.dart';
import 'usr_provision_base_page.dart';
import '../../data_home/data_location_type.dart';
import 'client/connect_interface_type.dart';

class UsrProvisionLinuxPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionLinuxPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionLinuxPage> createState() => _UsrProvisionLinuxPageState();
}

class _UsrProvisionLinuxPageState extends UsrProvisionBasePage<UsrProvisionLinuxPage> {

  @override
  late final provision = UsrProvisionLinux();

  final BleClientNodeScanner _bleNodeScanner = BleClientNodeScanner();
  List<BleClientNodeDiscovered> discoveredBleDevices = [];
  BleClientNodeDiscovered? selectedBleDevice;
  bool isBleScanning = false;

  /// Реалізація запуск BLE сканера для Linux
  @override
  Future<void> startBleScanNode() async {
    final deviceType = UsrClientNodeType.fromPrefix(selectedPrefix);

    setState(() {
      networks.clear();
      nodeClient = BleClientNode(deviceType: deviceType);
      nodeClient.mac = null;
      nodeClient.ssidName = null;

      macController.clear();
      ssidNameController.text = deviceType.prefix;

      selectedBleDevice = null;
      discoveredBleDevices.clear();
      isBleScanning = true;
      isLoading = true;
      status = "Запуск BLE сканування ефіру...";
    });

    if (selectedUartType.name == 'rxTx') {
      setState(() {
        selectedUartType = ConnectInterfaceType.rs485;
      });
    }

    await _bleNodeScanner.startScan(timeout: const Duration(seconds: 5));

    if (!mounted) return;

    setState(() {
      discoveredBleDevices = List.from(_bleNodeScanner.discoveredDevices);
      isBleScanning = false;
      isLoading = false;

      if (selectedBleDevice == null) {
        status = "Відсутній коннект Client node в режимі BLE";
      } else {
        status = "Підключено до MAC: ${selectedBleDevice!.id.toUpperCase()}";
      }
    });
  }

  /// Реалізація зупинки BLE сканера для Linux
  @override
  Future<void> stopBleScanNode() async {
    await _bleNodeScanner.stopScan();

    if (!mounted) return;

    setState(() {
      isBleScanning = false;
      discoveredBleDevices.clear();
      selectedBleDevice = null;
      status = "Переключено на USR. Пошук мереж...";
    });

    if (selectedUartType.name == 'ble') {
      setState(() {
        selectedUartType = ConnectInterfaceType.rs485;
      });
    }
  }

  /// Вибір BLE-node зі списку
  void _onSelectBleClientNode(BleClientNodeDiscovered clientNode) {
    setState(() {
      selectedBleDevice = clientNode;

      macController.text = clientNode.id.toUpperCase();
      ssidNameController.text = clientNode.name;

      if (nodeClient is BleClientNode) {
        final bleClient = nodeClient as BleClientNode;
        bleClient.mac = clientNode.id.toUpperCase();
        bleClient.ssidName = clientNode.name;
      }

      status = "Підключено до MAC: ${clientNode.id.toUpperCase()}";
    });

    validateFormInternal();
  }

  @override
  Future<bool> onScanNode() async {
    final deviceTypeNode = UsrClientNodeType.fromPrefix(selectedPrefix);
    if (deviceTypeNode.isBleSupported) {
      return false;
    }

    try {
      final results = await provision.scanNetworks(null, nodeClient);

      if (mounted) {
        if (results.isNotEmpty) {
          scanSuccess = true;
          final Map<String, Map<String, dynamic>> uniqueMap = {};
          for (var net in results) {
            final String ssid = (net['ssid'] ?? "").toString();
            if (ssid.isEmpty || ssid.toLowerCase().contains("empty")) continue;
            if (!uniqueMap.containsKey(ssid) || (net['level'] ?? 0) > (uniqueMap[ssid]!['level'] ?? 0)) {
              uniqueMap[ssid] = net;
            }
          }

          setState(() {
            networks = uniqueMap.values.toList();
            networks.sort((a, b) => (b['level'] ?? 0).compareTo(a['level'] ?? 0));
            status = "Знайдено доступних (Linux) через пристрій WiFi мереж: ${networks.length}";
          });
          return true;
        } else {
          setState(() { status = "WiFi Мереж не знайдено"; scanSuccess = false; });
          return false;
        }
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        validateFormInternal();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);
    final deviceType = UsrClientNodeType.fromPrefix(selectedPrefix);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: const Text(
          "Linux Configuration",
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: widgets.buildCommonForm(
        networkSelector: Column(
          children: [
            if (deviceType.isBleSupported) _buildBleNodeSelector(),
            _buildNetworkSelector(),
          ],
        ),
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "ЗБЕРЕГТИ ТА РЕСТАРТ",
        ),
      ),
    );
  }

  Widget _buildBleNodeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.bluetooth_searching, color: Colors.deepPurple),
              title: Text(
                selectedBleDevice == null
                    ? "Оберіть BLE-node (${discoveredBleDevices.length})"
                    : "Обрано node: ${selectedBleDevice!.name}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 11),
              ),
              children: [
                if (discoveredBleDevices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "BLE-node не знайдено...",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  Material(
                    color: Colors.white,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: discoveredBleDevices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final device = discoveredBleDevices[index];
                        final isSelected = selectedBleDevice?.id == device.id;

                        return ListTile(
                          dense: true,
                          title: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          subtitle: Text(
                            "MAC: ${device.id}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                              : Text("${device.rssi} dBm", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          onTap: () => _onSelectBleClientNode(device),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    if (isLoading) return const SizedBox.shrink();

    final deviceType = UsrClientNodeType.fromPrefix(selectedPrefix);
    if (networks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          deviceType.isBleSupported
              ? "Wi-Fi мережі (Provisioning) — очікування..."
              : "WiFi Мереж не знайдено",
          style: TextStyle(color: deviceType.isBleSupported ? Colors.grey : Colors.red, fontSize: 11),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.blue.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: GlobalKey(),
              iconColor: Colors.blue,
              collapsedIconColor: Colors.blue,
              leading: const Icon(Icons.wifi_find, color: Colors.blue, size: 28),
              title: Text(
                targetSsidController.text.isEmpty
                    ? "Оберіть Wi-Fi мережу (${networks.length})"
                    : "Обрано: ${targetSsidController.text}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 10),
              ),
              children: [
                Material(
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: networks.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final net = networks[index];
                        return ListTile(
                          dense: true,
                          title: Text(net['ssid'] ?? "Unknown"),
                          trailing: Text("${net['level']}%", style: const TextStyle(color: Colors.blueGrey)),
                          onTap: () {
                            setState(() {
                              targetSsidController.text = net['ssid'] ?? "";
                              onNetworkTap(net);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onNetworkTap(Map<String, dynamic> network) {
    final String ssid = network['ssid'] ?? "";

    if (nodeClient.mac == null) {
      final isModule = ssid.toUpperCase().contains("USR-WIFI232") ||
          ssid.toUpperCase().contains("USR-S100");

      if (isModule) {
        setState(() {
          status = "Підключення до $ssid...";
        });

        provision.scanNetworks(ssid, nodeClient).then((results) {
          if (results.isNotEmpty && results.first.containsKey('connected')) {
            isLoading = false;
            nodeClient.ssidName = ssid;
            runSetupSequence(ssid);
          } else {
            setState(() => isLoading = false);
          }
        }).catchError((e) {
          setState(() {
            isLoading = false;
            status = "Помилка підключення: $e";
          });
        });
        return;
      }
    }

    setState(() => targetSsidController.text = ssid);
    validateFormInternal();
  }
}