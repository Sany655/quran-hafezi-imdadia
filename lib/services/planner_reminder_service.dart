import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/hifz_model.dart';
import '../models/planner_model.dart';

class PlannerReminderService {
  PlannerReminderService._();

  static final PlannerReminderService instance = PlannerReminderService._();
  static const int _notificationId = 7301;
  static const int _sabaqNotificationId = 7302;
  static const int _sabqiNotificationId = 7303;
  static const int _manzilNotificationId = 7304;
  static const int _hifzWeeklyNotificationBase = 7500;
  static const int _hifzWeeklyNotificationCount = 21;
  static const int _readerSessionNotificationBase = 7400;
  static const int _readerSessionNotificationCount = 100;

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
    tz.setLocalLocation(tz.getLocation(localTimezone));

    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> scheduleDailyReminder(String time) async {
    return _scheduleReminder(
      id: _notificationId,
      time: time,
      title: 'কুরআন তিলাওয়াতের সময়',
      body: 'আজকের তিলাওয়াত ও রুটিনের জন্য কিছু সময় রাখুন।',
      channelId: 'quran_planner_daily',
      channelName: 'দৈনিক কুরআন রিমাইন্ডার',
    );
  }

  Future<bool> scheduleHifzReminders(HifzSettings settings) async {
    final reminders = [
      (
        category: 0,
        enabled: settings.sabaqReminderEnabled,
        time: settings.sabaqReminderTime,
        weekdays: settings.sabaqWeekdays,
        title: 'আজকের সবক',
        body: 'নতুন মুখস্থের নির্ধারিত সময় হয়েছে।',
      ),
      (
        category: 1,
        enabled: settings.sabqiReminderEnabled,
        time: settings.sabqiReminderTime,
        weekdays: settings.sabqiWeekdays,
        title: 'আজকের সবকি',
        body: 'সাম্প্রতিক মুখস্থ পুনরাবৃত্তির নির্ধারিত সময় হয়েছে।',
      ),
      (
        category: 2,
        enabled: settings.manzilReminderEnabled,
        time: settings.manzilReminderTime,
        weekdays: settings.manzilWeekdays,
        title: 'আজকের মনজিল',
        body: 'পুরোনো মুখস্থ পুনরাবৃত্তির নির্ধারিত সময় হয়েছে।',
      ),
    ];
    final activeReminders = reminders
        .where((reminder) => reminder.enabled && reminder.weekdays.isNotEmpty)
        .toList();
    if (activeReminders.isEmpty) {
      if (Platform.isAndroid) await cancelHifzReminders();
      return true;
    }
    if (!Platform.isAndroid) {
      throw UnsupportedError('Planner reminders are currently supported on Android.');
    }
    await _ensureInitialized();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final permissionGranted = await android?.requestNotificationsPermission();
    if (permissionGranted == false) {
      await cancelHifzReminders();
      return false;
    }
    await cancelHifzReminders();

    for (final reminder in activeReminders) {
      for (final weekday in reminder.weekdays) {
        await _scheduleReminder(
          id: _hifzWeeklyNotificationBase + reminder.category * 7 + weekday - 1,
          time: reminder.time,
          title: reminder.title,
          body: reminder.body,
          channelId: 'quran_planner_hifz',
          channelName: 'হিফজ রুটিন রিমাইন্ডার',
          weekday: weekday,
          requestPermission: false,
        );
      }
    }
    return true;
  }

  Future<bool> scheduleReaderSessionReminders(List<ReadingSession> sessions) async {
    final enabledSessions = sessions.where((session) => session.reminderEnabled).toList();
    if (enabledSessions.isEmpty) {
      if (Platform.isAndroid) await _cancelReaderSessionReminders();
      return true;
    }
    if (!Platform.isAndroid) {
      throw UnsupportedError('Planner reminders are currently supported on Android.');
    }
    if (sessions.length > _readerSessionNotificationCount) {
      throw ArgumentError('At most $_readerSessionNotificationCount reader sessions can be scheduled.');
    }
    await _ensureInitialized();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final permissionGranted = await android?.requestNotificationsPermission();
    if (permissionGranted == false) {
      await _cancelReaderSessionReminders();
      return false;
    }

    await _cancelReaderSessionReminders();
    for (var index = 0; index < sessions.length; index++) {
      final session = sessions[index];
      if (!session.reminderEnabled) continue;
      await _scheduleReminder(
        id: _readerSessionNotificationBase + index,
        time: session.time,
        title: session.title,
        body: 'আপনার নির্ধারিত কুরআন পাঠ সেশনের সময় হয়েছে।',
        channelId: 'quran_planner_reader_sessions',
        channelName: 'রিডিং সেশন রিমাইন্ডার',
        requestPermission: false,
      );
    }
    return true;
  }

  Future<void> _cancelReaderSessionReminders() async {
    await _ensureInitialized();
    for (var offset = 0; offset < _readerSessionNotificationCount; offset++) {
      await _notifications.cancel(_readerSessionNotificationBase + offset);
    }
  }

  Future<bool> _scheduleReminder({
    required int id,
    required String time,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    int? weekday,
    bool requestPermission = true,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Planner reminders are currently supported on Android.');
    }
    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('Invalid reminder time: $time');
    }

    await _ensureInitialized();
    if (requestPermission) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final permissionGranted = await android?.requestNotificationsPermission();
      if (permissionGranted == false) return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while ((weekday != null && scheduled.weekday != weekday) || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'দৈনিক তিলাওয়াত ও রিভিশন রিমাইন্ডার',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
    return true;
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _notifications.cancel(_notificationId);
  }

  Future<void> cancelHifzReminders() async {
    await _ensureInitialized();
    await _notifications.cancel(_sabaqNotificationId);
    await _notifications.cancel(_sabqiNotificationId);
    await _notifications.cancel(_manzilNotificationId);
    for (var offset = 0; offset < _hifzWeeklyNotificationCount; offset++) {
      await _notifications.cancel(_hifzWeeklyNotificationBase + offset);
    }
  }
}
