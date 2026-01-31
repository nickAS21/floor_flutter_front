import 'dart:io';

import 'package:floor_front/page/usr_wifi/provision/usr_provision_widgets.dart';
import 'package:flutter/material.dart';
import 'usr_provision_base_page.dart';
import 'http/usr_http_client.dart';
import '../../data_home/data_location_type.dart';


class UsrProvisionLinuxPage extends StatefulWidget {
  final LocationType selectedLocation;
  const UsrProvisionLinuxPage({super.key, required this.selectedLocation});

  @override
  State<UsrProvisionLinuxPage> createState() => _UsrProvisionLinuxPageState();
}

class _UsrProvisionLinuxPageState extends UsrProvisionBasePage<UsrProvisionLinuxPage> {
  final _httpClient = UsrHttpClient();
  final TextEditingController _macController = TextEditingController();

  List<Map<String, dynamic>> _networks = [];
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _macController.addListener(() {
      setState(() {
        detectedMac = _macController.text.trim().toUpperCase();
      });
      // ДОДАЙТЕ ЦЕ: викликає перевірку кнопки "Зберегти"
      validateFormInternal();
    });
    _onRefresh();
  }

  @override
  void updateModuleSsid(String mac) {
    // 1. Виконуємо базову логіку (оновлення SSID модуля)
    super.updateModuleSsid(mac);

    // 2. Синхронізуємо текст у полі вводу з отриманим MAC
    if (_macController.text != mac) {
      _macController.text = mac;
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      status = "Отримання даних...";

      // Чистимо ВСЕ: змінні та контролери
      detectedMac = null;
      macController.clear();
      targetSsidController.clear();
      passController.clear();
      // Якщо хочеш скидати і назву модуля:
      ssidNameController.clear();
    });

    try {
      final mac = await _httpClient.getMacAddress();
      if (mac != null) {
        updateModuleSsid(mac); // Це знову заповнить контролери новими даними
      }
    } catch (e) {
      setState(() => status = "Помилка: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = UsrProvisionWidgets(this); // Передаємо 'this' (State)

    return Scaffold(
      appBar: AppBar(
        title: const Text("Linux Configuration"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh)],
      ),
      body: widgets.buildCommonForm(
        actionButtons: widgets.buildActionButtons(
          onSave: () => onSaveHttpUpdate(widget.selectedLocation),
          saveLabel: "ЗБЕРЕГТИ ТА РЕСТАРТ",
        ),
      ),
    );
  }
}