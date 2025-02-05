import 'package:flutter/material.dart';
import 'page/login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false, // Приховуємо банер "DEBUG"
      title: 'My App other',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Починаємо з авторизації
    );
  }
}
