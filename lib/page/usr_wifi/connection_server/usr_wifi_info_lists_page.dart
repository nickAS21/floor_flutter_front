import 'package:flutter/material.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_list_page.dart';
import '../info/usr_wifi_info_storage.dart';
import '../info/usr_wifi_info_list_locale.dart';
import '../info/usr_wifi_info_page.dart'; // Форма редагування
import '../../data_home/data_location_type.dart';
import '../provision/client/http/usr_wifi_232_http_client_helper.dart';
import 'usr_wifi_info_connection.dart';
import 'usr_wifi_info_synchronization.dart';

class UsrWiFiInfoListsPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrWiFiInfoListsPage({super.key, required this.selectedLocation});

  @override
  State<UsrWiFiInfoListsPage> createState() => _UsrWiFiInfoListsPageState();
}

class _UsrWiFiInfoListsPageState extends State<UsrWiFiInfoListsPage> with SingleTickerProviderStateMixin {
  final _storage = UsrWiFiInfoStorage();
  late TabController _tabController;

  List<DataUsrWiFiInfo> _serverListUsrInfo = [];
  bool _isLoading = false;
  int _localSyncCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFromServer();
  }

  @override
  void didUpdateWidget(UsrWiFiInfoListsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      setState(() {
        _serverListUsrInfo = [];
        _localSyncCounter = 0; // Скидаємо лічильник для нової локації
      });
      _fetchFromServer();
    }
  }

  // GET
  Future<void> _fetchFromServer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _serverListUsrInfo = []; // Очищення кешу перед новим запитом
    });

    final result = await UsrWiFiInfoConnection.fetchFromServer(widget.selectedLocation);

    if (mounted) {
      setState(() {
        _serverListUsrInfo = result;
        _isLoading = false;
      });
    }
  }

  // POST
  Future<void> _handleUpload() async {
    if (!mounted || _serverListUsrInfo.isEmpty) return;
    setState(() => _isLoading = true);
    final success = await UsrWiFiInfoConnection.uploadToServer(widget.selectedLocation, _serverListUsrInfo);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Дані успішно відправлено на сервер" : "Помилка запису")),
      );
    }
  }

  // Синхронізація: Local -> Server Tab
  Future<void> _handleSyncLocalToServerState() async {
    final localData = await _storage.loadAllInfoForLocation(widget.selectedLocation);
    if (mounted) {
      setState(() {
        _serverListUsrInfo = UsrWiFiInfoSynchronization.updateFromLocalToServer(
          currentServerList: _serverListUsrInfo,
          localList: localData,
        );
      });
      _tabController.animateTo(1);
    }
  }

  Future<void> _handleSyncServerToLocale() async {
    if (_serverListUsrInfo.isEmpty) return;
    final dataToSave = UsrWiFiInfoSynchronization.copyServerToLocal(_serverListUsrInfo);
    await _storage.saveFullList(widget.selectedLocation, dataToSave);

    if (mounted) {
      setState(() {
        _localSyncCounter++; // Змінюємо стан, щоб Key оновився
      });
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Locale Prefs"),
            Tab(text: "Server Data"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalTab(),
          _buildServerTab(),
        ],
      ),
    );
  }

  Widget _buildLocalTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Кнопка копіювання з серверної вкладки в локалку
              _buildMiniBtn(
                  "Update From Server",
                  Icons.download_for_offline,
                  Colors.orange,
                  _serverListUsrInfo.isEmpty ? null : _handleSyncServerToLocale
              ),
              // Можна додати ще кнопку очищення або рефрешу, якщо треба
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: UsrWiFiInfoListLocale(
            // Ключ змусить Flutter перестворити віджет і заново вичитати SharedPrefs
            key: ValueKey("${widget.selectedLocation.name}_$_localSyncCounter"),
            selectedLocation: widget.selectedLocation,
          ),
        ),
      ],
    );
  }

  Widget _buildServerTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniBtn("GET", Icons.cloud_download, Colors.blue, _fetchFromServer),
              _buildMiniBtn("POST", Icons.cloud_upload, Colors.green, _serverListUsrInfo.isEmpty ? null : _handleUpload),
              _buildMiniBtn("From Local", Icons.sync, Colors.purple, _handleSyncLocalToServerState),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: UsrWiFiInfoListPage(
            selectedLocation: widget.selectedLocation,
            localeList: const [],
            externalList: _serverListUsrInfo,

            // РЕДАГУВАННЯ ТА ДОДАВАННЯ ЯК У LOCALE
            onAdd: () async {
              final newInfo = DataUsrWiFiInfo(
                id: _serverListUsrInfo.isEmpty ? 1 : _serverListUsrInfo.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1,
                locationType: widget.selectedLocation,
                ssidWifiBms: "",
                bssidMac: "",
                netIpA: "", netAPort: UsrWiFi232HttpClientHelper.netPortADef, netIpB: "0.0.0.0", netBPort: UsrWiFi232HttpClientHelper.netPortBDef,
              );

              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: newInfo)),
              );

              if (result == true) {
                setState(() => _serverListUsrInfo.add(newInfo));
              }
            },

            onEdit: (info) async {
              // Відкриваємо ту саму сторінку форми
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: info)),
              );
              // Якщо натиснули "Зберегти" у формі, оновлюємо UI
              if (result == true) {
                setState(() {});
              }
            },

            onDelete: (selectedIds) async {
              bool? confirm = await _showConfirm(selectedIds.length);
              if (confirm == true) {
                setState(() {
                  _serverListUsrInfo.removeWhere((item) => selectedIds.contains(item.id));
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirm(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Видалення"),
        content: Text("Видалити $count записів з серверного списку?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("НІ")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ТАК")),
        ],
      ),
    );
  }


  Widget _buildMiniBtn(String label, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}