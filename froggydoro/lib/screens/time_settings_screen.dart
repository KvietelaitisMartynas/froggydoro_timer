import 'package:flutter/material.dart';
import '../models/timerObject.dart';
import '../services/database_service.dart';
import '../widgets/time_step.dart';

class TimeSettingsScreen extends StatefulWidget {
  final TimerObject preset;
  final Function(int workDuration, int breakDuration, int count) updateTimer;

  const TimeSettingsScreen({
    required this.preset,
    required this.updateTimer,
    super.key,
  });

  @override
  _TimeSettingsScreenState createState() => _TimeSettingsScreenState();
}

class _TimeSettingsScreenState extends State<TimeSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  late TextEditingController _nameController;
  late int _workDuration;
  late int _breakDuration;
  late int _count;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _workDuration = widget.preset.workDuration;
    _breakDuration = widget.preset.breakDuration;
    _count = widget.preset.count;
  }

  Future<void> _saveChanges() async {
    _databaseService.updateTimer(
      widget.preset.id,
      _nameController.text,
      _workDuration,
      _breakDuration,
      count: _count,
    );

    //await _databaseService.setPickedTimer(widget.preset.id);

    widget.updateTimer(_workDuration, _breakDuration, _count);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Session Preset")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Preset Name"),
            ),
            const SizedBox(height: 16),
            TimeStep(
              label: "Work Duration",
              value: _workDuration,
              unit: "min",
              onIncrement: addWorkTime,
              onDecrement: subtractWorkTime
            ),
            const SizedBox(height: 16),
            TimeStep(
              label: "Break Duration",
              value: _breakDuration,
              unit: "min",
              onIncrement: addBreakTime,
              onDecrement: subtractBreakTime
            ),
            const SizedBox(height: 16),
            TimeStep(
              label: "Round Count",
              value: _count,
              unit: "rounds",
              onIncrement: addRound,
              onDecrement: subtractRound
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  // Increments work time by 5 minutes, up to a maximum of 60 minutes
  void addWorkTime() {
    setState(() {
      if (_workDuration < 60) {
        _workDuration += 5;
      }
    });
  }

  // Decrements work time by 5 minutes, down to a minimum of 5 minutes
  void subtractWorkTime() {
    setState(() {
      if (_workDuration > 5) {
        _workDuration -= 5;
      }
    });
  }

  // Increments break time by 5 minutes, up to a maximum of 30 minutes
  void addBreakTime() {
    setState(() {
      if (_breakDuration < 30) {
        _breakDuration += 5;
      }
    });
  }

  // Decrements break time by 5 minutes, down to a minimum of 5 minutes
  void subtractBreakTime() {
    setState(() {
      if (_breakDuration > 5) {
        _breakDuration -= 5;
      }
    });
  }

  // Increments round count by 1, up to a maximum of 10 rounds
  void addRound() {
    setState(() {
      if (_count < 10) {
        _count += 1;
      }
    });
  }

  // Decrements round count by 1, down to a minimum of 1 round
  void subtractRound() {
    setState(() {
      if (_count > 1) {
        _count -= 1;
      }
    });
  }


}


