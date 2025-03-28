import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/time_step.dart';

class TimeSettingsScreen extends StatefulWidget {
  final Function(int, int, int, int) updateTimer;

  const TimeSettingsScreen({required this.updateTimer, super.key});

  @override
  State<TimeSettingsScreen> createState() => _TimeSettingsScreenState();
}

class _TimeSettingsScreenState extends State<TimeSettingsScreen> {
  int _workMinutes = 25;
  int _breakMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
  }

  Future<void> _loadTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
    });
  }

  Future<void> _saveTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workMinutes', _workMinutes);
    await prefs.setInt('breakMinutes', _breakMinutes);
  }

  void saveTime() {
    widget.updateTimer(_workMinutes, 0, _breakMinutes, 0);
    _saveTimeSettings();
  }

  void addWorkTime() {
    setState(() {
      if (_workMinutes < 60) {
        _workMinutes += 5;
      }
    });
  }

  void subtractWorkTime() {
    setState(() {
      if (_workMinutes > 5) {
        _workMinutes -= 5;
      }
    });
  }

  void addBreakTime() {
    setState(() {
      if (_breakMinutes < 30) {
        _breakMinutes += 5;
      }
    });
  }

  void subtractBreakTime() {
    setState(() {
      if (_breakMinutes > 5) {
        _breakMinutes -= 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Time',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TimeStep(
              label: "Work Time",
              value: _workMinutes,
              onIncrement: addWorkTime,
              onDecrement: subtractWorkTime,
              unit: 'min',
            ),
            const SizedBox(height: 20),
            TimeStep(
              label: "Break Time",
              value: _breakMinutes,
              onIncrement: addBreakTime,
              onDecrement: subtractBreakTime,
              unit: 'min',
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveTime, child: const Text("Set")),
          ],
        ),
      ),
    );
  }
}
