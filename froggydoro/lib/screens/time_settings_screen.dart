import 'package:flutter/material.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/time_step.dart';

class TimeSettingsScreen extends StatefulWidget {
  final Function(int, int, int, int, int) updateTimer;

  const TimeSettingsScreen({required this.updateTimer, super.key});

  @override
  State<TimeSettingsScreen> createState() => _TimeSettingsScreenState();
}

class _TimeSettingsScreenState extends State<TimeSettingsScreen> {
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _defaultRoundCount = 4;
  final TextEditingController _presetNameController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;

  // Initializes the state and loads time settings from shared preferences
  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
  }

  // Loads the time settings from shared preferences
  Future<void> _loadTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _defaultRoundCount = prefs.getInt('defaultRoundCount') ?? 4;
    });
  }

  // Saves the time settings to shared preferences
  Future<void> _saveTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workMinutes', _workMinutes);
    await prefs.setInt('breakMinutes', _breakMinutes);
    await prefs.setInt('defaultRoundCount', _defaultRoundCount);
  }

  // Saves the preset to the database with the given name
  Future<void> _savePreset(String name) async {
    _databaseService.addTimer(
      name,
      _workMinutes,
      _breakMinutes,
      count: _defaultRoundCount,
    );
  }

  // Loads the selected preset from the database and applies it to the timer settings
  void _applyPreset(TimerObject timer) {
    setState(() {
      _workMinutes = timer.workDuration;
      _breakMinutes = timer.breakDuration;
      _defaultRoundCount = timer.count;
    });
    widget.updateTimer(_workMinutes, 0, _breakMinutes, 0, _defaultRoundCount);
  }

  // Interface for the time settings screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Time',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: -0.24,
          ),
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
            TimeStep(
              label: "Round Count",
              value: _defaultRoundCount,
              onIncrement: addRound,
              onDecrement: subtractRound,
              unit: 'rounds',
            ),
            ElevatedButton(onPressed: saveTime, child: const Text("Set")),
            const SizedBox(height: 20),
            const Text(
              "Create a new preset:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _presetNameController,
              decoration: const InputDecoration(
                labelText: "Preset Name",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_presetNameController.text.isNotEmpty) {
                  _savePreset(_presetNameController.text);
                  _presetNameController.clear();
                }
                setState(() {});
              },
              child: const Text("Save Preset"),
            ),
            const SizedBox(height: 20),
            const Text(
              "Available Presets:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            FutureBuilder(
              future: _databaseService.getTimers(),
              builder: (context, snapshot) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    TimerObject timer = snapshot.data![index];
                    return ListTile(
                      title: Text(timer.name),
                      onTap: () {
                        _applyPreset(timer);
                        _databaseService.setPicked(timer.id);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _databaseService.deleteTimer(timer.id);
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Increments work time by 5 minutes, up to a maximum of 60 minutes
  void addWorkTime() {
    setState(() {
      if (_workMinutes < 60) {
        _workMinutes += 5;
      }
    });
  }

  // Decrements work time by 5 minutes, down to a minimum of 5 minutes
  void subtractWorkTime() {
    setState(() {
      if (_workMinutes > 5) {
        _workMinutes -= 5;
      }
    });
  }

  // Increments break time by 5 minutes, up to a maximum of 30 minutes
  void addBreakTime() {
    setState(() {
      if (_breakMinutes < 30) {
        _breakMinutes += 5;
      }
    });
  }

  // Decrements break time by 5 minutes, down to a minimum of 5 minutes
  void subtractBreakTime() {
    setState(() {
      if (_breakMinutes > 5) {
        _breakMinutes -= 5;
      }
    });
  }

  // Increments round count by 1, up to a maximum of 10 rounds
  void addRound() {
    setState(() {
      if (_defaultRoundCount < 10) {
        _defaultRoundCount += 1;
      }
    });
  }

  // Decrements round count by 1, down to a minimum of 1 round
  void subtractRound() {
    setState(() {
      if (_defaultRoundCount > 1) {
        _defaultRoundCount -= 1;
      }
    });
  }

  // Saves the current time settings to shared preferences and updates the timer
  void saveTime() {
    widget.updateTimer(_workMinutes, 0, _breakMinutes, 0, _defaultRoundCount);
    _saveTimeSettings();
  }
}
