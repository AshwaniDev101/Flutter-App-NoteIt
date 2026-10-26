import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

import '../../core/router/router.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';

enum ReminderRepeatMode { once, daily, customDays }

class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();

  factory ReminderManager() => _instance;

  ReminderManager._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _desktopTimers = {};
  AudioPlayer? _audioPlayer;
  Timer? _desktopSoundTimer;
  final ValueNotifier<bool> isRinging = ValueNotifier<bool>(false);
  bool _isInitialized = false;

  /// Play custom alarm sound on Desktop (Windows / macOS / Linux)
  Future<void> _playDesktopAlarmSound() async {
    final prefs = SharedPreferenceManager.instance;
    if (!prefs.reminderSoundEnabled) return;
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) return;

    try {
      await stopAlarmSound();
      isRinging.value = true;
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);

      final customPath = prefs.customReminderSoundPath;
      if (customPath != null && customPath.isNotEmpty && File(customPath).existsSync()) {
        await _audioPlayer!.play(DeviceFileSource(customPath));
      } else {
        await _audioPlayer!.play(AssetSource('alarm_ring.mp3'));
      }

      final timeoutSecs = prefs.reminderDurationSeconds;
      _desktopSoundTimer = Timer(Duration(seconds: timeoutSecs), () {
        stopAlarmSound();
      });
    } catch (e) {
      debugPrint('Error playing desktop alarm sound: $e');
    }
  }

  /// Stop playing active desktop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      isRinging.value = false;
      _desktopSoundTimer?.cancel();
      _desktopSoundTimer = null;
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (_) {}
  }

  Future<void> _handleNotificationTap(String? payload) async {
    await stopAlarmSound();
    if (payload == null || payload.isEmpty) return;

    final String noteUuid = payload.startsWith('note_') ? payload.substring(5) : payload;
    if (noteUuid.isEmpty) return;

    try {
      final container = ProviderContainer();
      final noteWithFolder = await container.read(notesDaoProvider).getNoteById(noteUuid);
      container.dispose();

      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          try {
            await windowManager.setSize(const Size(780, 720));
            await windowManager.center();
            await windowManager.show();
            await windowManager.focus();
          } catch (_) {}
        }
        if (context.mounted) {
          GoRouter.of(context).push(AppRoutes.noteShowcase, extra: noteWithFolder);
        }
      }
    } catch (e) {
      debugPrint('Error launching NoteShowcasePage from notification: $e');
    }
  }

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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handleNotificationTap(response.payload);
      },
    );

    // Create high-importance Loud Alarm notification channel on Android 8.0+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'noteit_loud_alarms_v3',
      'Note-It Alarms',
      description: 'Loud alarm ringers and reminders for Note-It',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_ring'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await androidImplementation?.createNotificationChannel(channel);

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
      // Request exact alarm permissions for high-priority alarm timing
      try {
        await androidImplementation?.requestExactAlarmsPermission();
      } catch (_) {}

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
      noteUuid: noteUuid,
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
    required String noteUuid,
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

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'noteit_loud_alarms_v3',
        'Note-It Alarms',
        channelDescription: 'Loud alarm ringers and reminders for Note-It',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_ring'),
        additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: loops alarm sound continuously until dismissed
        enableVibration: true,
        fullScreenIntent: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        sound: 'alarm_ring.mp3',
        presentAlert: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      windows: const WindowsNotificationDetails(),
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
          payload: 'note_$noteUuid',
        );
      } catch (e) {
        debugPrint('exactAllowWhileIdle exception, falling back to inexact: $e');
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: message,
            scheduledDate: time,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchComponents,
            payload: 'note_$noteUuid',
          );
        } catch (err) {
          debugPrint('inexactAllowWhileIdle exception: $err');
        }
      }

      // 2. Desktop in-memory timer backup
      _scheduleDesktopTimer(
        id: id,
        noteUuid: noteUuid,
        title: title,
        message: message,
        scheduledDate: date,
      );
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
    required String noteUuid,
    required String title,
    required String message,
    required DateTime scheduledDate,
  }) {
    _desktopTimers[id]?.cancel();

    final duration = scheduledDate.difference(DateTime.now());
    if (duration.isNegative) return;

    _desktopTimers[id] = Timer(duration, () async {
      await _playDesktopAlarmSound();

      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'noteit_loud_alarms_v3',
          'Note-It Alarms',
          channelDescription: 'Loud alarm ringers and reminders for Note-It',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alarm_ring'),
          additionalFlags: Int32List.fromList([4]),
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          sound: 'alarm_ring.mp3',
          presentAlert: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        windows: const WindowsNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: message,
        notificationDetails: details,
        payload: 'note_$noteUuid',
      );
    });
  }

  Future<void> cancelReminder(int baseId) async {
    await _ensureInitialized();
    await stopAlarmSound();

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
