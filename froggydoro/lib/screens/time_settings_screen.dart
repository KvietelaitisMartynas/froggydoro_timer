import 'package:flutter/material.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  List<Map<String, dynamic>> _presets = [];
  TextEditingController _presetNameController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadTimeSettings();
    //_loadPresets();
  }

  Future<void> _loadTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workMinutes = prefs.getInt('workMinutes') ?? 25;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
      _defaultRoundCount = prefs.getInt('defaultRoundCount') ?? 4;
    });
  }

  Future<void> _saveTimeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workMinutes', _workMinutes);
    await prefs.setInt('breakMinutes', _breakMinutes);
    await prefs.setInt('defaultRoundCount', _defaultRoundCount);
  }

  Future<void> _savePreset(String name) async {
    final prefs = await SharedPreferences.getInstance();

    _databaseService.addTimer(
      name,
      _workMinutes,
      _breakMinutes,
      count: _roundCount,
    );
    /* final newPreset = {
      'name': name,
      'workMinutes': _workMinutes,
      'breakMinutes': _breakMinutes,
      'defaultRoundCount': _defaultRoundCount,
    };

    List<String> savedPresets = prefs.getStringList('presets') ?? [];
    savedPresets.add(name);
    prefs.setStringList('presets', savedPresets);

    List<String> presetValues = prefs.getStringList('presetValues') ?? [];
    presetValues.add(json.encode(newPreset));
    prefs.setStringList('presetValues', presetValues);

    setState(() {
      _presets.add(newPreset);
    }); */
  }

  /* Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPresets = prefs.getStringList('presets') ?? [];
    List<String> presetValues = prefs.getStringList('presetValues') ?? [];

    List<Timer> timers = await _databaseService.getTimers();

    List<Map<String, dynamic>> loadedPresets = [];

    for (int i = 0; i < timers.length; i++) {
      try {
        Map<String, dynamic> preset = json.decode(presetValues[i]);
        if (preset['name'] != null) {
          loadedPresets.add(preset);
        }
      } catch (e) {
        print("Error loading preset: $e");
      }
    }

    setState(() {
      _presets = loadedPresets;
    });
  } */

  void _applyPreset(TimerObject timer) {
    setState(() {
      _workMinutes = timer.workDuration ?? 25;
      _breakMinutes = timer.breakDuration ?? 5;
      _roundCount = timer.count ?? 4;
    });
    widget.updateTimer(_workMinutes, 0, _breakMinutes, 0, _defaultRoundCount);
  }

  /* Future<void> _deletePreset(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedPresets = prefs.getStringList('presets') ?? [];
    List<String> presetValues = prefs.getStringList('presetValues') ?? [];

    savedPresets.removeAt(index);
    presetValues.removeAt(index);

    prefs.setStringList('presets', savedPresets);
    prefs.setStringList('presetValues', presetValues);

    setState(() {
      _presets.removeAt(index);
    });
  } */

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
                      title: Text(timer.name ?? 'Unnamed Preset'),
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

  void addRound() {
    setState(() {
      if (_defaultRoundCount < 10) {
        _defaultRoundCount += 1;
      }
    });
  }

  void subtractRound() {
    setState(() {
      if (_defaultRoundCount > 1) {
        _defaultRoundCount -= 1;
      }
    });
  }

  void saveTime() {
    widget.updateTimer(_workMinutes, 0, _breakMinutes, 0, _defaultRoundCount);
    _saveTimeSettings();
  }
}
