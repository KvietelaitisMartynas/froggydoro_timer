import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/widgets/music_Manager.dart';

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Notifications notifications;

  const MainScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.notifications,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel(
    'com.example.froggydoro/exact_alarm',
  );

  late TabController _tabController;

  int _selectedIndex = 0;
  late int _workMinutes;
  int _workSeconds = 0;
  late int _breakMinutes;
  int _breakSeconds = 0;
  int _totalSeconds = 0;
  bool _isBreakTime = false;
  Timer? _timer;
  bool _isRunning = false;
  int _sessionCount = 0;
  int _roundCount = 4;
  late int _initialCount;

  final Set<int> _scheduledNotifications = {}; // Track scheduled notifications

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the TabController with 2 tabs and provide the vsync from the mixin.
    _tabController = TabController(length: 2, vsync: this);

    _loadPreferances();

    // Load the timer state after initializing the TabController
    _loadTimerState();
  }

  void _loadPreferances() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _sessionCount = prefs.getInt('sessionCount') ?? 0;
      _roundCount = prefs.getInt('roundCount') ?? 1;
      _initialCount = _roundCount;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTimerState();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  void _resumeTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeString = prefs.getString('startTime');

    if (startTimeString != null) {
      final startTime = DateTime.parse(startTimeString);
      final remainingSeconds = DateTime.now().difference(startTime).inSeconds;

      if (remainingSeconds > 0) {
        setState(() {
          _totalSeconds = remainingSeconds;
          _stopTimer(isReset: false);
        });
      }
    }
  }

  void _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remainingTime', _totalSeconds);
    await prefs.setBool('isRunning', _isRunning);
    await prefs.setBool('isBreakTime', _isBreakTime);
  }

  void _loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeString = prefs.getString('startTime');
      final remainingTime = prefs.getInt('remainingTime') ?? 0;

      if (startTimeString != null && _isRunning) {
        final startTime = DateTime.parse(startTimeString);
        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

        final updatedRemainingTime = remainingTime - elapsedSeconds;

        setState(() {
          _totalSeconds = updatedRemainingTime > 0 ? updatedRemainingTime : 0;
          _isRunning =
              updatedRemainingTime > 0 && (prefs.getBool('isRunning') ?? false);
        });
      } else {
        _totalSeconds = remainingTime;
        _isRunning = false;
      }
    } catch (e) {
      print('Error loading timer state: $e');
    }
  }

  void _updateTimer(int workMinutes, int workSeconds, int breakMinutes, int breakSeconds, int roundCount,) {
    setState(() {
      _workMinutes = workMinutes;
      _workSeconds = workSeconds;
      _breakMinutes = breakMinutes;
      _breakSeconds = breakSeconds;
      _roundCount = roundCount;
      if (_isBreakTime) {
        _totalSeconds = _breakMinutes * 60 + _breakSeconds;
      } else {
        _totalSeconds = _workMinutes * 60 + _workSeconds;
      }
    });
    _resetTimer();
  }

  Future<bool> isExactAlarmPermissionGranted() async {
    if (Platform.isAndroid) {
      try {
        final bool isGranted = await _channel.invokeMethod(
          'isExactAlarmPermissionGranted',
        );
        return isGranted;
      } on PlatformException catch (e) {
        print('Failed to check exact alarm permission: ${e.message}');
      }
    }
    return false;
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final isGranted = await isExactAlarmPermissionGranted();
        if (!isGranted) {
          await _channel.invokeMethod('requestExactAlarmPermission');
        }
      } on PlatformException catch (e) {
        print('Failed to request exact alarm permission: ${e.message}');
      }
    }
  }

  void _startTimer() async {
    if (_isRunning || (_workMinutes == 0 && _workSeconds == 0)) return;

    AudioManager().playMusic();

    final prefs = await SharedPreferences.getInstance();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(seconds: _totalSeconds));

    setState(() {
      _isRunning = true;
    });

    await prefs.setString('startTime', startTime.toIso8601String());
    await prefs.setInt('remainingTime', _totalSeconds);
    await prefs.setBool('isRunning', true);

    if (Platform.isIOS) {
      // Schedule notifications only on iOS
      try {
        await widget.notifications.scheduleNotification(
          id: 1,
          title: _isBreakTime ? 'Break is over!' : 'Work time is over!',
          body: _isBreakTime ? 'Back to work!' : 'Start your break now!',
          scheduledTime: endTime,
        );
        _scheduledNotifications.add(1);
      } catch (e) {
        print('Error scheduling notification: $e');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds > 0) {
        setState(() {
          _totalSeconds--;
        });
      } else {
        _stopTimer(isReset: false);
      }
    });
  }

  void _stopTimer({bool isReset = false}) async {
    AudioManager().pauseMusic();
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isRunning = false;
    });

    await prefs.setBool('isRunning', false);
    await prefs.setInt('remainingTime', _totalSeconds);

    if (Platform.isIOS && _totalSeconds != 0) {
      // Cancel notifications only on iOS
      try {
        if (_scheduledNotifications.contains(1)) {
          await widget.notifications.cancelNotification(1);
          _scheduledNotifications.remove(1);
        }
      } catch (e) {
        print('Error canceling notification: $e');
      }
    } else if (Platform.isAndroid && !isReset && _totalSeconds == 0) {
      // Show an immediate notification on Android only if not resetting
      try {
        await widget.notifications.showNotification(
          id: 2,
          title: _isBreakTime ? 'Work time!' : 'Break time!',
          body:
              _isBreakTime
                  ? 'Your break has ended!'
                  : 'You can finish your work!',
        );
      } catch (e) {
        print('Error displaying notification on Android: $e');
      }
    }

    if (_totalSeconds == 0) {
      if (_isBreakTime) {
        _sessionCount++;
        _saveSessionCount();

        _showSessionCompletePopup(context, 
          'Your break is over!', 
          'Start your work session',
          _restartWorkTime, 
        );
      } else {
        setState((){
          if (_roundCount > 0) {
            _roundCount--;
          }
        });
        _saveRoundCount();

        if (_roundCount == 0) {
          _showSessionCompletePopup(
            context, 
            'All rounds completed!', 
            'Take a long rest',
            () {
              _resetTimer();
              _roundCount = _initialCount;
              _saveRoundCount();
            },
          );
        } else {
          _showSessionCompletePopup(
            context, 
            'Your work session is over!', 
            'Start your break',
            _startBreakTime,
          );
        }
      }
    }



  }

  void _resetTimer() {
    AudioManager().pauseMusic();
    _stopTimer(isReset: true);
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
    });
    _saveSessionCount();
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

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_isBreakTime) {
        _totalSeconds = _breakMinutes * 60 + _breakSeconds;
      } else {
        _totalSeconds = _workMinutes * 60 + _workSeconds;
      }
    });
  }

  void _saveSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sessionCount', _sessionCount);
  }

  void _saveRoundCount() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('roundCount', _roundCount);
}

  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSessionCompletePopup(
    BuildContext context,
    String messageTitle,
    String messageBody,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    final backgroundColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF3F5738)
            : const Color(0xFFF1F3E5);
    final buttonColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFFB0C8AE)
            : const Color(0xFF586F51);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return SafeArea(
          child: Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16.0),
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  messageTitle,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  messageBody,
                  style: const TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: textColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onPressed();
                      },
                      child: const Text('Start'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: textColor,
                      ),
                      onPressed: () {
                        _isBreakTime = !_isBreakTime;
                        _pauseTimer();
                        Navigator.pop(context);
                      },
                      child: const Text('Pause'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
            letterSpacing: -0.24,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),
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
                    "Total work sessions completed: $_sessionCount",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Image.asset(
                    'assets/default_froggy_transparent.png',
                    height: screenHeight * 0.3,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    formatTime(_totalSeconds),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.15,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Rounds left: $_roundCount",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _startTimer,
                        child: const Text('Start'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _stopTimer(isReset: true),
                        child: const Text('Stop'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _resetTimer,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _workMinutes = 0;
                        _workSeconds = 10;
                        _breakMinutes = 0;
                        _breakSeconds = 5;
                        _totalSeconds = _workMinutes * 60 + _workSeconds;
                        _roundCount = 2;
                      });
                    },
                    child: const Text('Test Durations'),
                  ), 
                  //SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
          SettingsScreen(
            updateTimer: _updateTimer,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
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
