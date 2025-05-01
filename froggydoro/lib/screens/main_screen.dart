import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/widgets/build_button.dart'; // Assuming ButtonWidget is defined here
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/widgets/music_Manager.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:froggydoro/widgets/dialog_helper.dart';

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

  final DatabaseService _databaseService = DatabaseService.instance;

  late TabController _tabController;

  int _selectedIndex = 0;
  TimerObject? _timerObject; // Loaded from DB
  // Default values, will be overwritten by DB or SharedPreferences
  int _workMinutes = 25;
  int _workSeconds = 0;
  int _breakMinutes = 5;
  int _breakSeconds = 0;
  int _roundCountSetting = 4; // The configured number of rounds

  // State variables
  int _totalSeconds = 0; // Current remaining seconds
  bool _isBreakTime = false;
  Timer? _timer; // The periodic timer (only active in foreground)
  bool _isRunning = false; // Is the timer conceptually running?
  int _sessionCount = 0; // Completed work sessions in the current cycle
  int _currentRound = 1; // Current round number (starts at 1)
  bool _hasStartedCycle = false; // Has the user explicitly started a cycle?
  DateTime? _startTimeSaved; // When the current running period started
  bool _hasStarted =
      false; // <--- ADDED BACK: Tracks if timer started at least once since reset/load

  final Set<int> _scheduledNotifications = {}; // Track scheduled notifications

  // Constants for SharedPreferences keys
  static const String prefWorkMinutes = 'workMinutes';
  static const String prefWorkSeconds = 'workSeconds';
  static const String prefBreakMinutes = 'breakMinutes';
  static const String prefBreakSeconds = 'breakSeconds';
  static const String prefRoundCountSetting = 'roundCountSetting';
  static const String prefRemainingTime = 'remainingTime';
  static const String prefIsRunning = 'isRunning';
  static const String prefIsBreakTime = 'isBreakTime';
  static const String prefHasStartedCycle = 'hasStartedCycle';
  static const String prefSessionCount = 'sessionCount';
  static const String prefCurrentRound = 'currentRound';
  static const String prefStartTime = 'startTime';
  static const String prefHasStarted =
      'hasStarted'; // Need to save/load this too

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _initializeAsync(); // Use async initialization
  }

  // Separate async initialization
  Future<void> _initializeAsync() async {
    await _loadSettingsAndState();
    // Ensure UI reflects loaded state
    if (mounted) {
      setState(() {});
    }
  }

  void test() {
    var x = 10; // should suggest final
  }

  // Load settings from DB/Prefs and restore timer state
  Future<void> _loadSettingsAndState() async {
    final prefs = await SharedPreferences.getInstance();
    print("DEBUG: Loading state..."); // Add logging

    // 1. Load Timer Settings (Same as before)
    _timerObject = await _databaseService.getPickedTimer();
    if (_timerObject != null) {
      // ... load from _timerObject ...
      _workMinutes = _timerObject!.workDuration;
      _breakMinutes = _timerObject!.breakDuration;
      _roundCountSetting = _timerObject!.count;
      _workSeconds = 0;
      _breakSeconds = 0;
      await _saveSettingsToPrefs();
    } else {
      // ... load from Prefs ...
      _workMinutes = prefs.getInt(prefWorkMinutes) ?? 25;
      _workSeconds = prefs.getInt(prefWorkSeconds) ?? 0;
      _breakMinutes = prefs.getInt(prefBreakMinutes) ?? 5;
      _breakSeconds = prefs.getInt(prefBreakSeconds) ?? 0;
      _roundCountSetting = prefs.getInt(prefRoundCountSetting) ?? 4;
    }

    // 2. Restore Timer State
    // Load state variables first, including _isBreakTime which is needed for calculation
    _isBreakTime = prefs.getBool(prefIsBreakTime) ?? false;
    _hasStartedCycle = prefs.getBool(prefHasStartedCycle) ?? false;
    _sessionCount = prefs.getInt(prefSessionCount) ?? 0;
    _currentRound = prefs.getInt(prefCurrentRound) ?? 1;
    _hasStarted = prefs.getBool(prefHasStarted) ?? false;

    final savedIsRunning = prefs.getBool(prefIsRunning) ?? false;
    final startTimeString = prefs.getString(prefStartTime);
    final savedRemainingTime = prefs.getInt(
      prefRemainingTime,
    ); // We might not even need this anymore

    print(
      "DEBUG: Loaded Prefs - savedIsRunning: $savedIsRunning, startTime: $startTimeString, isBreak: $_isBreakTime, hasStarted: $_hasStarted",
    );

    int newTotalSeconds;
    bool newIsRunning = savedIsRunning; // Assume saved running state initially

    if (savedIsRunning && startTimeString != null) {
      _startTimeSaved = DateTime.parse(startTimeString);
      final DateTime resumeTime = DateTime.now();
      final int totalElapsedSinceStart =
          resumeTime.difference(_startTimeSaved!).inSeconds;

      // Determine the initial duration of the segment that was running
      final int initialDurationOfSegment =
          _isBreakTime
              ? (_breakMinutes * 60 + _breakSeconds)
              : (_workMinutes * 60 + _workSeconds);

      // Calculate the *actual* remaining time
      newTotalSeconds = initialDurationOfSegment - totalElapsedSinceStart;

      if (newTotalSeconds <= 0) {
        newTotalSeconds = 0;
        newIsRunning = false; // Timer finished while backgrounded
      }
    } else if (savedRemainingTime != null && _hasStarted) {
      // Timer was paused, restore saved time directly
      newTotalSeconds = savedRemainingTime;
      newIsRunning = false; // Ensure it's marked as not running
    } else {
      // No valid saved state, or cycle not started, initialize to work time
      newTotalSeconds = _workMinutes * 60 + _workSeconds;
      _isBreakTime = false; // Ensure starting with work time
      newIsRunning = false;
      _hasStartedCycle = false;
      _hasStarted = false; // Reset cycle state if no valid save
      _currentRound = 1;
      _sessionCount = 0;
      _startTimeSaved = null; // Ensure start time is cleared
    }

    // Apply the calculated state ONLY IF MOUNTED
    if (mounted) {
      setState(() {
        _totalSeconds = newTotalSeconds;
        _isRunning = newIsRunning; // Update the state variable
      });

      // If the timer finished while inactive, handle the completion AFTER state is set
      if (savedIsRunning && startTimeString != null && newTotalSeconds <= 0) {
        // Use addPostFrameCallback to ensure build is complete before showing popup potentially
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again inside callback
            _handleTimerCompletion(triggeredByLoad: true);
          }
        });
      } else if (_isRunning) {
        // If the timer should still be running, restart the periodic timer
        print("DEBUG: Timer should be running, starting periodic timer.");
        _startPeriodicTimer();
      } else {
        print("DEBUG: Timer is not running, no periodic timer started.");
      }
    } else {
      print("DEBUG: State not set because widget is not mounted.");
      // If not mounted, just update the instance variables directly
      // This might happen if load finishes after dispose but before async gap completes
      _totalSeconds = newTotalSeconds;
      _isRunning = newIsRunning;
    }
  }

  // Save only the timer *state* (not settings)
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefRemainingTime, _totalSeconds);
    await prefs.setBool(prefIsRunning, _isRunning);
    await prefs.setBool(prefIsBreakTime, _isBreakTime);
    await prefs.setBool(prefHasStartedCycle, _hasStartedCycle);
    await prefs.setInt(prefSessionCount, _sessionCount);
    await prefs.setInt(prefCurrentRound, _currentRound);
    await prefs.setBool(prefHasStarted, _hasStarted); // <-- SAVE _hasStarted

    if (_isRunning && _startTimeSaved != null) {
      await prefs.setString(prefStartTime, _startTimeSaved!.toIso8601String());
    } else {
      await prefs.remove(prefStartTime);
    }
  }

  // Save only the timer *settings*
  Future<void> _saveSettingsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefWorkMinutes, _workMinutes);
    await prefs.setInt(prefWorkSeconds, _workSeconds);
    await prefs.setInt(prefBreakMinutes, _breakMinutes);
    await prefs.setInt(prefBreakSeconds, _breakSeconds);
    await prefs.setInt(prefRoundCountSetting, _roundCountSetting);
  }

  // Cleans up resources when the widget is removed from the widget tree.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Handles changes to the app's lifecycle (e.g. paused, resumed).
  // Saves or restores timer state depending on whether the app is backgrounded or resumed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden: // Treat hidden like paused
        _timer?.cancel();
        _saveTimerState();
        break;
      case AppLifecycleState.resumed:
        _loadSettingsAndState();
        break;
    }
  }

  // Called when a bottom navigation item is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }
  
  // Helper to cancel notifications
  void _cancelScheduledNotifications() {
    if (Platform.isIOS) {
      for (int id in _scheduledNotifications) {
        widget.notifications.cancelNotification(id).catchError((e) {
          print("Error cancelling notification $id: $e");
        });
      }
      _scheduledNotifications.clear();
    }
    // Add cancellation for Android exact alarms if you implement them
  }
  
  // Starts the timer (either a work or break session) and schedules a notification.
  // Also starts music, updates state, and saves session start time for persistence.
  void _startTimer() {
    if (_isRunning) return;
    if (_workMinutes == 0 && _workSeconds == 0 && !_isBreakTime) return;
    if (_breakMinutes == 0 && _breakSeconds == 0 && _isBreakTime) return;

    AudioManager().playMusic();

    _startTimeSaved = DateTime.now();
    final endTime = _startTimeSaved!.add(Duration(seconds: _totalSeconds + 1));

    setState(() {
      _isRunning = true;
      _hasStartedCycle = true;
      _hasStarted = true; // <-- SET _hasStarted TO TRUE
    });

    _saveTimerState();

      // Schedule iOS notification based on session state
    _cancelScheduledNotifications();
    if (Platform.isIOS) {
      try {
        if (_currentRound >= _roundCountSetting) {
          widget.notifications.scheduleNotification(
            id: 4,
            title: 'Cycle complete',
            body: 'You have finished your planned rounds',
            scheduledTime: endTime,
          );
        } else {
          widget.notifications.scheduleNotification(
            id: 1,
            title: _isBreakTime ? 'Break Over!' : 'Work Complete!',
            body:
                _isBreakTime
                    ? 'Time to get back to work.'
                    : 'Ready for a break?',
            scheduledTime: endTime,
          );
        }

        _scheduledNotifications.add(1);
      } catch (e) {
        print('Error scheduling iOS notification: $e');
      }
    }

    _startPeriodicTimer();
  }
  // Resets the timer and state variables when the entire work/break cycle is complete.
  // Sets the round and session counters back to initial values and saves state.
  void _handleCycleCompleteReset() {
  _resetTimer();
  setState(() {
    _currentRound = 1;
    _sessionCount = 0;
    _hasStartedCycle = false;
  });
  _saveTimerState();
}

  // Handles the logic when a timer period (work/break) completes
  void _handleTimerCompletion({bool triggeredByLoad = false}) {
    _isRunning = false;
    _startTimeSaved = null;
    _cancelScheduledNotifications();

    if (Platform.isAndroid) {
    try {
      if (_currentRound >= _roundCountSetting) {
        widget.notifications.showNotification(
          id: 3,
          title: 'Cycle complete',
          body: 'You have finished your planned rounds',
        );
      } else {
        widget.notifications.showNotification(
          id: 2,
          title: _isBreakTime ? 'Break Over!' : 'Work Complete!',
          body: _isBreakTime
              ? 'Time to get back to work.'
              : 'Ready for a break?',
        );
      }
      } catch (e) {
        print('Error showing immediate Android notification: $e');
      }
    }

    bool wasBreak = _isBreakTime; // Store if the completed timer was a break

    if (wasBreak) {
      // ---- Break Finished ----
      _sessionCount++; // Increment session after break
      setState(() {
        _isBreakTime = false;
        _totalSeconds = _workMinutes * 60 + _workSeconds;
      });
      _saveTimerState();

      setState(() {
        _currentRound++;
      });

      if (!triggeredByLoad && mounted) {
        TimerDialogsHelper.showSessionCompletePopup(
          context: context,
          messageTitle: 'Break Over!',
          messageBody: 'Start Round $_currentRound Work?',
          onStartPressed: _startTimer,
        );
      }
    } else {
      // ---- Work Finished ----
      bool isLastRound = _currentRound >= _roundCountSetting;

      if (isLastRound) {
        // ---- All Rounds Completed ----

        if (!triggeredByLoad && mounted) {
          TimerDialogsHelper.showSessionCompletePopup(
            context: context,
            messageTitle: 'Cycle Complete!',
            messageBody: 'All $_roundCountSetting rounds finished!',
            onStartPressed: _handleCycleCompleteReset,
            showStart: false,
            showPause: false,
            showReset: true,
          );
        }
      } else {
        // ---- Normal Work Round Completed, Move to Next ----

        setState(() {
          _isBreakTime = true; // Switch to break mode conceptually
          _totalSeconds = _breakMinutes * 60 + _breakSeconds;
        });
        int roundCompleted = _currentRound; // Capture before incrementing

        _saveTimerState();

        if (!triggeredByLoad && mounted) {
          TimerDialogsHelper.showSessionCompletePopup(
              context: context,
              messageTitle: 'Work Complete!',
              messageBody: 'Start Break for Round $roundCompleted?',
              onStartPressed: _startTimer,
          );
        }
      }
    }
  }

  // Starts the actual Timer.periodic for UI updates
  void _startPeriodicTimer() {
    _timer?.cancel();
    if (!_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), _timerTick);
  }

  // The callback for the periodic timer
  void _timerTick(Timer timer) {
    if (!_isRunning) {
      timer.cancel();
      return;
    }
    if (_totalSeconds > 0) {
      setState(() {
        _totalSeconds--;
      });
    } else {
      timer.cancel();
      _isRunning = false;
      _handleTimerCompletion();
    }
  }

  // Stops (pauses) the conceptual timer
  void _stopTimer() {
    if (!_isRunning) return;

    AudioManager().pauseMusic();
    _timer?.cancel();
    _cancelScheduledNotifications();

    setState(() {
      _isRunning = false;
    });

    _startTimeSaved = null;
    _saveTimerState();
  }

  // Resets the timer to the beginning of the WORK session
  void _resetTimer() {
    AudioManager().pauseMusic();
    _timer?.cancel();
    _cancelScheduledNotifications();

    setState(() {
      _isRunning = false;
      _isBreakTime = false;
      _hasStartedCycle = false;
      _hasStarted = false; // <-- SET _hasStarted TO FALSE
      _totalSeconds = _workMinutes * 60 + _workSeconds;
      _currentRound = 1;
      _sessionCount = 0;
      _startTimeSaved = null;
    });

    _saveTimerState();
    // Optionally save settings if reset should always use current config
    // _saveSettingsToPrefs();
  }



  // Update settings from SettingsScreen
  void _updateSettings(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
    int roundCount,
  ) {
    setState(() {
      _workMinutes = workMinutes;
      _workSeconds = workSeconds;
      _breakMinutes = breakMinutes;
      _breakSeconds = breakSeconds;
      _roundCountSetting = roundCount;

      if (!_isRunning) {
        _resetTimer(); // Reset state to apply new settings immediately if paused/stopped
      }
      // If running, settings will apply on next cycle/reset
    });
    _saveSettingsToPrefs();
    if (!_isRunning) _saveTimerState();
  }

  // Format time helper
  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Build Methods ---

  // ============================================================
  // REVERTED buildButtons METHOD (Using _hasStarted logic)
  // ============================================================
  Widget buildButtons(BuildContext context) {
    // Calculate maxSeconds based on current mode
    final _maxSeconds =
        _isBreakTime
            ? (_breakMinutes * 60 + _breakSeconds)
            : (_workMinutes * 60 + _workSeconds);

    // Determine if the timer is at the start or end
    final isCompleted = _totalSeconds == _maxSeconds || _totalSeconds == 0;
    final theme = Theme.of(context);

    final buttonColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFFB0C8AE)
            : const Color(0xFF586F51);

    // Show only Start button if timer has never started in this session
    if (!_hasStarted && !_isRunning) {
      return ButtonWidget(
        color: buttonColor,
        text: 'Start',
        iconLocation: 'assets/Icons/Play.svg',
        width: 200, // The original wide width
        onClicked: () {
          // Note: _hasStarted is set inside _startTimer now
          _startTimer();
        },
      );
    }

    // Show Pause/Start and Reset if running OR if paused mid-way
    return _isRunning || !isCompleted
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonWidget(
              color: buttonColor,
              // Text changes based on running state
              text: _isRunning ? 'Stop' : 'Start', // Original used "Stop"
              iconLocation:
                  _isRunning
                      ? 'assets/Icons/Pause.svg'
                      : 'assets/Icons/Play.svg',
              width: 120,
              onClicked: () {
                // Don't need to manage _hasStarted here, _startTimer/_stopTimer handle it
                if (_isRunning) {
                  _stopTimer(); // Use _stopTimer to pause
                } else {
                  _startTimer(); // Use _startTimer to resume/start
                }
              },
            ),
            const SizedBox(width: 20),
            ButtonWidget(
              color: buttonColor,
              text: 'Reset',
              iconLocation: 'assets/Icons/Rewind.svg',
              width: 120,
              onClicked: () {
                // Call the confirmation dialog instead of _resetTimer directly
                TimerDialogsHelper.showResetConfirmationDialog(
                  context: context,
                  onConfirmed: _resetTimer,
                );
              },
            ),
          ],
        )
        // Show only Start button if timer is paused AND completed (at 0 or max)
        : ButtonWidget(
          color: buttonColor,
          text: 'Start',
          iconLocation: 'assets/Icons/Play.svg',
          width: 200, // The original wide width
          onClicked: () {
            // _startTimer handles setting _hasStarted
            _startTimer();
          },
        );
  }
  // ============================================================
  // END OF REVERTED buildButtons METHOD
  // ============================================================

  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Text for rounds display
    String roundsText = "Round $_currentRound of $_roundCountSetting";
    // Use _hasStarted to determine initial round text display might be better
    if (!_hasStarted && !_isRunning) roundsText = "Configure in Settings";

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
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Timer View
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
                  // ============================================================
                  // REVERTED "Work Time"/"Break Time" Text
                  // ============================================================
                  Text(
                    _isBreakTime
                        ? "Break Time"
                        : "Work Time", // Original simpler logic
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      fontSize: screenWidth * 0.06,
                    ),
                  ),
                  // ============================================================
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    roundsText, // Keep using roundsText
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Image.asset(
                    _isBreakTime
                        ? 'assets/rest_froggy.png'
                        : 'assets/froggy.png',
                    height: screenHeight * 0.3,
                    color:
                        Theme.of(
                          context,
                        ).bottomNavigationBarTheme.selectedItemColor,
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
                  buildButtons(context), // Use the dynamic button builder
                  SizedBox(height: screenHeight * 0.02),
                  // Test button (optional)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _workMinutes = 0;
                        _workSeconds = 10;
                        _breakMinutes = 0;
                        _breakSeconds = 5;
                        _roundCountSetting = 2;
                      });
                      _updateSettings(
                        0,
                        10,
                        0,
                        5,
                        2,
                      ); // Use updateSettings to apply
                    },
                    child: const Text('Load Test Durations'),
                  ),
                ],
              ),
            ),
          ),
          // Settings View
          SettingsScreen(
            updateTimer: _updateSettings,
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

  // --- Permission Methods (Keep as is) ---
  /// Checks whether the app has permission to schedule exact alarms on Android.
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

  /// Requests permission to schedule exact alarms on Android, if not already granted.
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
}
