import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/util/platform_helper.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../reminder/reminder_manager.dart';

/// Manages desktop system tray icon, context menu, and minimize-to-tray window behavior.
class DesktopTrayHandler extends WindowListener with TrayListener {
  static final DesktopTrayHandler instance = DesktopTrayHandler._();
  DesktopTrayHandler._();

  bool _isInitialized = false;
  Future<void>? _initFuture;
  Timer? _resizeDebounce;

  VoidCallback? _ringingListener;
  VoidCallback? _soundListener;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInit();
    return _initFuture;
  }

  Future<void> _doInit() async {
    windowManager.addListener(this);
    trayManager.addListener(this);

    await windowManager.setPreventClose(true);

    try {
      // Windows Shell_NotifyIcon requires a valid .ico file for native HICON handle
      final iconPath = PlatformHelper.isWindows
          ? 'assets/icons/app_icon.ico'
          : 'assets/icons/note_icon.png';

      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('NoteIt');

      // Rebuild tray menu when alarm sound state or sound preference changes
      _ringingListener = () => updateTrayMenu();
      _soundListener = () => updateTrayMenu();

      ReminderManager().isRinging.addListener(_ringingListener!);
      SharedPreferenceManager.instance.reminderSoundListenable.addListener(_soundListener!);

      await updateTrayMenu();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Tray manager initialization error: $e');
    }
  }

  /// Cleans up listeners, debounce timers, and tray resources.
  void dispose() {
    _resizeDebounce?.cancel();
    _resizeDebounce = null;

    if (_ringingListener != null) {
      ReminderManager().isRinging.removeListener(_ringingListener!);
      _ringingListener = null;
    }
    if (_soundListener != null) {
      SharedPreferenceManager.instance.reminderSoundListenable.removeListener(_soundListener!);
      _soundListener = null;
    }

    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _isInitialized = false;
    _initFuture = null;
  }

  /// Destroys the system tray icon cleanly before destroying the main app window
  /// to avoid leaving orphaned/ghost tray icons on Windows.
  Future<void> destroyTrayAndExit() async {
    try {
      await trayManager.destroy();
    } catch (e) {
      debugPrint('Error destroying tray manager: $e');
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  /// Dynamically rebuilds the tray context menu based on alarm ringing state and sound preference.
  Future<void> updateTrayMenu() async {
    final isRinging = ReminderManager().isRinging.value;
    final isSoundEnabled = SharedPreferenceManager.instance.reminderSoundEnabled;

    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_app',
          label: 'Open NoteIt',
        ),
        MenuItem(
          key: 'snooze_reminder',
          label: 'Snooze Reminder',
          disabled: !isRinging,
        ),
        MenuItem(
          key: 'toggle_alarm_sound',
          label: isSoundEnabled ? 'Alarm OFF' : 'Alarm ON',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit NoteIt',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowFocus() {
    // Intentionally empty: prevents active window focus from silently dismissing background reminder audio cues.
  }

  @override
  void onWindowResized() {
    // Debounce window size persistence to prevent unthrottled disk I/O while dragging window borders.
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (_isInitialized) {
        final size = await windowManager.getSize();
        SharedPreferenceManager.instance.setWindowWidth(size.width);
        SharedPreferenceManager.instance.setWindowHeight(size.height);
      }
    });
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    } else {
      await destroyTrayAndExit();
    }
  }

  @override
  void onTrayIconMouseDown() {
    if (PlatformHelper.isMacOS) {
      trayManager.popUpContextMenu();
    } else {
      windowManager.show();
      windowManager.focus();
      ReminderManager().stopAlarmSound();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    // Force the OS to give this app foreground focus (even if hidden)
    if (PlatformHelper.isWindows) {
      await windowManager.focus();

      //  Now show the menu
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_app') {
      windowManager.show();
      windowManager.focus();
      ReminderManager().stopAlarmSound();
    } else if (menuItem.key == 'snooze_reminder') {
      ReminderManager().stopAlarmSound();
    } else if (menuItem.key == 'toggle_alarm_sound') {
      final prefs = SharedPreferenceManager.instance;
      final currentSoundEnabled = prefs.reminderSoundEnabled;
      await prefs.setReminderSoundEnabled(!currentSoundEnabled);
      await updateTrayMenu();
    } else if (menuItem.key == 'exit_app') {
      await destroyTrayAndExit();
    }
  }
}
