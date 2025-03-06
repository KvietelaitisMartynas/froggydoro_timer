import 'package:flutter/material.dart';
import '../widgets/time_picker.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int, int, int, int, int, int) updateTimer;

  const SettingsScreen({required this.updateTimer, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _workHours = 0;
  int _workMinutes = 25;
  int _workSeconds = 0;
  int _breakHours = 0;
  int _breakMinutes = 5;
  int _breakSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            onMinutesChanged: (value) => setState(() => _breakMinutes = value),
            onSecondsChanged: (value) => setState(() => _breakSeconds = value),
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
            },
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }
}
