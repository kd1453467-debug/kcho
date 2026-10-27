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

  /// Baked in at build time via `--dart-define=GROQ_API_KEY=...` — never
  /// written to a file, so it's never committed to the (public) repo. Empty
  /// in a plain `flutter run`/checkout, which leaves the AI features asking
  /// the user for their own key, same as before.
  static const String _builtInGroqApiKey = String.fromEnvironment('GROQ_API_KEY');

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

  /// The key the user explicitly typed into Settings, if any — empty
  /// otherwise. Used only to populate the Settings text field, so a
  /// build-time [_builtInGroqApiKey] never shows up (and can't be copied)
  /// from the UI.
  Future<String> getStoredGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGroqApiKey) ?? '';
  }

  /// Groq API key for the AI auto-fill feature (see GroqService). A value
  /// the user typed into Settings always wins; otherwise falls back to the
  /// build-time [_builtInGroqApiKey], if any.
  Future<String> getGroqApiKey() async {
    final stored = await getStoredGroqApiKey();
    return stored.isNotEmpty ? stored : _builtInGroqApiKey;
  }

  Future<void> setGroqApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGroqApiKey, value);
  }
}
