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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Work & Break Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
