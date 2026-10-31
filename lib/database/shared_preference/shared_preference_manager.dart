import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/menus/view_menu_button.dart';
import '../drift/notes/notes_dao.dart';
import '../sync/sync_engine.dart';

/// Enum representing the synchronization role of the device in a P2P / sync setup.
enum SyncRole {
  /// Role is not defined yet (0).
  undefine,

  /// Device operates as a Host server node (1).
  host,

  /// Device operates as a Client connecting node (2).
  client,
}

/// Global Riverpod Provider for accessing [SharedPreferenceManager].
final sharedPreferenceProvider = Provider<SharedPreferenceManager>((ref) {
  return SharedPreferenceManager.instance;
});

/// Centralized manager for accessing and modifying application settings stored in [SharedPreferences].
class SharedPreferenceManager {
  SharedPreferenceManager._internal();

  static final SharedPreferenceManager instance = SharedPreferenceManager._internal();

  static late SharedPreferences _prefs;

  /// Reactive notifier for changes to the reminder sound enabled state.
  late final ValueNotifier<bool> reminderSoundListenable;

  /// Initializes [SharedPreferences] and reactive listenable objects.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    instance.reminderSoundListenable = ValueNotifier<bool>(instance.reminderSoundEnabled);
  }

  // =========================================================================
  // SHARED PREFERENCE KEYS
  // =========================================================================

  // --- Sync & P2P Keys ---

  /// Key for storing the active synchronization engine mode.
  /// Enum: [SyncEngine] (`cloud`, `local`, `offline`).
  static const String _keySyncEngine = 'sync_engine';

  /// Key for storing the device's synchronization role.
  /// Enum: [SyncRole] (`0` = `undefine`, `1` = `host`, `2` = `client`).
  static const String _keySyncRole = 'sync_role';

  /// Key for storing the unique Host UUID for P2P connection.
  /// Value: String (UUID v4 generated when device becomes a host).
  static const String _keyHostUuid = 'host_uuid';

  /// Key for storing the timestamp of the last successful sync.
  /// Value: int (Epoch timestamp in milliseconds).
  static const String _keyLastSyncTime = 'last_sync_time';

  // --- Theme & Interface Keys ---

  /// Key for storing the overall theme mode.
  /// Value: String (e.g., `'dark'`, `'light'`).
  static const String _keyThemeType = 'theme_type';

  /// Key for toggling dynamic key hint overlays across the UI.
  /// Boolean:
  /// - `true`: Show dynamic key hints.
  /// - `false`: Hide dynamic key hints.
  static const String _keyShowDynamicKeyHints = 'show_dynamic_key_hints';

  /// Key for appending keyboard shortcuts to UI tooltips.
  /// Boolean:
  /// - `true`: Append keyboard shortcuts (e.g., "(Ctrl+N)") to tooltips.
  /// - `false`: Display standard tooltips without shortcut hints.
  static const String _keyAppendShortcutToTooltips = 'append_shortcut_to_tooltips';

  // --- Security & Session Keys ---

  /// Key for storing the master password used to lock notes.
  /// Value: String (Hashed password or null if unset).
  static const String _keyMasterPassword = 'master_password';

  /// Key for keeping notes unlocked throughout the app session.
  /// Boolean:
  /// - `true`: Keep notes unlocked for the entire active session once unlocked.
  /// - `false`: Require re-locking strictly based on lock triggers or timeout.
  static const String _keyKeepUnlockedSession = 'keep_unlocked_session';

  // --- Note View & Sort Keys ---

  /// Key for legacy main view type.
  /// Value: int.
  static const String _keyViewType = 'view_type';

  /// Prefix key for page-specific view layout (`page_view_<pageId>`).
  /// Enum: [NoteViewType] (`list`, `detailedList`, `grid`, `largeGrid`).
  static const String _keyPageViewPrefix = 'page_view_';

  /// Prefix key for default page-specific view layout (`default_page_view_<pageId>`).
  /// Enum: [NoteViewType] (`list`, `detailedList`, `grid`, `largeGrid`).
  static const String _keyDefaultPageViewPrefix = 'default_page_view_';

  /// Prefix key for page-specific sorting option (`page_sort_<pageId>`).
  /// Enum: [NoteSortPreference] (`name`, `createdAt`, `updatedAt`, `folder`, `reminderAt`).
  static const String _keyPageSortPrefix = 'page_sort_';

  /// Prefix key for default page-specific sorting option (`default_page_sort_<pageId>`).
  /// Enum: [NoteSortPreference] (`name`, `createdAt`, `updatedAt`, `folder`, `reminderAt`).
  static const String _keyDefaultPageSortPrefix = 'default_page_sort_';

  // --- Layout & Window Dimension Keys ---

  /// Key for current window width.
  /// Value: double.
  static const String _keyWindowWidth = 'window_width';

  /// Key for default window width fallback.
  /// Value: double.
  static const String _keyDefaultWindowWidth = 'default_window_width';

  /// Key for current window height.
  /// Value: double.
  static const String _keyWindowHeight = 'window_height';

  /// Key for default window height fallback.
  /// Value: double.
  static const String _keyDefaultWindowHeight = 'default_window_height';

  /// Key for side list panel width.
  /// Value: double.
  static const String _keyListPanelWidth = 'list_panel_width';

  /// Key for default list panel width fallback.
  /// Value: double.
  static const String _keyDefaultListPanelWidth = 'default_list_panel_width';

  // --- Note Editor Preference Keys ---

  /// Key for initial focus target when opening the note editor.
  /// Boolean:
  /// - `true`: Place cursor in the note content body field on open.
  /// - `false`: Place cursor in the note title field on open.
  static const String _keyPutCursorOnContent = 'editor_put_cursor_on_content';

  /// Key for editor title font size.
  /// Value: double.
  static const String _keyTitleFontSize = 'editor_title_font_size';

  /// Key for editor body content font size.
  /// Value: double.
  static const String _keyContentFontSize = 'editor_content_font_size';

  /// Key for editor line spacing multiplier.
  /// Value: double.
  static const String _keyLineSpacing = 'editor_line_spacing';

  // --- Reminder & Notification Keys ---

  /// Key for custom reminder sound file path.
  /// Value: String? (Path to sound file or null for default system alarm).
  static const String _keyCustomSoundPath = 'reminder_custom_sound_path';

  /// Key for custom reminder sound display name.
  /// Value: String.
  static const String _keyCustomSoundName = 'reminder_custom_sound_name';

  /// Key for enabling audio playback for reminders.
  /// Boolean:
  /// - `true`: Play audio sound when reminder triggers.
  /// - `false`: Mute audio playback when reminder triggers.
  static const String _keyReminderSoundEnabled = 'reminder_sound_enabled';

  /// Key for enabling device vibration for reminders.
  /// Boolean:
  /// - `true`: Vibrate device when reminder triggers.
  /// - `false`: Disable vibration when reminder triggers.
  static const String _keyReminderVibrationEnabled = 'reminder_vibration_enabled';

  /// Key for reminder alarm playback duration in seconds.
  /// Value: int.
  static const String _keyReminderDurationSeconds = 'reminder_duration_seconds';

  /// Key for default repeat rule for new reminders.
  /// Value: String (e.g., `'once'`, `'daily'`, `'weekly'`, `'monthly'`, `'yearly'`).
  static const String _keyDefaultRepeatMode = 'reminder_default_repeat_mode';

  // --- Date & Time Formatting Keys ---

  /// Key for using system default date/time formatting.
  /// Boolean:
  /// - `true`: Use system default locale date/time format.
  /// - `false`: Use custom user date/time format preferences.
  static const String _keyTimeUseSystemFormat = 'time_use_system_format';

  /// Key for 24-hour time display.
  /// Boolean:
  /// - `true`: Display time in 24-hour format (e.g., 14:30).
  /// - `false`: Display time in 12-hour format with AM/PM (e.g., 2:30 PM).
  static const String _keyTimeIs24Hour = 'time_is_24_hour';

  /// Key for day format representation.
  /// Value: String (e.g., `'d'`, `'dd'`).
  static const String _keyTimeDayFormat = 'time_day_format';

  /// Key for month format representation.
  /// Value: String (e.g., `'M'`, `'MM'`, `'MMM'`, `'MMMM'`).
  static const String _keyTimeMonthFormat = 'time_month_format';

  /// Key for year format representation.
  /// Value: String (e.g., `'yy'`, `'yyyy'`).
  static const String _keyTimeYearFormat = 'time_year_format';

  /// Key for separator character in formatted dates.
  /// Value: String (e.g., `'-'`, `'/'`, `'.'`).
  static const String _keyTimeSeparator = 'time_separator';

  /// Key for ordering sequence of date and time components.
  /// Value: `List<String>` (e.g., `['day', 'month', 'year', 'time']`).
  static const String _keyTimeOrder = 'time_order';

  // =========================================================================
  // 1. SYNC & P2P METHODS
  // =========================================================================

  /// Retrieves the active [SyncEngine], defaulting to [SyncEngine.offline].
  SyncEngine get currentEngine {
    final engineName = _prefs.getString(_keySyncEngine) ?? SyncEngine.offline.name;
    return SyncEngine.values.firstWhere((e) => e.name == engineName, orElse: () => SyncEngine.offline);
  }

  /// Sets the active [SyncEngine].
  Future<bool> setCurrentEngine(SyncEngine engine) async {
    return await _prefs.setString(_keySyncEngine, engine.name);
  }

  /// Retrieves the persistent Host UUID, generating a new UUID v4 on first access.
  String get hostUuid {
    String? uuid = _prefs.getString(_keyHostUuid);
    if (uuid == null) {
      uuid = const Uuid().v4();
      _prefs.setString(_keyHostUuid, uuid);
    }
    return uuid;
  }

  /// Retrieves the device's [SyncRole] in P2P mode.
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

  /// Sets the device's [SyncRole] in P2P mode.
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

  /// Timestamp of the last successful sync operation (in milliseconds).
  int get lastSyncTime => _prefs.getInt(_keyLastSyncTime) ?? 0;

  /// Saves the last sync timestamp.
  Future<bool> setLastSyncTime(int timestamp) async {
    return await _prefs.setInt(_keyLastSyncTime, timestamp);
  }

  /// Clears the saved sync timestamp.
  Future<bool> clearSyncTime() async {
    return await _prefs.remove(_keyLastSyncTime);
  }

  // =========================================================================
  // 2. THEME & INTERFACE METHODS
  // =========================================================================

  /// Active theme type (e.g., `'dark'`, `'light'`).
  String get themeType => _prefs.getString(_keyThemeType) ?? 'dark';

  /// Updates the theme type preference.
  Future<bool> setThemeType(String value) async {
    return await _prefs.setString(_keyThemeType, value);
  }

  /// Whether dynamic key hints are shown in the UI (defaults to `true`).
  bool get showDynamicKeyHints => _prefs.getBool(_keyShowDynamicKeyHints) ?? true;

  /// Toggles dynamic key hint visibility.
  Future<bool> setShowDynamicKeyHints(bool value) async {
    return await _prefs.setBool(_keyShowDynamicKeyHints, value);
  }

  /// Whether keyboard shortcut hints are appended to tooltips (defaults to `true`).
  bool get appendShortcutToTooltips => _prefs.getBool(_keyAppendShortcutToTooltips) ?? true;

  /// Toggles tooltip shortcut visibility.
  Future<bool> setAppendShortcutToTooltips(bool value) async {
    return await _prefs.setBool(_keyAppendShortcutToTooltips, value);
  }

  // =========================================================================
  // 3. SECURITY & SESSION METHODS
  // =========================================================================

  /// Master password used for note locking/encryption.
  String? get masterPassword => _prefs.getString(_keyMasterPassword);

  /// Saves a new master password.
  Future<bool> setMasterPassword(String password) async {
    return await _prefs.setString(_keyMasterPassword, password);
  }

  /// Checks if a master password has been configured.
  bool get hasMasterPassword => _prefs.containsKey(_keyMasterPassword);

  /// Removes the stored master password.
  Future<bool> removeMasterPassword() async {
    return await _prefs.remove(_keyMasterPassword);
  }

  /// Whether notes remain unlocked for the duration of the current app session once unlocked.
  bool get keepUnlockedDuringSession => _prefs.getBool(_keyKeepUnlockedSession) ?? false;

  /// Updates the session lock preference.
  Future<bool> setKeepUnlockedDuringSession(bool value) async {
    return await _prefs.setBool(_keyKeepUnlockedSession, value);
  }

  // =========================================================================
  // 4. NOTE VIEW & SORT METHODS
  // =========================================================================

  /// Legacy view type integer.
  int get viewType => _prefs.getInt(_keyViewType) ?? 0;

  /// Sets the legacy view type integer.
  Future<bool> setViewType(int value) async {
    return await _prefs.setInt(_keyViewType, value);
  }

  /// Gets the [NoteViewType] saved for a specific page, falling back to page default or provided fallback.
  NoteViewType getPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) {
    final savedName = _prefs.getString('$_keyPageViewPrefix$pageId');
    if (savedName == null) {
      return getDefaultPageViewType(pageId, fallback: fallback);
    }
    return NoteViewType.values.firstWhere(
      (e) => e.name == savedName,
      orElse: () => getDefaultPageViewType(pageId, fallback: fallback),
    );
  }

  /// Saves the [NoteViewType] for a specific page.
  Future<bool> setPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('$_keyPageViewPrefix$pageId', view.name);
  }

  /// Gets the default [NoteViewType] configured for a specific page.
  NoteViewType getDefaultPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) {
    final savedName = _prefs.getString('$_keyDefaultPageViewPrefix$pageId');
    if (savedName == null) return fallback;
    return NoteViewType.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  /// Sets the default [NoteViewType] for a specific page.
  Future<bool> setDefaultPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('$_keyDefaultPageViewPrefix$pageId', view.name);
  }

  /// Gets the [NoteSortPreference] saved for a specific page.
  NoteSortPreference getPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) {
    final savedName = _prefs.getString('$_keyPageSortPrefix$pageId');
    if (savedName == null) {
      return getDefaultPageSortOption(pageId, fallback: fallback);
    }
    return NoteSortPreference.values.firstWhere(
      (e) => e.name == savedName,
      orElse: () => getDefaultPageSortOption(pageId, fallback: fallback),
    );
  }

  /// Saves the [NoteSortPreference] for a specific page.
  Future<bool> setPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('$_keyPageSortPrefix$pageId', sort.name);
  }

  /// Gets the default [NoteSortPreference] configured for a specific page.
  NoteSortPreference getDefaultPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) {
    final savedName = _prefs.getString('$_keyDefaultPageSortPrefix$pageId');
    if (savedName == null) return fallback;
    return NoteSortPreference.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  /// Sets the default [NoteSortPreference] for a specific page.
  Future<bool> setDefaultPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('$_keyDefaultPageSortPrefix$pageId', sort.name);
  }

  /// Resets all custom page-level view layout and sort preferences to system defaults.
  Future<void> resetPageViewsAndSortsToDefaults() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPageViewPrefix) || key.startsWith(_keyPageSortPrefix)) {
        await _prefs.remove(key);
      }
    }
  }

  // =========================================================================
  // 5. LAYOUT & WINDOW DIMENSION METHODS
  // =========================================================================

  /// Width of the list panel in split/multi-pane view.
  double get listPanelWidth => _prefs.getDouble(_keyListPanelWidth) ?? getDefaultListPanelWidth();

  /// Saves the list panel width.
  Future<bool> setListPanelWidth(double width) async {
    return await _prefs.setDouble(_keyListPanelWidth, width);
  }

  /// Default fallback list panel width (defaults to `340.0`).
  double getDefaultListPanelWidth() {
    return _prefs.getDouble(_keyDefaultListPanelWidth) ?? 340.0;
  }

  /// Saves the default list panel width preference.
  Future<bool> setDefaultListPanelWidth(double width) async {
    return await _prefs.setDouble(_keyDefaultListPanelWidth, width);
  }

  /// Application window width.
  double get windowWidth => _prefs.getDouble(_keyWindowWidth) ?? getDefaultWindowWidth();

  /// Saves the window width.
  Future<bool> setWindowWidth(double width) async {
    return await _prefs.setDouble(_keyWindowWidth, width);
  }

  /// Default fallback window width (defaults to `1400.0`).
  double getDefaultWindowWidth() {
    return _prefs.getDouble(_keyDefaultWindowWidth) ?? 1400.0;
  }

  /// Saves default window width preference.
  Future<bool> setDefaultWindowWidth(double width) async {
    return await _prefs.setDouble(_keyDefaultWindowWidth, width);
  }

  /// Application window height.
  double get windowHeight => _prefs.getDouble(_keyWindowHeight) ?? getDefaultWindowHeight();

  /// Saves the window height.
  Future<bool> setWindowHeight(double height) async {
    return await _prefs.setDouble(_keyWindowHeight, height);
  }

  /// Default fallback window height (defaults to `900.0`).
  double getDefaultWindowHeight() {
    return _prefs.getDouble(_keyDefaultWindowHeight) ?? 900.0;
  }

  /// Saves default window height preference.
  Future<bool> setDefaultWindowHeight(double height) async {
    return await _prefs.setDouble(_keyDefaultWindowHeight, height);
  }

  /// Sets both window width and height simultaneously.
  Future<bool> setWindowSize(double width, double height) async {
    final results = await Future.wait([
      _prefs.setDouble(_keyWindowWidth, width),
      _prefs.setDouble(_keyWindowHeight, height),
    ]);
    return results.every((r) => r);
  }

  // =========================================================================
  // 6. NOTE EDITOR PREFERENCES
  // =========================================================================

  /// Whether to place cursor in the note content body on editor open (`true`) or title field (`false`).
  bool get putCursorOnContent => _prefs.getBool(_keyPutCursorOnContent) ?? true;

  /// Saves the cursor focus preference for the note editor.
  Future<bool> setPutCursorOnContent(bool value) async => await _prefs.setBool(_keyPutCursorOnContent, value);

  /// Note title font size (defaults to `22.0`).
  double get titleFontSize => _prefs.getDouble(_keyTitleFontSize) ?? 22.0;

  /// Saves the title font size.
  Future<bool> setTitleFontSize(double value) async => await _prefs.setDouble(_keyTitleFontSize, value);

  /// Note body content font size (defaults to `16.0`).
  double get contentFontSize => _prefs.getDouble(_keyContentFontSize) ?? 16.0;

  /// Saves the content font size.
  Future<bool> setContentFontSize(double value) async => await _prefs.setDouble(_keyContentFontSize, value);

  /// Line spacing height multiplier in editor (defaults to `1.5`).
  double get lineSpacing => _prefs.getDouble(_keyLineSpacing) ?? 1.5;

  /// Saves line spacing multiplier.
  Future<bool> setLineSpacing(double value) async => await _prefs.setDouble(_keyLineSpacing, value);

  // =========================================================================
  // 7. REMINDER & NOTIFICATION PREFERENCES
  // =========================================================================

  /// File path to custom reminder sound.
  String? get customReminderSoundPath => _prefs.getString(_keyCustomSoundPath);

  /// Display name of custom reminder sound.
  String get customReminderSoundName => _prefs.getString(_keyCustomSoundName) ?? 'Default Ring (alarm_ring.mp3)';

  /// Sets or clears the custom reminder sound path and name.
  Future<bool> setCustomReminderSound(String? path, String? name) async {
    if (path == null) {
      await _prefs.remove(_keyCustomSoundPath);
      return await _prefs.remove(_keyCustomSoundName);
    }
    await _prefs.setString(_keyCustomSoundPath, path);
    return await _prefs.setString(_keyCustomSoundName, name ?? 'Custom Sound');
  }

  /// Whether reminder audio playback is enabled.
  bool get reminderSoundEnabled => _prefs.getBool(_keyReminderSoundEnabled) ?? true;

  /// Sets reminder sound enabled state and notifies listenables.
  Future<bool> setReminderSoundEnabled(bool value) async {
    reminderSoundListenable.value = value;
    return await _prefs.setBool(_keyReminderSoundEnabled, value);
  }

  /// Whether reminder vibration feedback is enabled.
  bool get reminderVibrationEnabled => _prefs.getBool(_keyReminderVibrationEnabled) ?? true;

  /// Sets reminder vibration enabled state.
  Future<bool> setReminderVibrationEnabled(bool value) async {
    return await _prefs.setBool(_keyReminderVibrationEnabled, value);
  }

  /// Duration of reminder alarm playback in seconds (defaults to `30`).
  int get reminderDurationSeconds => _prefs.getInt(_keyReminderDurationSeconds) ?? 30;

  /// Sets reminder alarm playback duration in seconds.
  Future<bool> setReminderDurationSeconds(int seconds) async {
    return await _prefs.setInt(_keyReminderDurationSeconds, seconds);
  }

  /// Default repeat mode string for new reminders (defaults to `'once'`).
  String get defaultRepeatMode => _prefs.getString(_keyDefaultRepeatMode) ?? 'once';

  /// Sets the default repeat mode for new reminders.
  Future<bool> setDefaultRepeatMode(String mode) async {
    return await _prefs.setString(_keyDefaultRepeatMode, mode);
  }

  // =========================================================================
  // 8. DATE & TIME FORMATTING PREFERENCES
  // =========================================================================

  /// Whether system default date/time format is used instead of custom user formatting.
  bool get timeUseSystemFormat => _prefs.getBool(_keyTimeUseSystemFormat) ?? false;

  /// Saves system time format usage preference.
  Future<bool> setTimeUseSystemFormat(bool value) async => await _prefs.setBool(_keyTimeUseSystemFormat, value);

  /// Whether 24-hour time clock format is enabled (`true`) or 12-hour AM/PM (`false`).
  bool get timeIs24Hour => _prefs.getBool(_keyTimeIs24Hour) ?? false;

  /// Saves 24-hour time format preference.
  Future<bool> setTimeIs24Hour(bool value) async => await _prefs.setBool(_keyTimeIs24Hour, value);

  /// Day representation format string (e.g., `'d'`, `'dd'`).
  String get timeDayFormat => _prefs.getString(_keyTimeDayFormat) ?? 'dd';

  /// Saves day format representation.
  Future<bool> setTimeDayFormat(String value) async => await _prefs.setString(_keyTimeDayFormat, value);

  /// Month representation format string (e.g., `'M'`, `'MM'`, `'MMM'`, `'MMMM'`).
  String get timeMonthFormat => _prefs.getString(_keyTimeMonthFormat) ?? 'MMM';

  /// Saves month format representation.
  Future<bool> setTimeMonthFormat(String value) async => await _prefs.setString(_keyTimeMonthFormat, value);

  /// Year representation format string (e.g., `'yy'`, `'yyyy'`).
  String get timeYearFormat => _prefs.getString(_keyTimeYearFormat) ?? 'yyyy';

  /// Saves year format representation.
  Future<bool> setTimeYearFormat(String value) async => await _prefs.setString(_keyTimeYearFormat, value);

  /// Date component separator character (e.g., `'-'`, `'/'`, `'.'`).
  String get timeSeparator => _prefs.getString(_keyTimeSeparator) ?? '-';

  /// Saves date separator character.
  Future<bool> setTimeSeparator(String value) async => await _prefs.setString(_keyTimeSeparator, value);

  /// Order sequence of date/time components (e.g., `['day', 'month', 'year', 'time']`).
  List<String> get timeOrder => _prefs.getStringList(_keyTimeOrder) ?? const ['day', 'month', 'year', 'time'];

  /// Saves date component layout ordering sequence.
  Future<bool> setTimeOrder(List<String> order) async => await _prefs.setStringList(_keyTimeOrder, order);

  // =========================================================================
  // 9. GENERAL / LIFECYCLE METHODS
  // =========================================================================

  /// Clears all keys stored in [SharedPreferences].
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
