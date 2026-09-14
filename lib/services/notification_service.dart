import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the single daily "study reminder" local notification.
///
/// This app is iOS-focused, so only the Darwin (iOS) notification path is
/// wired up. No backend, no push — everything happens on-device.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _reminderNotificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Fall back to whatever `timezone` defaults to (UTC) if the device's
      // zone can't be resolved — the reminder will still fire, just
      // possibly at the wrong wall-clock hour until this succeeds.
    }

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(iOS: iosSettings));
    _initialized = true;
  }

  /// Asks the user for notification permission. Returns whether it was granted.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  /// Schedules (replacing any previous one) a daily reminder at [hour]:[minute].
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _reminderNotificationId,
      'K帳',
      'K帳で復習する時間です！',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily reminder.
  Future<void> cancel() async {
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
