import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/time_picker.dart';

class TimeSettingsScreen extends StatefulWidget {
  final Function(int, int, int, int, int, int) updateTimer;

  const TimeSettingsScreen({required this.updateTimer, super.key});

  @override
  State<TimeSettingsScreen> createState() => _TimeSettingsScreenState();
}

class _TimeSettingsScreenState extends State<TimeSettingsScreen> {
  int _workHours = 0;
  int _workMinutes = 25;
  int _workSeconds = 0;
  int _breakHours = 0;
  int _breakMinutes = 5;
  int _breakSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
  }

  Future<void> _loadTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workHours = prefs.getInt('workHours') ?? 0;
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _workSeconds = prefs.getInt('workSeconds') ?? 0;
      _breakHours = prefs.getInt('breakHours') ?? 0;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _breakSeconds = prefs.getInt('breakSeconds') ?? 0;
    });
  }

  Future<void> _saveTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workHours', _workHours);
    await prefs.setInt('workMinutes', _workMinutes);
    await prefs.setInt('workSeconds', _workSeconds);
    await prefs.setInt('breakHours', _breakHours);
    await prefs.setInt('breakMinutes', _breakMinutes);
    await prefs.setInt('breakSeconds', _breakSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TimePickerWidget(
              label: "Set Work Time",
              hours: _workHours,
              minutes: _workMinutes,
              seconds: _workSeconds,
              onHoursChanged: (value) => setState(() => _workHours = value),
              onMinutesChanged: (value) => setState(() => _workMinutes = value),
              onSecondsChanged: (value) => setState(() => _workSeconds = value),
            ),
            const SizedBox(height: 20),
            TimePickerWidget(
              label: "Set Break Time",
              hours: _breakHours,
              minutes: _breakMinutes,
              seconds: _breakSeconds,
              onHoursChanged: (value) => setState(() => _breakHours = value),
              onMinutesChanged:
                  (value) => setState(() => _breakMinutes = value),
              onSecondsChanged:
                  (value) => setState(() => _breakSeconds = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.updateTimer(
                  _workHours,
                  _workMinutes,
                  _workSeconds,
                  _breakHours,
                  _breakMinutes,
                  _breakSeconds,
                );
                _saveTimeSettings();
                Navigator.pop(context);
              },
              child: const Text("Set"),
            ),
          ],
        ),
      ),
    );
  }
}
