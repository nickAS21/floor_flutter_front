import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  _EnvironmentPageState createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  List<String> _logs = [];

  Future<void> _fetchEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    String apiUrl = EnvironmentConfig.backendUrl + AppConfig.apiPathSmart + AppConfig.pathConfig;
    final url = Uri.parse(apiUrl);
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _logs = List<String>.from(jsonDecode(response.body)["logs"]);
      });
    } else {
      setState(() {
        _logs = ["Error loading logs"];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEnvironment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(_logs[index]));
        },
      ),
    );
  }
}
