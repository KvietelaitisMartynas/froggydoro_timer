import 'package:flutter/material.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/screens/session_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:froggydoro/services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int, int, int, int, int) updateTimer;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    required this.updateTimer,
    required this.onThemeModeChanged,
    super.key,
  });

  static Future<String> getAmbience() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedAmbience') ?? 'Bonfire';
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _DropdownMenu extends StatefulWidget {
  final List<String> options;
  final String initialValue;
  final ValueChanged<String?> onChanged;

  const _DropdownMenu({
    required this.options,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  _DropdownMenuState createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<_DropdownMenu> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedValue = newValue;
          });
          widget.onChanged(newValue);
        }
      },
      items:
          widget.options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isWakeLockEnabled = false;
  TimerObject? _selectedPreset;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadWakeLock();
    _loadAmbience();
    _loadSelectedPreset();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';

    setState(() {
      _themeMode = _getThemeModeFromString(themeModeString);
      selectedTheme =
          themeOptions.entries
              .firstWhere(
                (entry) => entry.value['value'] == themeModeString,
                orElse: () => themeOptions.entries.last,
              )
              .key;
    });
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _getStringFromThemeMode(themeMode));
  }

  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  void _loadWakeLock() async {
    final prefs = await SharedPreferences.getInstance();
    final isWakeLockEnabled = prefs.getBool('isWakeLockEnabled') ?? false;
    setState(() {
      _isWakeLockEnabled = isWakeLockEnabled;
    });
    if (_isWakeLockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _saveWakeLock(bool isWakeLockEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWakeLockEnabled', isWakeLockEnabled);
    if (_isWakeLockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _loadSelectedPreset() async {
    final pickedPreset = await _databaseService.getPickedTimer();
    if (mounted) {
      setState(() {
        _selectedPreset = pickedPreset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'General',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ), // Make the text bigger
          ),
          const SizedBox(height: 10),
          buildChangeThemeSetting(),
          const SizedBox(height: 10),
          buildChangeWakelockSetting(),
          const SizedBox(height: 20),
          buildChangeTimeSetting(),
          const SizedBox(height: 20),
          buildChangeAmbienceSetting(),
        ],
      ),
    );
  }

  final Map<String, Map<String, dynamic>> themeOptions = {
    'Light Mode': {'value': 'light', 'icon': Icons.wb_sunny},
    'Dark Mode': {'value': 'dark', 'icon': Icons.nightlight_round},
    'Follow System': {'value': 'system', 'icon': Icons.brightness_4},
  };

  String selectedTheme = 'Follow System';

  Widget buildChangeThemeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: const Text('Theme Mode'),
            subtitle: Row(
              children: [
                Icon(themeOptions[selectedTheme]?['icon'], size: 20),
                const SizedBox(width: 8),
                Text(selectedTheme),
              ],
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          themeOptions.entries
                              .map(
                                (entry) => ListTile(
                                  leading: Icon(entry.value['icon']),
                                  title: Text(entry.key),
                                  onTap: () async {
                                    setState(() {
                                      selectedTheme = entry.key;
                                      _themeMode = _getThemeModeFromString(
                                        entry.value['value'],
                                      );
                                    });
                                    await _saveThemeMode(_themeMode);
                                    widget.onThemeModeChanged(_themeMode);
                                    Navigator.pop(context);
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildChangeTimeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: const Text('Session'),
            subtitle:
                _selectedPreset != null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text("Preset: ${_selectedPreset!.name}")],
                    )
                    : const Text("No preset selected"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SessionSelectionScreen(
                        onSessionChanged: (workDuration, breakDuration, count) {
                          widget.updateTimer(
                            workDuration,
                            breakDuration,
                            count,
                            0,
                            0,
                          );
                        },
                      ),
                ),
              );
              await _loadSelectedPreset();
            },
          ),
        ),
      ],
    );
  }

  Widget buildChangeWakelockSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Always on display',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SwitchListTile(
            title: const Text('Enable'),
            value: _isWakeLockEnabled,
            onChanged: (bool value) {
              setState(() {
                _isWakeLockEnabled = value;
              });
              _saveWakeLock(value);
            },
          ),
        ),
      ],
    );
  }

  static const String ambienceKey = 'selectedAmbience';

  Future<void> _saveAmbience(String ambience) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ambienceKey, ambience);
  }

  Future<void> _loadAmbience() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAmbience = prefs.getString(ambienceKey) ?? 'None';
    });
  }

  String selectedAmbience = 'None';

  Widget buildChangeAmbienceSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambience Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: const Text('Ambient Sounds'),
            subtitle: Text(selectedAmbience),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          ["None", "Bonfire", "Chirping", "Rain", "River"]
                              .map(
                                (String value) => ListTile(
                                  title: Text(value),
                                  onTap: () async {
                                    setState(() {
                                      selectedAmbience = value;
                                    });
                                    await _saveAmbience(value);
                                    Navigator.pop(context);
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
