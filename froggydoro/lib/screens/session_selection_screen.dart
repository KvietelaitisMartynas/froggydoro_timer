import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/timerObject.dart';
import '../screens/time_settings_screen.dart';

class SessionSelectionScreen extends StatefulWidget {
  final void Function(int workDuration, int breakDuration, int count)
  onSessionChanged;

  const SessionSelectionScreen({required this.onSessionChanged, super.key});

  @override
  State<SessionSelectionScreen> createState() => _SessionSelectionScreenState();
}

class _SessionSelectionScreenState extends State<SessionSelectionScreen> {
  List<TimerObject> _presets = [];
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final allPresets = await _databaseService.getTimers();
    setState(() {
      _presets = allPresets;
    });
  }

  Future<void> _selectPreset(TimerObject preset) async {
    await _databaseService.setPickedTimer(preset.id);

    widget.onSessionChanged(
      preset.workDuration,
      preset.breakDuration,
      preset.count,
    );
    Navigator.pop(context);
  }

  Future<void> _editPreset(TimerObject preset) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TimeSettingsScreen(
              preset: preset,
              updateTimer: (workDuration, breakDuration, count) {
                setState(() {
                  final index = _presets.indexWhere((p) => p.id == preset.id);
                  if (index != -1) {
                    _presets[index] = TimerObject(
                      id: preset.id,
                      name: preset.name,
                      workDuration: workDuration,
                      breakDuration: breakDuration,
                      count: count,
                    );
                  }
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Session Preset")),
      body: ListView.builder(
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text(preset.name),
              subtitle: Text(
                '${preset.count} times | ${preset.workDuration} min | ${preset.breakDuration} min',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      _databaseService.deleteTimer(preset.id);
                      _loadPresets();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed:
                        () => _editPreset(preset),
                  ),
                ],
              ),
              onTap: () => _selectPreset(preset),
            ),
          );
        },
      ),
    );
  }
}
