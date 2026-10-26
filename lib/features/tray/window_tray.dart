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

  Future<void> init() async {
    if (_isInitialized) return;

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

      // Rebuild tray menu when alarm sound state or silent mode changes
      ReminderManager().isRinging.addListener(() {
        updateTrayMenu();
      });
      SharedPreferenceManager.instance.reminderSoundListenable.addListener(() {
        updateTrayMenu();
      });

      await updateTrayMenu();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Tray manager initialization error: $e');
    }
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
    ReminderManager().stopAlarmSound();
  }

  @override
  void onWindowResized() async {
    final size = await windowManager.getSize();
    SharedPreferenceManager.instance.setWindowWidth(size.width);
    SharedPreferenceManager.instance.setWindowHeight(size.height);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
    ReminderManager().stopAlarmSound();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await updateTrayMenu();
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_app') {
      windowManager.show();
      windowManager.focus();
      ReminderManager().stopAlarmSound();
    } else if (menuItem.key == 'snooze_reminder') {
      ReminderManager().stopAlarmSound();
    } else if (menuItem.key == 'toggle_alarm_sound' || menuItem.key == 'toggle_silent_mode') {
      final prefs = SharedPreferenceManager.instance;
      final currentSoundEnabled = prefs.reminderSoundEnabled;
      await prefs.setReminderSoundEnabled(!currentSoundEnabled);
      await updateTrayMenu();
    } else if (menuItem.key == 'exit_app') {
      windowManager.setPreventClose(false);
      windowManager.destroy();
    }
  }
}
