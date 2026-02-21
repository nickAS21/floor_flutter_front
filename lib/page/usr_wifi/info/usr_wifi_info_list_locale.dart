import 'package:flutter/material.dart';
import '../info/data_usr_wifi_info.dart';
import '../info/usr_wifi_info_storage.dart';
import '../info/usr_wifi_info_page.dart';
import '../provision/client/usr_client_helper.dart';
import 'usr_wifi_info_list_page.dart';
import '../../data_home/data_location_type.dart';

class UsrWiFiInfoListLocale extends StatefulWidget {
  final LocationType selectedLocation;

  const UsrWiFiInfoListLocale({super.key, required this.selectedLocation});

  @override
  State<UsrWiFiInfoListLocale> createState() => _UsrWiFiInfoListLocaleState();
}

class _UsrWiFiInfoListLocaleState extends State<UsrWiFiInfoListLocale> {
  final UsrWiFiInfoStorage _storage = UsrWiFiInfoStorage();

  // Оновлення екрана (викликає FutureBuilder заново)
  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataUsrWiFiInfo>>(
      future: _storage.loadAllInfoForLocation(widget.selectedLocation),
      builder: (context, snapshot) {
        // Чекаємо завантаження з Prefs
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return UsrWiFiInfoListPage(
          selectedLocation: widget.selectedLocation,
          localeList: snapshot.data!,
          onAdd: _addNewInfo,
          onDelete: _deleteSelected,
          onEdit: _editInfo,
          onRefresh: _refresh, // Додаємо, щоб UI міг оновитися
        );
      },
    );
  }

  Future<void> _addNewInfo() async {
    final newInfo = DataUsrWiFiInfo(
      id: 0,
      locationType: widget.selectedLocation,
      bssidMac: "",
      ssidWifiBms: "",
      netIpA: "",
      netAPort: UsrClientHelper.netPortADef,
      netIpB: "0.0.0.0",
      netBPort: UsrClientHelper.netPortBDef,
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: newInfo)),
    );
    if (result == true) _refresh();
  }

  Future<void> _deleteSelected(Set<int> selectedIds) async {
    List<DataUsrWiFiInfo> list = await _storage.loadAllInfoForLocation(widget.selectedLocation);
    list.removeWhere((info) => selectedIds.contains(info.id));
    await _storage.saveFullList(widget.selectedLocation, list);
    _refresh();
  }

  Future<void> _editInfo(DataUsrWiFiInfo info) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UsrWiFiInfoPage(info: info)),
    );
    if (result == true) _refresh();
  }
}