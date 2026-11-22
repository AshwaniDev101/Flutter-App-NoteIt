import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final reminderPreferencesProvider = Provider<ReminderPreferences>((ref) {
  return ReminderPreferences(ref.watch(sharedPreferencesProvider));
});

/// Reactive notifier for the reminder sound enabled state.
class ReminderSoundNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(reminderPreferencesProvider).reminderSoundEnabled;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(reminderPreferencesProvider).setReminderSoundEnabled(value);
  }
}

final reminderSoundProvider = NotifierProvider<ReminderSoundNotifier, bool>(() {
  return ReminderSoundNotifier();
});

class ReminderPreferences {
  final SharedPreferences _prefs;
  ReminderPreferences(this._prefs);

  static const String _keyCustomSoundPath = 'reminder_custom_sound_path';
  static const String _keyCustomSoundName = 'reminder_custom_sound_name';
  static const String _keyReminderSoundEnabled = 'reminder_sound_enabled';
  static const String _keyReminderVibrationEnabled = 'reminder_vibration_enabled';
  static const String _keyReminderDurationSeconds = 'reminder_duration_seconds';
  static const String _keyDefaultRepeatMode = 'reminder_default_repeat_mode';

  String? get customReminderSoundPath => _prefs.getString(_keyCustomSoundPath);

  String get customReminderSoundName => _prefs.getString(_keyCustomSoundName) ?? 'Default Ring (alarm_ring.mp3)';

  Future<bool> setCustomReminderSound(String? path, String? name) async {
    if (path == null) {
      await _prefs.remove(_keyCustomSoundPath);
      return await _prefs.remove(_keyCustomSoundName);
    }
    await _prefs.setString(_keyCustomSoundPath, path);
    return await _prefs.setString(_keyCustomSoundName, name ?? 'Custom Sound');
  }

  bool get reminderSoundEnabled => _prefs.getBool(_keyReminderSoundEnabled) ?? true;

  Future<bool> setReminderSoundEnabled(bool value) async {
    return await _prefs.setBool(_keyReminderSoundEnabled, value);
  }

  bool get reminderVibrationEnabled => _prefs.getBool(_keyReminderVibrationEnabled) ?? true;

  Future<bool> setReminderVibrationEnabled(bool value) async {
    return await _prefs.setBool(_keyReminderVibrationEnabled, value);
  }

  int get reminderDurationSeconds => _prefs.getInt(_keyReminderDurationSeconds) ?? 30;

  Future<bool> setReminderDurationSeconds(int seconds) async {
    return await _prefs.setInt(_keyReminderDurationSeconds, seconds);
  }

  String get defaultRepeatMode => _prefs.getString(_keyDefaultRepeatMode) ?? 'once';

  Future<bool> setDefaultRepeatMode(String mode) async {
    return await _prefs.setString(_keyDefaultRepeatMode, mode);
  }
}
