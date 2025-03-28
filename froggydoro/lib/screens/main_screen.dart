import 'dart:async';
import 'package:flutter/material.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/widgets/music_Manager.dart';

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Notifications notifications;

  MainScreen({
    Key? key,
    required this.onThemeModeChanged,
    Notifications? notifications,
  }) : notifications = notifications ?? Notifications(),
       super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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
    WidgetsBinding.instance.addObserver(this);

    // Initialize the TabController with 2 tabs and provide the vsync from the mixin.
    _tabController = TabController(length: 2, vsync: this);

    // Load the timer state after initializing the TabController
    _loadTimerState();
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
      // Reload the timer state when the app resumes
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
          _stopTimer();
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

      if (startTimeString != null) {
        final startTime = DateTime.parse(startTimeString);
        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

        final updatedRemainingTime = remainingTime - elapsedSeconds;

        setState(() {
          _totalSeconds = updatedRemainingTime > 0 ? updatedRemainingTime : 0;
          _isRunning =
              updatedRemainingTime > 0 && (prefs.getBool('isRunning') ?? false);
        });
      }
    } catch (e) {
      print('Error loading timer state: $e');
    }
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

  void _startTimer() async {
    if (_isRunning || (_workMinutes == 0 && _workSeconds == 0)) return;

    AudioManager().playMusic();

    final prefs = await SharedPreferences.getInstance();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(seconds: _totalSeconds));

    setState(() {
      _isRunning = true;
    });

    // Save the start time and initial remaining time
    await prefs.setString('startTime', startTime.toIso8601String());
    await prefs.setInt('remainingTime', _totalSeconds);
    await prefs.setBool('isRunning', true);

    // Schedule a notification for when the timer ends
    await widget.notifications.scheduleNotification(
      id: 1,
      title: _isBreakTime ? 'Break is over!' : 'Work time is over!',
      body: _isBreakTime ? 'Back to work!' : 'Start your break now!',
      scheduledTime: endTime,
    );

    // Start the timer logic
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds > 0) {
        setState(() {
          _totalSeconds--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _startBreakTime() {
    AudioManager().fadeOutMusic();
    setState(() {
      _isBreakTime = true;
      _totalSeconds = _breakMinutes * 60 + _breakSeconds;
    });
    _startTimer();
  }

  void _restartWorkTime() {
    AudioManager().playMusic();
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
    });
    _startTimer();
  }

  void _stopTimer() async {
    AudioManager().pauseMusic();
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isRunning = false;
    });

    // Save the updated timer state
    await prefs.setBool('isRunning', false);
    await prefs.setInt('remainingTime', _totalSeconds);

    // Cancel the scheduled notification
    await widget.notifications.cancelNotification(1);

    // Show popup and notification when the timer ends
    if (_totalSeconds == 0) {
      if (_isBreakTime) {
        // Break time ended
        _sessionCount++;
        /* widget.notifications.showNotification(
          id: 2,
          title: 'Break is over!',
          body: 'Back to work!',
        ); */
        _showSessionCompletePopup(
          context,
          'Your break is over.',
          'Start your work session.',
          _restartWorkTime,
        );
      } else {
        // Work time ended
        /*         widget.notifications.showNotification(
          id: 1,
          title: 'Work time is over!',
          body: 'Start your break now!',
        ); */
        _showSessionCompletePopup(
          context,
          'Your work session is complete.',
          'Start your break.',
          _startBreakTime,
        );
      }
    }
  }

  void _resetTimer() {
    AudioManager().stopMusic();
    _stopTimer();
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workMinutes * 60 + _workSeconds;
      _sessionCount = 0;
    });
    _saveSessionCount();
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
      isDismissible: false, // Prevent dismissal by tapping outside
      enableDrag: false, // Prevent dismissal by dragging
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        final screenWidth =
            MediaQuery.of(context).size.width; // Get screen width

        return SafeArea(
          child: Container(
            width: screenWidth, // Set the width to match the screen width
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: textColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the popup
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
            letterSpacing: -0.24,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
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
                "Work sessions completed: $_sessionCount",
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
                _formatTime(_totalSeconds),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.15,
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _setTestDurations,
                child: const Text('Test Durations'),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
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
