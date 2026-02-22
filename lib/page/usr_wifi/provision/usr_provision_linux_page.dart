import 'package:floor_front/page/usr_wifi/provision/usr_provision_linux.dart';
import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import '../../data_home/data_location_type.dart';

class UsrProvisionLinuxPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionLinuxPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionLinuxPage> createState() => _UsrProvisionLinuxPageState();
}

class _UsrProvisionLinuxPageState extends UsrProvisionBasePage<UsrProvisionLinuxPage> {

  @override
  late final provision = UsrProvisionLinux();

  @override
  Future<bool> onScan() async {
    try {
       // 3. Скануємо мережі через нативного провайдера Linux
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
          setState(() { status = "Мереж не знайдено (Timeout)"; scanSuccess = false; });
          return false;
        }
      }
    } catch (e) {
      if (mounted) setState(() => status = "Помилка: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        validateFormInternal(); // Оновлюємо стан кнопки Save
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40, // ВСТАНОВІТЬ БАЖАНУ ВИСОТУ ТУТ (стандартна — 56)
        title: const Text(
          "Linux Configuration",
          style: TextStyle(fontSize: 16), // Можна зменшити шрифт для гармонії
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => runSetupSequence(null), // Передаємо null явно
          ),
        ],
      ),
      body: widgets.buildCommonForm(
        networkSelector: _buildNetworkSelector(),
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "ЗБЕРЕГТИ ТА РЕСТАРТ",
        ),
      ),
    );
  }

  Widget _buildNetworkSelector() {
    if (isLoading) return const SizedBox.shrink();
    if (networks.isEmpty) return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Мереж не знайдено", style: TextStyle(color: Colors.red)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(15),
        border: Border.all(color: Colors.blue, width: 2), // Жирна рамка блоку
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
            Container(
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
    );
  }

  // Усередині State-класу сторінки
  void onNetworkTap(Map<String, dynamic> network) {
    final String ssid = network['ssid'] ?? "";

    if (httpClient.mac == null) {
      final isModule = ssid.toUpperCase().contains("USR-WIFI232") ||
          ssid.toUpperCase().contains("USR-S100");

      if (isModule) {
        setState(() {
          // isLoading = true; // Вмикаємо колесо відразу
          status = "Підключення до $ssid...";
        });

        // 1. ВИКЛИКАЄМО КОНЕКТ (через той самий метод провайдера)
        // Ми передаємо SSID, щоб Linux виконав nmcli connect
        provision.scanNetworks(ssid, httpClient).then((results) {
          // Перевіряємо тільки маркер успіху
          if (results.isNotEmpty && results.first.containsKey('connected')) {

            // ТІЛЬКИ ПІСЛЯ ТОГО як ОС підключилася, запускаємо п.1 архітектури
            // Ніяких foundNetworks = results, нам це вже не цікаво
            isLoading = false;
            httpClient.ssidName = ssid;
            runSetupSequence(ssid);

          } else {
            // Якщо маркера немає, значить це був просто холостий скан
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

    // Звичайний вибір робочої мережі
    setState(() => targetSsidController.text = ssid);
    validateFormInternal();
  }
}