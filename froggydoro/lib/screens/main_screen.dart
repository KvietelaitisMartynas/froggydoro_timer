import 'dart:async';
import 'package:flutter/material.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/widgets/music_Manager.dart';

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

    AudioManager().playMusic();

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
    AudioManager().fadeOutMusic();
    setState(() {
      _isBreakTime = true;
      _totalSeconds = _breakMinutes * 60 + _breakSeconds;
    });

    Notifications().showNotification(
      id: 1,
      title: 'Work time is over!',
      body: 'Start your break now!',
    );
  }

  void _restartWorkTime() {
    AudioManager().playMusic();
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
    });

    Notifications().showNotification(
      id: 2,
      title: 'Break is over!',
      body: 'Back to work!',
    );

    _startTimer();
  }

  void _stopTimer() {
    AudioManager().pauseMusic();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    AudioManager().stopMusic();
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
                  Spacer(flex: 1),
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
                  Spacer(flex: 1),
                  Image.asset(
                    'assets/default_froggy_transparent.png',
                    height: screenHeight * 0.3,
                  ),
                  Spacer(flex: 1),
                  Text(
                    _formatTime(_totalSeconds),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.12,
                    ),
                  ),
                  Spacer(flex: 1),
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
                  Spacer(flex: 1),
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
