import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../shared/menus/view_menu_button.dart';
import '../drift/notes/notes_dao.dart';
import '../sync/sync_engine.dart';

enum SyncRole { undefine, host, client }

// The Global Settings Provider
final sharedPreferenceProvider = Provider<SharedPreferenceManager>((ref) {
  return SharedPreferenceManager.instance;
});

class SharedPreferenceManager {
  SharedPreferenceManager._internal();

  static final SharedPreferenceManager instance = SharedPreferenceManager._internal();

  static late SharedPreferences _prefs;
  late final ValueNotifier<bool> reminderSoundListenable;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    instance.reminderSoundListenable = ValueNotifier<bool>(instance.reminderSoundEnabled);
  }

  static const String _keyViewType = 'view_type';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyMasterPassword = 'master_password';
  static const String _keyThemeType = 'theme_type';
  static const String _keySyncEngine = 'sync_engine';
  static const String _keyHostUuid = 'host_uuid'; // Need when this device ever becomes a host
  static const String _keySyncRole = 'sync_role'; //  0 = undefine, 1 = Host, 2 = Client
  static const String _keyShowDynamicKeyHints = 'show_dynamic_key_hints';
  static const String _keyAppendShortcutToTooltips = 'append_shortcut_to_tooltips';

  // Layout Keys
  static const String _keyWindowWidth = 'window_width';
  static const String _keyWindowHeight = 'window_height';
  static const String _keyListPanelWidth = 'list_panel_width';

  // Key for keeping notes unlocked during session
  static const String _keyKeepUnlockedSession = 'keep_unlocked_session';

  // --- Sync Engine Mode ---
  // Defaults to offline if the user has never chosen one
  SyncEngine get currentEngine {
    final engineName = _prefs.getString(_keySyncEngine) ?? SyncEngine.offline.name;
    return SyncEngine.values.firstWhere((e) => e.name == engineName, orElse: () => SyncEngine.offline);
  }

  Future<bool> setCurrentEngine(SyncEngine engine) async {
    return await _prefs.setString(_keySyncEngine, engine.name);
  }

  // --- Legacy View Type ---
  int get viewType => _prefs.getInt(_keyViewType) ?? 0;

  Future<bool> setViewType(int value) async {
    return await _prefs.setInt(_keyViewType, value);
  }

  // --- Generic Page View Types ---
  NoteViewType getPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) {
    final savedName = _prefs.getString('page_view_$pageId');
    if (savedName == null) {
      return getDefaultPageViewType(pageId, fallback: fallback);
    }
    return NoteViewType.values.firstWhere(
      (e) => e.name == savedName,
      orElse: () => getDefaultPageViewType(pageId, fallback: fallback),
    );
  }

  Future<bool> setPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('page_view_$pageId', view.name);
  }

  NoteViewType getDefaultPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) {
    final savedName = _prefs.getString('default_page_view_$pageId');
    if (savedName == null) return fallback;
    return NoteViewType.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  Future<bool> setDefaultPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('default_page_view_$pageId', view.name);
  }

  // --- Generic Page Sort Options ---
  NoteSortPreference getPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) {
    final savedName = _prefs.getString('page_sort_$pageId');
    if (savedName == null) {
      return getDefaultPageSortOption(pageId, fallback: fallback);
    }
    return NoteSortPreference.values.firstWhere(
      (e) => e.name == savedName,
      orElse: () => getDefaultPageSortOption(pageId, fallback: fallback),
    );
  }

  Future<bool> setPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('page_sort_$pageId', sort.name);
  }

  NoteSortPreference getDefaultPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) {
    final savedName = _prefs.getString('default_page_sort_$pageId');
    if (savedName == null) return fallback;
    return NoteSortPreference.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  Future<bool> setDefaultPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('default_page_sort_$pageId', sort.name);
  }

  Future<void> resetPageViewsAndSortsToDefaults() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('page_view_') || key.startsWith('page_sort_')) {
        await _prefs.remove(key);
      }
    }
  }

  // --- Layout Dimensions ---
  double get listPanelWidth => _prefs.getDouble(_keyListPanelWidth) ?? getDefaultListPanelWidth();

  Future<bool> setListPanelWidth(double width) async {
    return await _prefs.setDouble(_keyListPanelWidth, width);
  }

  double getDefaultListPanelWidth() {
    return _prefs.getDouble('default_list_panel_width') ?? 340.0;
  }

  Future<bool> setDefaultListPanelWidth(double width) async {
    return await _prefs.setDouble('default_list_panel_width', width);
  }

  double get windowWidth => _prefs.getDouble(_keyWindowWidth) ?? getDefaultWindowWidth();

  Future<bool> setWindowWidth(double width) async {
    return await _prefs.setDouble(_keyWindowWidth, width);
  }

  double getDefaultWindowWidth() {
    return _prefs.getDouble('default_window_width') ?? 1400.0;
  }

  Future<bool> setDefaultWindowWidth(double width) async {
    return await _prefs.setDouble('default_window_width', width);
  }

  double get windowHeight => _prefs.getDouble(_keyWindowHeight) ?? getDefaultWindowHeight();

  Future<bool> setWindowHeight(double height) async {
    return await _prefs.setDouble(_keyWindowHeight, height);
  }

  Future<bool> setWindowSize(double width, double height) async {
    final results = await Future.wait([
      _prefs.setDouble(_keyWindowWidth, width),
      _prefs.setDouble(_keyWindowHeight, height),
    ]);
    return results.every((r) => r);
  }

  double getDefaultWindowHeight() {
    return _prefs.getDouble('default_window_height') ?? 900.0;
  }

  Future<bool> setDefaultWindowHeight(double height) async {
    return await _prefs.setDouble('default_window_height', height);
  }

  // --- Sync Time ---
  int get lastSyncTime => _prefs.getInt(_keyLastSyncTime) ?? 0;

  Future<bool> setLastSyncTime(int timestamp) async {
    return await _prefs.setInt(_keyLastSyncTime, timestamp);
  }

  Future<bool> clearSyncTime() async {
    return await _prefs.remove(_keyLastSyncTime);
  }

  // --- Master Password ---
  String? get masterPassword => _prefs.getString(_keyMasterPassword);

  Future<bool> setMasterPassword(String password) async {
    return await _prefs.setString(_keyMasterPassword, password);
  }

  bool get hasMasterPassword => _prefs.containsKey(_keyMasterPassword);

  Future<bool> removeMasterPassword() async {
    return await _prefs.remove(_keyMasterPassword);
  }

  // --- Session Lock Preference ---
  // Defaults to false (strict mode)
  bool get keepUnlockedDuringSession => _prefs.getBool(_keyKeepUnlockedSession) ?? false;

  Future<bool> setKeepUnlockedDuringSession(bool value) async {
    return await _prefs.setBool(_keyKeepUnlockedSession, value);
  }

  // --- Reminder Settings ---
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
    reminderSoundListenable.value = value;
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

  // --- Theme  ---
  String get themeType => _prefs.getString(_keyThemeType) ?? 'dark';

  Future<bool> setThemeType(String value) async {
    return await _prefs.setString(_keyThemeType, value);
  }

  // --- Global ---
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  // --- UUID ---
  // Retrieves the saved UUID, or generates a new one on the very first run.
  String get hostUuid {
    String? uuid = _prefs.getString(_keyHostUuid);

    if (uuid == null) {
      uuid = const Uuid().v4();
      // Fire-and-forget save; no need to await it here
      _prefs.setString(_keyHostUuid, uuid);
    }

    return uuid;
  }

  SyncRole get syncRole {
    final role = _prefs.getInt(_keySyncRole) ?? 0;

    switch (role) {
      case 0:
        return SyncRole.undefine;
      case 1:
        return SyncRole.host;
      case 2:
        return SyncRole.client;
    }

    return SyncRole.undefine;
  }

  void setSyncRole(SyncRole role) {
    switch (role) {
      case SyncRole.undefine:
        _prefs.setInt(_keySyncRole, 0);
        break;
      case SyncRole.host:
        _prefs.setInt(_keySyncRole, 1);
        break;
      case SyncRole.client:
        _prefs.setInt(_keySyncRole, 2);
        break;
    }
  }

  // Defaults to true so users see the hints by default
  bool get showDynamicKeyHints => _prefs.getBool(_keyShowDynamicKeyHints) ?? true;

  Future<bool> setShowDynamicKeyHints(bool value) async {
    return await _prefs.setBool(_keyShowDynamicKeyHints, value);
  }

  // Defaults to true so users see (Ctrl+N) in tooltips by default
  bool get appendShortcutToTooltips => _prefs.getBool(_keyAppendShortcutToTooltips) ?? true;

  Future<bool> setAppendShortcutToTooltips(bool value) async {
    return await _prefs.setBool(_keyAppendShortcutToTooltips, value);
  }
}
