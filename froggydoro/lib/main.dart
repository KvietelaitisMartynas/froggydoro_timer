import 'package:flutter/material.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();
  print('Time zones initialized successfully.');

  // Initialize notifications
  final notifications = Notifications();
  await notifications.init();

  runApp(MyApp(notifications: notifications));
}

class MyApp extends StatefulWidget {
  final Notifications notifications;

  const MyApp({super.key, required this.notifications});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = _getThemeModeFromString(themeMode);
    });
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _getStringFromThemeMode(themeMode));
  }

  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

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
        scaffoldBackgroundColor: const Color(
          0xFFF1F3E5,
        ), // Light mode background color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF1F3E5),
          foregroundColor: Color(0xFF586F51), // Match the background
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF1F3E5),
          selectedItemColor: Color(0xFF586F51),
          unselectedItemColor: Color(0xFFB0C8AE),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF586F51),
          ), // Light theme text color
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFF3F5738,
        ), // Dark mode background color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F5738),
          foregroundColor: Color(0xFFB0C8AE),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF3F5738),
          selectedItemColor: Color(0xFFB0C8AE),
          unselectedItemColor: Color(0xFF63805C),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFFB0C8AE),
          ), // Dark theme text color
        ),
      ),
      themeMode: _themeMode,
      home: MainScreen(
        onThemeModeChanged: _onThemeModeChanged,
        notifications: widget.notifications,
      ),
    );
  }
}
