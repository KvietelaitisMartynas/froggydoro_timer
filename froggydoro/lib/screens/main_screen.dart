import 'dart:async';
import 'package:flutter/material.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MainScreen({super.key, required this.onThemeModeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  int _workHours = 0;
  int _workMinutes = 25;
  int _workSeconds = 0;
  int _breakHours = 0;
  int _breakMinutes = 5;
  int _breakSeconds = 0;
  int _totalSeconds = 0;
  bool _isBreakTime = false;
  Timer? _timer;
  bool _isRunning = false;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    _loadTimeSettings();
    _loadSessionCount();

    Notifications().init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  void _updateTimer(
    int workHours,
    int workMinutes,
    int workSeconds,
    int breakHours,
    int breakMinutes,
    int breakSeconds,
  ) {
    setState(() {
      _workHours = workHours;
      _workMinutes = workMinutes;
      _workSeconds = workSeconds;
      _breakHours = breakHours;
      _breakMinutes = breakMinutes;
      _breakSeconds = breakSeconds;
      if (_isBreakTime) {
        _totalSeconds = _breakHours * 3600 + _breakMinutes * 60 + _breakSeconds;
      } else {
        _totalSeconds = _workHours * 3600 + _workMinutes * 60 + _workSeconds;
      }
    });
    _resetTimer();
  }

  void _startTimer() {
    if (_isRunning ||
        (_workHours == 0 && _workMinutes == 0 && _workSeconds == 0))
      return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds > 0) {
        setState(() {
          _totalSeconds--;
        });
      } else {
        if (!_isBreakTime) {
          setState(() {
            _sessionCount++;
          });
          _saveSessionCount();
          _startBreakTime();
        } else {
          _restartWorkTime();
        }
      }
    });
  }

  void _startBreakTime() {
    setState(() {
      _isBreakTime = true;
      _totalSeconds = _breakHours * 3600 + _breakMinutes * 60 + _breakSeconds;
    });

    Notifications().showNotification(
      id: 1,
      title: 'Work time is over!',
      body: 'Start your break now!',
    );
  }

  void _restartWorkTime() {
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workHours * 3600 + _workMinutes * 60 + _workSeconds;
    });

    Notifications().showNotification(
      id: 2,
      title: 'Break is over!',
      body: 'Back to work!',
    );

    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    _isBreakTime = false;
    _totalSeconds = _workHours * 3600 + _workMinutes * 60 + _workSeconds;
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _loadSessionCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionCount = prefs.getInt('sessionCount') ?? 0;
    });
  }

  void _saveSessionCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sessionCount', _sessionCount);
  }

  void _loadTimeSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _workHours = prefs.getInt('workHours') ?? 0;
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _workSeconds = prefs.getInt('workSeconds') ?? 0;
      _breakHours = prefs.getInt('breakHours') ?? 0;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _breakSeconds = prefs.getInt('breakSeconds') ?? 0;
      _updateTimer(
        _workHours,
        _workMinutes,
        _workSeconds,
        _breakHours,
        _breakMinutes,
        _breakSeconds,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFFF1F3E5), // Light mode background color
        title: const Text(
          'Froggydoro',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 88, 111, 81),
            fontSize: 24,
            fontStyle: FontStyle.normal,
            letterSpacing: -0.24,
          ),
        ),
      ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification notification) {
          notification.disallowIndicator();
          return true;
        },
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Center(
              child: Column(
                children: [
                  Row(children: [Expanded(child: Container(height: 120))]),
                  Text(
                    _isBreakTime ? "Break Time" : "Work Time",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          _isBreakTime
                              ? const Color.fromARGB(255, 144, 169, 85)
                              : Color.fromARGB(255, 49, 87, 44),
                    ),
                  ),
                  Text(
                    "Work sessions completed: $_sessionCount",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(children: [Expanded(child: Container(height: 10))]),
                  Text(
                    _formatTime(_totalSeconds),
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _startTimer,
                        child: const Text('Start'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _stopTimer,
                        child: const Text('Stop'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _resetTimer,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SettingsScreen(
              updateTimer: _updateTimer,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory, // Removes ripple effect
          highlightColor: Colors.transparent, // Removes highlight effect
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedFontSize: 0,
          elevation: 0,
          iconSize: 30,
          onTap: _onItemTapped,
          backgroundColor: Color(0xFFF1F3E5), // Light mode background color
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: ""),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
