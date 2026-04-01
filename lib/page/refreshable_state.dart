import 'package:flutter/material.dart';

/// Базовий клас для станів, які підтримують зовнішнє оновлення.
abstract class RefreshableState<T extends StatefulWidget> extends State<T> {
  void refresh();
}