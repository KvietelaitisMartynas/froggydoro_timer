import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String ambienceKey = 'selectedAmbience';
  static const String wakeLockKey = 'isWakeLockEnabled';

  static Future<void> saveAmbience(String ambience) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ambienceKey, ambience);
  }

  static Future<String> loadAmbience() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ambienceKey) ?? 'None';
  }

  static Future<void> saveWakeLock(bool isWakeLockEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(wakeLockKey, isWakeLockEnabled);
  }

  static Future<bool> loadWakeLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(wakeLockKey) ?? false;
  }
}
