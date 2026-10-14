import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floor_front/page/usr_wifi/provision/client/usr_client_device_type.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import '../../../esp/provision/ble_client.dart';
import '../../../esp/provision/ble_client_scanner.dart';
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

  final BleClientScanner _bleScanner = BleClientScanner();
  List<BleDiscoveredDevice> discoveredBleDevices = [];
  BleDiscoveredDevice? selectedBleDevice;
  bool isBleScanning = false;

  @override
  void onPrefixChanged(String newPrefix) {
    super.onPrefixChanged(newPrefix);
    final newDeviceType = UsrClientDeviceType.fromPrefix(newPrefix);
    onDeviceTypeChanged(newDeviceType);
  }

  /// Обробник зміни типу девайса (префікса)
  void onDeviceTypeChanged(UsrClientDeviceType newType) {
    if (newType.isBleSupported) {
      debugPrint("КРОК 5: Перехід USR -> ESP: Зупиняємо HTTP, переходимо до BLE");
      _switchToBleMode(newType);
    } else {
      debugPrint("КРОК 6: Перехід ESP -> USR: Зупиняємо BLE, повертаємо HTTP");
      _switchToHttpMode();
    }
  }

  /// Перехід у режим BLE (Очищення Wi-Fi + запуск BLE-сканеру)
  void _switchToBleMode(UsrClientDeviceType deviceType) {
    setState(() {
      networks.clear();

      httpClient = BleClient(deviceType: deviceType);
      httpClient.mac = null;
      httpClient.ssidName = null;

      macController.clear();
      ssidNameController.text = deviceType.prefix;

      selectedBleDevice = null;
      discoveredBleDevices.clear();
      isLoading = false;
      status = "Переключено на ${deviceType.label}. Пошук BLE пристроїв...";
    });

    if (selectedUartType.name == 'rxTx') {
      setState(() {
        selectedUartType = ConnectInterfaceType.rs485;
      });
    }

    _startBleScan();
  }

  /// Перехід у режим HTTP (USR)
  void _switchToHttpMode() {
    _bleScanner.stopScan();

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

    runSetupSequence(null);
  }

  /// Запуск BLE сканування через bluetoothctl (Linux)
  Future<void> _startBleScan() async {
    debugPrint("BLE: Стартуємо сканування BLE-ефіру...");

    setState(() {
      isBleScanning = true;
      isLoading = true;
      status = "Запуск BLE сканування ефіру...";
    });

    // 1. Чекаємо завершення сканування bluetoothctl
    await _bleScanner.startScan(timeout: const Duration(seconds: 5));

    if (!mounted) return;

    // 2. Беремо зафіксований список знайдених пристроїв з геттера сканера
    setState(() {
      discoveredBleDevices = List.from(_bleScanner.discoveredDevices);
      isBleScanning = false;
      isLoading = false;

      if (discoveredBleDevices.isEmpty) {
        status = selectedUartType.isRs485Enabled
            ? "Відсутній коннект Device-шлюз в режимі BLE"
            : "BLE пристроїв не знайдено";
      } else {
        status = "Знайдено BLE-шлюзів: ${discoveredBleDevices.length}";
      }
    });
  }

  /// Вибір BLE-шлюзу зі списку
  void _onSelectBleDevice(BleDiscoveredDevice device) {
    setState(() {
      selectedBleDevice = device;

      macController.text = device.id.toUpperCase();
      ssidNameController.text = device.name;

      if (httpClient is BleClient) {
        final bleClient = httpClient as BleClient;
        bleClient.mac = device.id.toUpperCase();
        bleClient.ssidName = device.name;
      }

      status = "Обрано BLE-шлюз: ${device.name}";
    });

    validateFormInternal();
  }

  @override
  Future<bool> onScan() async {
    final deviceType = UsrClientDeviceType.fromPrefix(selectedPrefix);
    if (deviceType.isBleSupported) {
      return false;
    }

    try {
      final results = await provision.scanNetworks(null, httpClient);

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
    final deviceType = UsrClientDeviceType.fromPrefix(selectedPrefix);

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
            if (deviceType.isBleSupported) _buildBleGatewaySelector(),
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

  Widget _buildBleGatewaySelector() {
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
                    ? "Оберіть BLE-шлюз (${discoveredBleDevices.length})"
                    : "Обрано шлюз: ${selectedBleDevice!.name}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 11),
              ),
              children: [
                if (discoveredBleDevices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "BLE-шлюзів не знайдено...",
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
                          onTap: () => _onSelectBleDevice(device),
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

    final deviceType = UsrClientDeviceType.fromPrefix(selectedPrefix);
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

    if (httpClient.mac == null) {
      final isModule = ssid.toUpperCase().contains("USR-WIFI232") ||
          ssid.toUpperCase().contains("USR-S100");

      if (isModule) {
        setState(() {
          status = "Підключення до $ssid...";
        });

        provision.scanNetworks(ssid, httpClient).then((results) {
          if (results.isNotEmpty && results.first.containsKey('connected')) {
            isLoading = false;
            httpClient.ssidName = ssid;
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