import 'dart:async';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  final int workMinutes;
  final int workSeconds;
  final int breakMinutes;
  final int breakSeconds;

  const TimerScreen({
    required this.workMinutes,
    required this.workSeconds,
    required this.breakMinutes,
    required this.breakSeconds,
    super.key,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int _remainingTime;
  bool _isWorkPhase = true;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _remainingTime =
        _isWorkPhase
            ? _convertToSeconds(
              widget.workMinutes,
              widget.workSeconds,
            )
            : _convertToSeconds(
              widget.breakMinutes,
              widget.breakSeconds,
            );
    setState(() {});
  }

  int _convertToSeconds(int minutes, int seconds) {
    return (minutes * 60) + seconds;
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _timer?.cancel();
          _isWorkPhase = !_isWorkPhase;
          _resetTimer();
          _startPauseTimer(); // Automatically switch between work & break
        }
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _resetTimer();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isWorkPhase ? "Work Time" : "Break Time",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _formatTime(_remainingTime),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startPauseTimer,
              child: Text(_isRunning ? "Pause" : "Start"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: _stopTimer, child: const Text("Reset")),
          ],
        ),
      ],
    );
  }
}
