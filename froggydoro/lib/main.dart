import 'package:flutter/material.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  final DatabaseService _databaseService = DatabaseService.instance;

  // Initialize notifications
  final notifications = Notifications();
  await notifications.init();

  final prefs = await SharedPreferences.getInstance();
  final wasActive = prefs.getBool('wasActive') ?? false;

  if (!wasActive) {
    // Check if a timer is picked in the database
    final pickedTimer = await _databaseService.getPickedTimer();

    if (pickedTimer != null) {
      // Use the picked timer's settings
      await prefs.setInt('workMinutes', pickedTimer.workDuration);
      await prefs.setInt('breakMinutes', pickedTimer.breakDuration);
      await prefs.setInt('totalSeconds', pickedTimer.workDuration * 60);
      await prefs.setInt('remainingTime', pickedTimer.workDuration * 60);
    } else {
      // Fall back to default values
      final workTime = prefs.getInt('workMinutes') ?? 25;
      final breakTime = prefs.getInt('breakMinutes') ?? 5;
      await prefs.setInt('totalSeconds', workTime * 60);
      await prefs.setInt('remainingTime', workTime * 60);
    }

    // Reset other timer states
    await prefs.setBool('isRunning', false);
    await prefs.setBool('isBreakTime', false);
    await prefs.setBool('hasStarted', false);
  }

  // Mark as active again
  prefs.setBool('wasActive', true);

  runApp(MyApp(notifications: notifications));
}

class MyApp extends StatefulWidget {
  final Notifications notifications;

  const MyApp({super.key, required this.notifications});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DatabaseService _databaseService;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    _databaseService = DatabaseService.instance;
    _loadThemeMode();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = _getThemeModeFromString(themeMode);
    });
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE4E8CD), // Button color
            foregroundColor: Color(0xFF586F51), // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Color(0xFFF1F3E5),
                width: 1,
              ), // Border color and width
            ),
          ),
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF63805C), // Button color
            foregroundColor: Color(0xFFB0C8AE), // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Color(0xFFB0C8AE),
                width: 1,
              ), // Border color and width
            ),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: MainScreen(
        onThemeModeChanged: _onThemeModeChanged,
        notifications: widget.notifications,
        databaseService: _databaseService,
      ),
    );
  }
}
