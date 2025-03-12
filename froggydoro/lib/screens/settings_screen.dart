import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'time_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int, int, int, int) updateTimer;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    required this.updateTimer,
    required this.onThemeModeChanged,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = _getThemeModeFromString(themeMode);
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
          const SizedBox(height: 20),
          buildChangeTimeSetting(),
        ],
      ),
    );
  }

  Widget buildChangeThemeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme Mode',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: _themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  setState(() {
                    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
                  });
                  widget.onThemeModeChanged(_themeMode);
                  _saveThemeMode(_themeMode);
                },
              ),
              SwitchListTile(
                title: const Text('Follow System'),
                value: _themeMode == ThemeMode.system,
                onChanged: (bool value) {
                  setState(() {
                    _themeMode = value ? ThemeMode.system : ThemeMode.light;
                  });
                  widget.onThemeModeChanged(_themeMode);
                  _saveThemeMode(_themeMode);
                },
              ),
            ],
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
            title: const Text('Work/Break Time'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          TimeSettingsScreen(updateTimer: widget.updateTimer),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
