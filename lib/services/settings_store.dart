import 'package:shared_preferences/shared_preferences.dart';

/// Local-only app settings (profile name, reminder prefs), persisted with
/// shared_preferences. No backend, no account — everything stays on-device.
class SettingsStore {
  static const _keyDisplayName = 'display_name';
  static const _keyReminderEnabled = 'reminder_enabled';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyGroqApiKey = 'groq_api_key';

  static const int defaultReminderHour = 20;
  static const int defaultReminderMinute = 0;

  Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName) ?? '';
  }

  Future<void> setDisplayName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, value);
  }

  Future<bool> getReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderEnabled) ?? false;
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, value);
  }

  /// Returns (hour, minute), defaulting to 20:00.
  Future<(int hour, int minute)> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyReminderHour) ?? defaultReminderHour;
    final minute = prefs.getInt(_keyReminderMinute) ?? defaultReminderMinute;
    return (hour, minute);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  /// Groq API key for the AI auto-fill feature (see GroqService). Kept
  /// in on-device prefs only — never committed to source control.
  Future<String> getGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGroqApiKey) ?? '';
  }

  Future<void> setGroqApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGroqApiKey, value);
  }
}
