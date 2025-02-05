import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LogsPage extends StatefulWidget {
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<String> _logs = [];

  Future<void> _fetchLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8084/api/logs'),
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
    _fetchLogs();
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
