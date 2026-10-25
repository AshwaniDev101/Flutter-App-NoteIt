import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum ReminderRepeatMode { once, daily, customDays }

class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();

  factory ReminderManager() => _instance;

  ReminderManager._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _desktopTimers = {};
  bool _isInitialized = false;

  /// 1. Initialization for flutter_local_notifications 22.3.3
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback if local timezone identifier is not present in tz database
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const WindowsInitializationSettings windowsInit = WindowsInitializationSettings(
      appName: 'NoteIt',
      appUserModelId: 'com.example.noteit',
      guid: '6d01d0e1-0c30-4e5a-a38f-5867160714b1',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      windows: windowsInit,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        }
      },
    );

    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// 2. Permission Request
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      return granted ?? false;
    }
    return true; // Windows / Web
  }

  /// Unique notification integer ID derived from string note UUID
  int getNotificationId(String noteUuid) => noteUuid.hashCode.abs() % 2147483647;

  /// High-level method to schedule a reminder tied to a Note UUID
  Future<void> scheduleForNote({
    required String noteUuid,
    required String title,
    required String message,
    required DateTime date,
    required ReminderRepeatMode repeatMode,
    List<int>? selectedDays,
  }) async {
    final int baseId = getNotificationId(noteUuid);
    await schedule(
      baseId: baseId,
      title: title,
      message: message,
      date: date,
      repeatMode: repeatMode,
      selectedDays: selectedDays,
    );
  }

  /// High-level method to cancel a reminder for a Note UUID
  Future<void> cancelForNote(String noteUuid) async {
    final int baseId = getNotificationId(noteUuid);
    await cancelReminder(baseId);
  }

  /// 3. Scheduling notifications
  Future<void> schedule({
    required int baseId,
    required String title,
    required String message,
    required DateTime date,
    required ReminderRepeatMode repeatMode,
    List<int>? selectedDays,
  }) async {
    await _ensureInitialized();
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await cancelReminder(baseId);

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(date, tz.local);

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'note_reminders',
        'Note Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    Future<void> scheduleNotification({
      required int id,
      required tz.TZDateTime time,
      DateTimeComponents? matchComponents,
    }) async {
      // 1. System notification schedule
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: message,
          scheduledDate: time,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
          payload: 'note_$baseId',
        );
      } catch (e) {
        debugPrint('zonedSchedule exception: $e');
      }

      // 2. Desktop in-memory timer backup
      _scheduleDesktopTimer(id: id, title: title, message: message, scheduledDate: date);
    }

    switch (repeatMode) {
      case ReminderRepeatMode.once:
        await scheduleNotification(id: baseId, time: scheduledDate);
        break;

      case ReminderRepeatMode.daily:
        await scheduleNotification(
          id: baseId,
          time: scheduledDate,
          matchComponents: DateTimeComponents.time,
        );
        break;

      case ReminderRepeatMode.customDays:
        if (selectedDays == null || selectedDays.isEmpty) return;

        for (int day in selectedDays) {
          final tz.TZDateTime nextDayDate = _nextInstanceOfWeekday(scheduledDate, day);
          final int uniqueId = (baseId * 10) + day;

          await scheduleNotification(
            id: uniqueId,
            time: nextDayDate,
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;
    }
  }

  void _scheduleDesktopTimer({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledDate,
  }) {
    _desktopTimers[id]?.cancel();

    final duration = scheduledDate.difference(DateTime.now());
    if (duration.isNegative) return;

    _desktopTimers[id] = Timer(duration, () async {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminders',
          'Note Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: message,
        notificationDetails: details,
        payload: 'note_$id',
      );
    });
  }

  Future<void> cancelReminder(int baseId) async {
    await _ensureInitialized();

    // Cancel system schedule
    try {
      await _notificationsPlugin.cancel(id: baseId);
    } catch (_) {}

    // Cancel in-memory desktop timer
    _desktopTimers[baseId]?.cancel();
    _desktopTimers.remove(baseId);

    for (int i = 1; i <= 7; i++) {
      final subId = (baseId * 10) + i;
      try {
        await _notificationsPlugin.cancel(id: subId);
      } catch (_) {}
      _desktopTimers[subId]?.cancel();
      _desktopTimers.remove(subId);
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(tz.TZDateTime time, int weekday) {
    tz.TZDateTime scheduledDate = time;
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
