import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/timerObject.dart';
import '../screens/time_settings_screen.dart';

class SessionSelectionScreen extends StatefulWidget {
  final void Function(int workDuration, int breakDuration, int count) onSessionChanged;

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
        builder: (context) => TimeSettingsScreen(
          preset: preset,
          updateTimer: (workDuration, breakDuration, count, presetName) {
            setState(() {
              final index = _presets.indexWhere((p) => p.id == preset.id);
              if (index != -1) {
                _presets[index] = TimerObject(
                  id: preset.id,
                  name: presetName,
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

  void _addNewPreset() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TimeSettingsScreen(
        preset: TimerObject(
          id: 0, // id will be set after saving to the database
          name: '', // Default name, will be set by the user
          workDuration: 25, // Default work duration
          breakDuration: 5, // Default break duration
          count: 1, // Default round count
        ),
        updateTimer: (workDuration, breakDuration, count, presetName) {
          // This will be called once the user confirms the changes
          setState(() {
            // Create new TimerObject with the updated values
            final newPreset = TimerObject(
              id: 0, // id will be set by the database
              name: presetName, // Name from the user input
              workDuration: workDuration,
              breakDuration: breakDuration,
              count: count,
            );

            // Save the new preset to the database inside TimeSettingsScreen
            _databaseService.addTimer(
              newPreset.name, 
              newPreset.workDuration, 
              newPreset.breakDuration, 
              count: newPreset.count
            ).then((id) {
              final updatedPreset = newPreset.copyWith(id: id);

              // Add the new preset to the list
              _presets.add(updatedPreset);

              // Reload the list of presets (optional)
              _loadPresets();
            }).catchError((e) {
              print("Error inserting preset: $e");
            });
          });
        },
      ),
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Session Preset"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewPreset,
          ),
        ],
      ),
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
                    onPressed: () => _editPreset(preset),
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
