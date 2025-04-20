import 'package:flutter/material.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/screens/session_selection_screen.dart';
import 'package:froggydoro/widgets/settings_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:froggydoro/services/preferences_service.dart';

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

  /// Loads the saved theme mode from shared preferences and updates the state.
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

  /// Saves the selected theme mode to shared preferences.
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _getStringFromThemeMode(themeMode));
  }

  /// Converts a string representation of the theme mode to a `ThemeMode` object.
  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        throw ArgumentError('Invalid theme mode: $themeMode');
    }
  }

  /// Converts a `ThemeMode` object to its string representation.
  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Loads the wake lock setting from shared preferences and updates the state.
  void _loadWakeLock() async {
    final isWakeLockEnabled = await PreferencesService.loadWakeLock();
    setState(() {
      _isWakeLockEnabled = isWakeLockEnabled;
    });
    if (_isWakeLockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  /// Saves the wake lock setting to shared preferences and applies it.
  void _saveWakeLock(bool isWakeLockEnabled) async {
    await PreferencesService.saveWakeLock(isWakeLockEnabled);
    if (isWakeLockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  /// Loads the selected timer preset from the database and updates the state.
  Future<void> _loadSelectedPreset() async {
    if (_selectedPreset != null) return;
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
          const Text(
            'General',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

  /// Builds the UI for changing the theme mode.
  Widget buildChangeThemeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SettingsTile(
          title: 'Theme Mode',
          subtitle: selectedTheme,
          trailingIcon: Icons.arrow_drop_down,
          onTap: () {
            _showBottomSheet(
              context: context,
              children:
                  themeOptions.entries.map((entry) {
                    return ListTile(
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
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Builds the UI for changing the timer preset.
  Widget buildChangeTimeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SettingsTile(
          title: 'Session',
          subtitle:
              _selectedPreset != null
                  ? "Preset: ${_selectedPreset!.name}"
                  : "No preset selected",
          trailingIcon: Icons.arrow_forward,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SessionSelectionScreen(
                      onSessionChanged: (workDuration, breakDuration, count) {
                        widget.updateTimer(
                          workDuration,
                          0,
                          breakDuration,
                          0,
                          count,
                        );
                      },
                    ),
              ),
            );
            await _loadSelectedPreset();
          },
        ),
      ],
    );
  }

  /// Builds the UI for toggling the wake lock setting.
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

  static const List<String> ambienceOptions = [
    "None",
    "Bonfire",
    "Chirping",
    "Rain",
    "River",
  ];

  /// Saves the selected ambient sound setting to shared preferences.
  Future<void> _saveAmbience(String ambience) async {
    await PreferencesService.saveAmbience(ambience);
  }

  /// Loads the ambient sound setting from shared preferences and updates the state.
  Future<void> _loadAmbience() async {
    final ambience = await PreferencesService.loadAmbience();
    setState(() {
      selectedAmbience = ambience;
    });
  }

  String selectedAmbience = 'None';

  /// Builds the UI for changing the ambient sound setting.
  Widget buildChangeAmbienceSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambience Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SettingsTile(
          title: 'Ambient Sounds',
          subtitle: selectedAmbience,
          trailingIcon: Icons.arrow_drop_down,
          onTap: () {
            _showBottomSheet(
              context: context,
              children:
                  ambienceOptions.map((String value) {
                    return ListTile(
                      title: Text(value),
                      onTap: () async {
                        setState(() {
                          selectedAmbience = value;
                        });
                        await _saveAmbience(value);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Displays a bottom sheet with the provided list of widgets.
  void _showBottomSheet({
    required BuildContext context,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        );
      },
    );
  }
}
