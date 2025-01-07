import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'ble_scan_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scanner App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set the splash screen as the initial screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/ble_scan': (context) => const BLEScanScreen(),
      },
    );
  }
}
