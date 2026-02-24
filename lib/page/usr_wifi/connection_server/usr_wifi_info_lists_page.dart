import 'package:flutter/material.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_list_page.dart';
import '../info/usr_wifi_info_storage.dart';
import '../info/usr_wifi_info_list_locale.dart';
import '../info/usr_wifi_info_page.dart';
import '../../data_home/data_location_type.dart';
import '../provision/client/usr_client_helper.dart';
import 'usr_wifi_info_connection.dart';
import 'usr_wifi_info_synchronization.dart';
import 'usr_wifi_info_location_server_session.dart';

class UsrWiFiInfoListsPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrWiFiInfoListsPage({super.key, required this.selectedLocation});

  @override
  State<UsrWiFiInfoListsPage> createState() => _UsrWiFiInfoListsPageState();
}

class _UsrWiFiInfoListsPageState extends State<UsrWiFiInfoListsPage> with SingleTickerProviderStateMixin {
  final _storage = UsrWiFiInfoStorage();
  late TabController _tabController;

  // 1. Архітектурна Мапа Сесій
  final Map<LocationType, UsrWiFiInfoLocationServerSession> _serverDataMapInfo = {};
  bool _isLoading = false;
  int _localSyncCounter = 0;

  // 2. Метод-геттер: "лінива" ініціалізація
  UsrWiFiInfoLocationServerSession getServerSession(LocationType loc) {
    return _serverDataMapInfo.putIfAbsent(
      loc,
          () => UsrWiFiInfoLocationServerSession(data: []),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Автоматичний запуск при першому вході
    _fetchFromServer(isAuto: true);
  }

  @override
  void didUpdateWidget(UsrWiFiInfoListsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      // При зміні локації намагаємось ініціалізувати нову сесію
      _fetchFromServer(isAuto: true);
    }
  }

  // 3. Розумний GET: автоматично тільки якщо сесія не ініційована
  Future<void> _fetchFromServer({bool isAuto = false}) async {
    if (!mounted) return;

    final session = getServerSession(widget.selectedLocation);

    // СТРАТЕГІЯ: Якщо сесія вже була (навіть якщо список порожній через "ігри"),
    // авто-запит блокується. Працює лише ручний GET (isAuto: false).
    if (isAuto && session.isInitialized) return;

    setState(() => _isLoading = true);

    final result = await UsrWiFiInfoConnection.fetchFromServer(widget.selectedLocation);

    if (mounted) {
      setState(() {
        session.data = result;
        session.isInitialized = true; // Сесію зафіксовано
        _isLoading = false;
      });
    }
  }

  // POST: Беремо дані з поточної активної сесії
  Future<void> _handleUpload() async {
    final session = getServerSession(widget.selectedLocation);
    if (!mounted || session.data.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await UsrWiFiInfoConnection.uploadToServer(widget.selectedLocation, session.data);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Дані успішно відправлено на сервер" : "Помилка запису")),
      );
    }
  }

  // Синхронізація: Local -> Active Session Map
  Future<void> _handleSyncLocalToServerState() async {
    final localData = await _storage.loadAllInfoForLocation(widget.selectedLocation);
    final session = getServerSession(widget.selectedLocation);

    if (mounted) {
      setState(() {
        session.data = UsrWiFiInfoSynchronization.updateFromLocalToServer(
          currentServerList: session.data,
          localList: localData,
        );
        session.isInitialized = true; // Синхронізація теж ініціює сесію
      });
      _tabController.animateTo(1);
    }
  }

  Future<void> _handleSyncServerToLocale() async {
    final session = getServerSession(widget.selectedLocation);
    if (session.data.isEmpty) return;

    final dataToSave = UsrWiFiInfoSynchronization.copyServerToLocal(session.data);
    await _storage.saveFullList(widget.selectedLocation, dataToSave);

    if (mounted) {
      setState(() => _localSyncCounter++);
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = getServerSession(widget.selectedLocation);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Locale Prefs"), Tab(text: "Server Data")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalTab(session),
          _buildServerTab(session),
        ],
      ),
    );
  }

  Widget _buildLocalTab(UsrWiFiInfoLocationServerSession session) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniBtn(
                  "Update From Server",
                  Icons.download_for_offline,
                  Colors.orange,
                  session.data.isEmpty ? null : _handleSyncServerToLocale
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: UsrWiFiInfoListLocale(
            key: ValueKey("${widget.selectedLocation.name}_$_localSyncCounter"),
            selectedLocation: widget.selectedLocation,
          ),
        ),
      ],
    );
  }

  Widget _buildServerTab(UsrWiFiInfoLocationServerSession session) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniBtn("GET", Icons.cloud_download, Colors.blue, () => _fetchFromServer(isAuto: false)),
              _buildMiniBtn("POST", Icons.cloud_upload, Colors.green, session.data.isEmpty ? null : _handleUpload),
              _buildMiniBtn("From Local", Icons.sync, Colors.purple, _handleSyncLocalToServerState),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: UsrWiFiInfoListPage(
            selectedLocation: widget.selectedLocation,
            localeList: const [],
            externalList: session.data,
            onMove: (items, target) async {
              await _moveSelectedToServerLocation(items, target);
            },
            onAdd: () async {
              final newId = session.data.isEmpty ? 1 : session.data.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
              final newInfo = DataUsrWiFiInfo(
                id: newId,
                locationType: widget.selectedLocation,
                ssidWifiBms: "", bssidMac: "", netIpA: "",
                netAPort: UsrClientHelper.netPortADef, netIpB: "0.0.0.0", netBPort: UsrClientHelper.netPortBDef,
              );

              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: newInfo)));
              if (result == true) setState(() => session.data.add(newInfo));
            },

            onEdit: (info) async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: info)));
              if (result == true) setState(() {});
            },

            onDelete: (selectedIds) async {
              bool? confirm = await _showConfirm(selectedIds.length);
              if (confirm == true) {
                setState(() => session.data.removeWhere((item) => selectedIds.contains(item.id)));
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

  Future<void> _moveSelectedToServerLocation(List<DataUsrWiFiInfo> items, LocationType target) async {
    if (items.isEmpty || target == widget.selectedLocation) return;

    // Отримуємо посилання на об'єкти сесій у RAM
    final currentSession = getServerSession(widget.selectedLocation);
    final targetSession = getServerSession(target);

    setState(() {
      for (var item in items) {
        item.locationType = target; // Оновлюємо тип локації
        currentSession.data.removeWhere((e) => e.id == item.id);
        targetSession.data.add(item);
      }
      targetSession.isInitialized = true; // Фіксуємо сесію цільової локації

      targetSession.data.sort((a, b) => a.id.compareTo(b.id));
      currentSession.data.sort((a, b) => a.id.compareTo(b.id));
    });
  }
}