import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

import '../../core/router/router.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../home/core/providers.dart';
import '../home/view/desktop/content_panel/core/navigator.dart';

enum ReminderRepeatMode { once, daily, customDays }

class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();

  factory ReminderManager() => _instance;

  ReminderManager._internal();

  ProviderContainer? _container;
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
      final container = _container;
      if (container == null) return;

      await _onReminderTriggered(noteUuid);

      final noteWithFolder = await container.read(notesDaoProvider).getNoteById(noteUuid);

      // Set active note in Riverpod state
      container.read(activeNoteProvider.notifier).setNote(noteWithFolder);

      final context = rootNavigatorKey.currentContext;

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        try {
          if (await windowManager.isMinimized()) {
            await windowManager.restore();
          }
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          debugPrint('Error bringing desktop window to foreground: $e');
        }

        // Set right panel view to note editor
        container.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.noteEditor);

        if (context != null && context.mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        if (context != null && context.mounted) {
          GoRouter.of(context).push(AppRoutes.edit, extra: noteWithFolder);
        }
      }
    } catch (e) {
      debugPrint('Error launching note from notification: $e');
    }
  }

  /// 1. Initialization for flutter_local_notifications 22.3.3
  Future<void> init([ProviderContainer? container]) async {
    if (container != null) {
      _container = container;
    }

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
    await rearmPendingReminders();
  }

  /// Re-reads all upcoming pending reminders from SQLite and re-arms in-memory desktop sound timers.
  Future<void> rearmPendingReminders() async {
    final container = _container;
    if (container == null) return;

    try {
      final pendingNotes = await container.read(notesDaoProvider).getNotesWithPendingReminders();
      final now = DateTime.now();

      for (final noteWithFolder in pendingNotes) {
        final note = noteWithFolder.note;
        final reminderAt = note.reminderAt;

        if (reminderAt != null && reminderAt.isAfter(now)) {
          final int baseId = getNotificationId(note.uuid);
          _scheduleDesktopTimer(
            id: baseId,
            noteUuid: note.uuid,
            title: 'Note-It Reminder',
            message: note.title.isNotEmpty ? note.title : 'Reminder for your note',
            scheduledDate: reminderAt,
          );
        }
      }
    } catch (e) {
      debugPrint('Error re-arming pending reminders: $e');
    }
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

  static String formatReminderLabel(DateTime reminderAt, String? repeatMode, String? customDays) {
    final timeStr = DateFormat('h:mm a').format(reminderAt);

    if (repeatMode == 'daily') {
      return 'Daily, $timeStr';
    } else if (repeatMode == 'customDays' || repeatMode == 'custom') {
      return 'Weekly, $timeStr';
    } else {
      return DateFormat('MMM d, h:mm a').format(reminderAt);
    }
  }

  static DateTime _nextDailyOccurrence(DateTime targetTime) {
    final now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );
    if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime _nextWeekdayOccurrence(DateTime targetTime, int targetWeekday) {
    final now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );
    while (candidate.isBefore(now) || candidate.isAtSameMomentAs(now) || candidate.weekday != targetWeekday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// High-level method to schedule a reminder tied to a Note UUID
  Future<DateTime?> scheduleForNote({
    required String noteUuid,
    required String title,
    required String message,
    required DateTime date,
    required ReminderRepeatMode repeatMode,
    List<int>? selectedDays,
  }) async {
    final int baseId = getNotificationId(noteUuid);
    return await schedule(
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
  Future<DateTime?> schedule({
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
    if (!hasPermission) return null;

    await cancelReminder(baseId);

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
      required DateTime targetDate,
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
        scheduledDate: targetDate,
      );
    }

    switch (repeatMode) {
      case ReminderRepeatMode.once:
        final scheduledDate = tz.TZDateTime.from(date, tz.local);
        await scheduleNotification(id: baseId, time: scheduledDate, targetDate: date);
        return date;

      case ReminderRepeatMode.daily:
        final nextDate = _nextDailyOccurrence(date);
        final nextTz = tz.TZDateTime.from(nextDate, tz.local);
        await scheduleNotification(
          id: baseId,
          time: nextTz,
          targetDate: nextDate,
          matchComponents: DateTimeComponents.time,
        );
        return nextDate;

      case ReminderRepeatMode.customDays:
        if (selectedDays == null || selectedDays.isEmpty) return null;

        DateTime? earliestNextDate;
        for (int day in selectedDays) {
          final nextDate = _nextWeekdayOccurrence(date, day);
          final nextTz = tz.TZDateTime.from(nextDate, tz.local);
          final int uniqueId = (baseId * 10) + day;

          await scheduleNotification(
            id: uniqueId,
            time: nextTz,
            targetDate: nextDate,
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );

          if (earliestNextDate == null || nextDate.isBefore(earliestNextDate)) {
            earliestNextDate = nextDate;
          }
        }
        return earliestNextDate;
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
      _desktopTimers.remove(id);
      await _playDesktopAlarmSound();
      await _onReminderTriggered(noteUuid);

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

  /// Handles auto-clearing one-time reminders or advancing repeating reminders when triggered.
  Future<void> _onReminderTriggered(String noteUuid) async {
    final container = _container;
    if (container == null) return;

    try {
      final noteWithFolder = await container.read(notesDaoProvider).getNoteById(noteUuid);
      final note = noteWithFolder.note;
      final repeatMode = note.reminderRepeatMode;

      if (repeatMode == 'daily') {
        final currentReminder = note.reminderAt ?? DateTime.now();
        final nextDate = currentReminder.add(const Duration(days: 1));
        await container.read(notesDaoProvider).updateNoteReminder(
              noteUuid,
              nextDate,
              repeatMode: 'daily',
            );
      } else if (repeatMode == 'customDays' && note.reminderCustomDays != null) {
        final currentReminder = note.reminderAt ?? DateTime.now();
        final days = note.reminderCustomDays!
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>()
            .toList();
        if (days.isNotEmpty) {
          final tzDate = tz.TZDateTime.from(currentReminder, tz.local);
          final nextTz = _nextInstanceOfCustomDays(tzDate, days);
          await container.read(notesDaoProvider).updateNoteReminder(
                noteUuid,
                nextTz.toLocal(),
                repeatMode: 'customDays',
                customDays: note.reminderCustomDays,
              );
        } else {
          await container.read(notesDaoProvider).updateNoteReminder(noteUuid, null);
        }
      } else {
        // One-time reminder: auto-clear in SQLite database
        await container.read(notesDaoProvider).updateNoteReminder(noteUuid, null);
      }
    } catch (e) {
      debugPrint('Error processing triggered reminder for note ($noteUuid): $e');
    }
  }

  tz.TZDateTime _nextInstanceOfCustomDays(tz.TZDateTime from, List<int> days) {
    tz.TZDateTime candidate = from.add(const Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      if (days.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
