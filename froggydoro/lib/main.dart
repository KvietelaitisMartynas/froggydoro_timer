import 'dart:async';
import 'package:flutter/material.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/screens/timer_screen.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/widgets/time_picker.dart';
import 'package:numberpicker/numberpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Work & Break Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 19, 19, 19),
      ),
      themeMode: _themeMode,
      home: MainScreen(onThemeModeChanged: _onThemeModeChanged),
    );
  }
}
