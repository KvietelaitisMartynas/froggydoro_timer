import 'dart:async';
import 'package:flutter/material.dart';
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
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _workHours = 0;  // Default work time is 0 hours
  int _workMinutes = 25;  // Default work time is 25 minutes
  int _workSeconds = 0;  // Default work time is 0 seconds

  int _breakHours = 0;  // Default break time is 0 hours
  int _breakMinutes = 5;  // Default break time is 5 minutes
  int _breakSeconds = 0;  // Default break time is 0 seconds

  int _totalSeconds = 0;
  bool _isBreakTime = false;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _setCustomTime();
  }

  void _startTimer() {
    if (_isRunning || _totalSeconds == 0) return;

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
  }

  void _restartWorkTime() {
    setState(() {
      _isBreakTime = false;
      _totalSeconds = _workHours * 3600 + _workMinutes * 60 + _workSeconds;
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
    _setCustomTime();
  }

  void _setCustomTime() {
    setState(() {
      _totalSeconds = _workHours * 3600 + _workMinutes * 60 + _workSeconds;
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Froggydoro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isBreakTime ? "Break Time" : "Work Time",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isBreakTime ? Colors.green : Colors.red),
            ),
            Text(
              _formatTime(_totalSeconds),
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Work Time Pickers
            const Text("Set Work Time"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberPicker(
                  value: _workHours,
                  minValue: 0,
                  maxValue: 23,
                  onChanged: (value) => setState(() => _workHours = value),
                ),
                const Text(" : "),
                NumberPicker(
                  value: _workMinutes,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _workMinutes = value),
                ),
                const Text(" : "),
                NumberPicker(
                  value: _workSeconds,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _workSeconds = value),
                ),
              ],
            ),

            // Break Time Pickers
            const Text("Set Break Time"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberPicker(
                  value: _breakHours,
                  minValue: 0,
                  maxValue: 23,
                  onChanged: (value) => setState(() => _breakHours = value),
                ),
                const Text(" : "),
                NumberPicker(
                  value: _breakMinutes,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _breakMinutes = value),
                ),
                const Text(" : "),
                NumberPicker(
                  value: _breakSeconds,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) => setState(() => _breakSeconds = value),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setCustomTime,
              child: const Text('Set'),
            ),
            const SizedBox(height: 10),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startTimer, child: const Text('Start')),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _stopTimer, child: const Text('Stop')),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _resetTimer, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
