import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int reminderId = 1001;
  static const int budgetWarnId = 1002;
  static const int budgetOverId = 1003;
  static const int testId = 1099;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      // Scheduling needs to know the phone's timezone to fire at the
      // right LOCAL time.
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (e) {
        debugPrint('Could not read device timezone: $e');
      }

      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  NotificationDetails _details(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Asks the user for permission (Android 13+ and iOS require it).
    /// Asks the user for permission (Android 13+ and iOS require it).
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      // The declared type on the left tells Dart which platform
      // implementation to return, so no angle brackets are needed.
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
    return false;
  }

  /// Repeats every day at [time]. Same id = replaces the old schedule.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (!_ready) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        reminderId,
        "Did you log today's expenses?",
        'It only takes a few seconds to keep your budget on track.',
        when,
        _details('daily_reminder', 'Daily reminder'),
        // "inexact" = no special exact-alarm permission needed
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }

  Future<void> cancelReminder() async {
    if (_ready) await _plugin.cancel(reminderId);
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  /// Shows a notification immediately (budget alerts and the test button).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String channelId = 'budget_alerts',
    String channelName = 'Budget alerts',
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(id, title, body, _details(channelId, channelName));
    } catch (e) {
      debugPrint('Showing notification failed: $e');
    }
  }
}