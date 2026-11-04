import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PlannerReminderService {
  PlannerReminderService._();

  static final PlannerReminderService instance = PlannerReminderService._();
  static const int _notificationId = 7301;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> _ensureInitialized() async {
    final initialization = _initialization ??= _initialize();
    try {
      await initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> scheduleDailyReminder(String time) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Daily planner reminders are currently supported on Android.');
    }

    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('Invalid reminder time: $time');
    }

    await _ensureInitialized();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final permissionGranted = await android?.requestNotificationsPermission();
    if (permissionGranted == false) return false;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _notificationId,
      'কুরআন তিলাওয়াতের সময়',
      'আজকের তিলাওয়াত ও রুটিনের জন্য কিছু সময় রাখুন।',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quran_planner_daily',
          'দৈনিক কুরআন রিমাইন্ডার',
          channelDescription: 'দৈনিক তিলাওয়াত ও রিভিশন রিমাইন্ডার',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _notifications.cancel(_notificationId);
  }
}
