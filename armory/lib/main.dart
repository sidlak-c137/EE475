import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(MaterialApp(
    title: 'BLE Demo',
    theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF)),
    home: const HomePage(title: 'The Armory'),
  ));
}
