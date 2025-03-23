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

  int _workMinutes = 25;
  int _workSeconds = 0;
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
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
  ) {
    setState(() {
      _workMinutes = workMinutes;
      _workSeconds = workSeconds;
      _breakMinutes = breakMinutes;
      _breakSeconds = breakSeconds;
      if (_isBreakTime) {
        _totalSeconds = _breakMinutes * 60 + _breakSeconds;
      } else {
        _totalSeconds = _workMinutes * 60 + _workSeconds;
      }
    });
    _resetTimer();
  }

  void _startTimer() {
    if (_isRunning || (_workMinutes == 0 && _workSeconds == 0)) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds > 0) {
        setState(() {
          _totalSeconds--;
        });
      } else {
        _stopTimer();
        if (!_isBreakTime) {
          setState(() {
            _sessionCount++;
          });
          _saveSessionCount();
          Notifications().showNotification(
            id: 1,
            title: 'Work time is over!',
            body: 'Start your break now!',
          );
          _showSessionCompletePopup(
            context,
            'Your work session is complete. Start your break.',
            _startBreakTime,
          );
        } else {
          Notifications().showNotification(
            id: 2,
            title: 'Break is over!',
            body: 'Back to work!',
          );
          _showSessionCompletePopup(
            context,
            'Your break is over. Start your work session.',
            _restartWorkTime,
          );
        }
      }
    });
  }

  void _startBreakTime() {
    setState(() {
      _isBreakTime = true;
      _totalSeconds = _breakMinutes * 60 + _breakSeconds;
    });
    _startTimer();
  }

  void _restartWorkTime() {
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
    });
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
    _totalSeconds = _workMinutes * 60 + _workSeconds;
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _workSeconds = 0;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _breakSeconds = prefs.getInt('breakSeconds') ?? 0;
      _updateTimer(_workMinutes, _workSeconds, _breakMinutes, _breakSeconds);
    });
  }

  void _showSessionCompletePopup(
    BuildContext context,
    String message,
    VoidCallback onPressed,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(fontSize: 18.0)),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(
                      0xFFB0C8AE,
                    ), // Explicit background color
                    foregroundColor: Colors.white, // Explicit text color
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onPressed();
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setTestDurations() {
    setState(() {
      _workMinutes = 0;
      _workSeconds = 10;
      _breakMinutes = 0;
      _breakSeconds = 5;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Froggydoro',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
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
                  const Spacer(flex: 1),
                  Text(
                    _isBreakTime ? "Break Time" : "Work Time",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      fontSize: screenWidth * 0.06,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Work sessions completed: $_sessionCount",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  const Spacer(flex: 1),
                  Image.asset(
                    'assets/default_froggy_transparent.png',
                    height: screenHeight * 0.3,
                  ),
                  const Spacer(flex: 1),
                  Text(
                    _formatTime(_totalSeconds),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.15,
                    ),
                  ),
                  const Spacer(flex: 1),
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
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _setTestDurations,
                    child: const Text('Test Durations'),
                  ),
                  const Spacer(flex: 1),
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
          iconSize: screenWidth * 0.08,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/clock.png')),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/Sliders.png')),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
