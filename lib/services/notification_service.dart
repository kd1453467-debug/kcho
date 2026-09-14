import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the single daily "study reminder" local notification.
///
/// The real target is iOS, but the Darwin (iOS/macOS) path is wired up for
/// both — desktop builds are also used during development, and
/// `flutter_local_notifications` throws if you initialize it without
/// settings for the platform it's actually running on. No web support:
/// this package has no web implementation at all, so every method here is
/// a no-op on web.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _reminderNotificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Fall back to whatever `timezone` defaults to (UTC) if the device's
      // zone can't be resolved — the reminder will still fire, just
      // possibly at the wrong wall-clock hour until this succeeds.
    }

    // Darwin settings cover both iOS and macOS; the plugin requires the
    // settings block matching whichever platform it's actually running on
    // to be present, or `initialize()` throws.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(iOS: darwinSettings, macOS: darwinSettings),
    );
    _initialized = true;
  }

  /// Asks the user for notification permission. Returns whether it was granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _ensureInitialized();

    final bool? granted;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        granted = await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case TargetPlatform.macOS:
        granted = await _plugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      default:
        // Not a target platform for this app — nothing to request.
        granted = false;
    }
    return granted ?? false;
  }

  /// Schedules (replacing any previous one) a daily reminder at [hour]:[minute].
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _reminderNotificationId,
      'K帳',
      'K帳で復習する時間です！',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily reminder.
  Future<void> cancel() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(_reminderNotificationId);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
