import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noteit/core/sync/sync_engine.dart';
export 'package:noteit/core/sync/sync_engine.dart' show SyncRole;
import '../../shared/menus/view_menu_button.dart';
import '../drift/notes/notes_dao.dart';

import 'sync_preferences.dart';
import 'theme_preferences.dart';
import 'security_preferences.dart';
import 'note_view_preferences.dart';
import 'layout_preferences.dart';
import 'editor_preferences.dart';
import 'reminder_preferences.dart';
import 'date_time_preferences.dart';
import 'workspace_preferences.dart';
import 'app_preferences_utility.dart';

/// Global Riverpod Provider for accessing [SharedPreferenceManager].
@Deprecated('Use domain-specific preference providers instead')
final sharedPreferenceProvider = Provider<SharedPreferenceManager>((ref) {
  return SharedPreferenceManager.instance;
});

/// Centralized manager for accessing and modifying application settings stored in [SharedPreferences].
@Deprecated('Use domain-specific preference providers instead')
class SharedPreferenceManager {
  SharedPreferenceManager._internal();

  static final SharedPreferenceManager instance = SharedPreferenceManager._internal();

  static late SyncPreferences _sync;
  static late ThemePreferences _theme;
  static late SecurityPreferences _security;
  static late NoteViewPreferences _noteView;
  static late LayoutPreferences _layout;
  static late EditorPreferences _editor;
  static late ReminderPreferences _reminder;
  static late DateTimePreferences _dateTime;
  static late WorkspacePreferences _workspace;
  static late AppPreferencesUtility _utility;

  /// Reactive notifier for changes to the reminder sound enabled state.
  /// Deprecated: Migrate to ref.watch(reminderSoundProvider)
  @Deprecated('Migrate to reminderSoundProvider')
  late final ValueNotifier<bool> reminderSoundListenable;

  /// Initializes [SharedPreferences] and delegates.
  static void init(SharedPreferences prefs) {
    _sync = SyncPreferences(prefs);
    _theme = ThemePreferences(prefs);
    _security = SecurityPreferences(prefs);
    _noteView = NoteViewPreferences(prefs);
    _layout = LayoutPreferences(prefs);
    _editor = EditorPreferences(prefs);
    _reminder = ReminderPreferences(prefs);
    _dateTime = DateTimePreferences(prefs);
    _workspace = WorkspacePreferences(prefs);
    _utility = AppPreferencesUtility(prefs);

    // Maintain backwards compatibility for the ValueNotifier
    // until all usages are migrated.
    instance.reminderSoundListenable = ValueNotifier<bool>(_reminder.reminderSoundEnabled);
  }

  // =========================================================================
  // 1. SYNC & P2P METHODS
  // =========================================================================
  SyncMode get syncMode => _sync.syncMode;
  Future<bool> setSyncMode(SyncMode mode) => _sync.setSyncMode(mode);
  SyncEngine get currentEngine => _sync.currentEngine;
  Future<bool> setCurrentEngine(SyncEngine engine) => _sync.setCurrentEngine(engine);
  String get hostUuid => _sync.hostUuid;
  SyncRole get syncRole => _sync.syncRole;
  void setSyncRole(SyncRole role) => _sync.setSyncRole(role);
  int get lastSyncTime => _sync.lastSyncTime;
  Future<bool> setLastSyncTime(int timestamp) => _sync.setLastSyncTime(timestamp);
  Future<bool> clearSyncTime() => _sync.clearSyncTime();
  int get lastCloudSyncTime => _sync.lastCloudSyncTime;
  Future<bool> setLastCloudSyncTime(int timestamp) => _sync.setLastCloudSyncTime(timestamp);

  // =========================================================================
  // 2. THEME & INTERFACE METHODS
  // =========================================================================
  String get themeType => _theme.themeType;
  Future<bool> setThemeType(String value) => _theme.setThemeType(value);
  bool get showDynamicKeyHints => _theme.showDynamicKeyHints;
  Future<bool> setShowDynamicKeyHints(bool value) => _theme.setShowDynamicKeyHints(value);
  bool get appendShortcutToTooltips => _theme.appendShortcutToTooltips;
  Future<bool> setAppendShortcutToTooltips(bool value) => _theme.setAppendShortcutToTooltips(value);

  // =========================================================================
  // 3. SECURITY & SESSION METHODS
  // =========================================================================
  Future<bool> setHasMasterPassword(bool hasPassword) => _security.setHasMasterPassword(hasPassword);
  bool get hasMasterPassword => _security.hasMasterPassword;
  Future<bool> removeMasterPassword() => _security.removeMasterPassword();
  bool get keepUnlockedDuringSession => _security.keepUnlockedDuringSession;
  Future<bool> setKeepUnlockedDuringSession(bool value) => _security.setKeepUnlockedDuringSession(value);

  // =========================================================================
  // 4. NOTE VIEW & SORT METHODS
  // =========================================================================
  String? get lastActiveFolderId => _noteView.lastActiveFolderId;
  Future<bool> setLastActiveFolderId(String? uuid) => _noteView.setLastActiveFolderId(uuid);
  String? get lastActiveNoteId => _noteView.lastActiveNoteId;
  Future<bool> setLastActiveNoteId(String? uuid) => _noteView.setLastActiveNoteId(uuid);
  int get viewType => _noteView.viewType;
  Future<bool> setViewType(int value) => _noteView.setViewType(value);
  NoteViewType getPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) => _noteView.getPageViewType(pageId, fallback: fallback);
  Future<bool> setPageViewType(String pageId, NoteViewType view) => _noteView.setPageViewType(pageId, view);
  NoteViewType getDefaultPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) => _noteView.getDefaultPageViewType(pageId, fallback: fallback);
  Future<bool> setDefaultPageViewType(String pageId, NoteViewType view) => _noteView.setDefaultPageViewType(pageId, view);
  NoteSortPreference getPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) => _noteView.getPageSortOption(pageId, fallback: fallback);
  Future<bool> setPageSortOption(String pageId, NoteSortPreference sort) => _noteView.setPageSortOption(pageId, sort);
  NoteSortPreference getDefaultPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) => _noteView.getDefaultPageSortOption(pageId, fallback: fallback);
  Future<bool> setDefaultPageSortOption(String pageId, NoteSortPreference sort) => _noteView.setDefaultPageSortOption(pageId, sort);
  Future<void> resetPageViewsAndSortsToDefaults() => _noteView.resetPageViewsAndSortsToDefaults();

  // =========================================================================
  // 5. LAYOUT & WINDOW DIMENSION METHODS
  // =========================================================================
  double get listPanelWidth => _layout.listPanelWidth;
  Future<bool> setListPanelWidth(double width) => _layout.setListPanelWidth(width);
  double getDefaultListPanelWidth() => _layout.getDefaultListPanelWidth();
  Future<bool> setDefaultListPanelWidth(double width) => _layout.setDefaultListPanelWidth(width);
  double get windowWidth => _layout.windowWidth;
  Future<bool> setWindowWidth(double width) => _layout.setWindowWidth(width);
  double getDefaultWindowWidth() => _layout.getDefaultWindowWidth();
  Future<bool> setDefaultWindowWidth(double width) => _layout.setDefaultWindowWidth(width);
  double get windowHeight => _layout.windowHeight;
  Future<bool> setWindowHeight(double height) => _layout.setWindowHeight(height);
  double getDefaultWindowHeight() => _layout.getDefaultWindowHeight();
  Future<bool> setDefaultWindowHeight(double height) => _layout.setDefaultWindowHeight(height);
  Future<bool> setWindowSize(double width, double height) => _layout.setWindowSize(width, height);

  // =========================================================================
  // 6. NOTE EDITOR PREFERENCES
  // =========================================================================
  bool get putCursorOnContent => _editor.putCursorOnContent;
  Future<bool> setPutCursorOnContent(bool value) => _editor.setPutCursorOnContent(value);
  double get titleFontSize => _editor.titleFontSize;
  Future<bool> setTitleFontSize(double value) => _editor.setTitleFontSize(value);
  double get contentFontSize => _editor.contentFontSize;
  Future<bool> setContentFontSize(double value) => _editor.setContentFontSize(value);
  double get lineSpacing => _editor.lineSpacing;
  Future<bool> setLineSpacing(double value) => _editor.setLineSpacing(value);

  // =========================================================================
  // 7. REMINDER & NOTIFICATION PREFERENCES
  // =========================================================================
  String? get customReminderSoundPath => _reminder.customReminderSoundPath;
  String get customReminderSoundName => _reminder.customReminderSoundName;
  Future<bool> setCustomReminderSound(String? path, String? name) => _reminder.setCustomReminderSound(path, name);
  bool get reminderSoundEnabled => _reminder.reminderSoundEnabled;
  Future<bool> setReminderSoundEnabled(bool value) async {
    reminderSoundListenable.value = value;
    return await _reminder.setReminderSoundEnabled(value);
  }
  bool get reminderVibrationEnabled => _reminder.reminderVibrationEnabled;
  Future<bool> setReminderVibrationEnabled(bool value) => _reminder.setReminderVibrationEnabled(value);
  int get reminderDurationSeconds => _reminder.reminderDurationSeconds;
  Future<bool> setReminderDurationSeconds(int seconds) => _reminder.setReminderDurationSeconds(seconds);
  String get defaultRepeatMode => _reminder.defaultRepeatMode;
  Future<bool> setDefaultRepeatMode(String mode) => _reminder.setDefaultRepeatMode(mode);

  // =========================================================================
  // 8. DATE & TIME FORMATTING PREFERENCES
  // =========================================================================
  bool get timeUseSystemFormat => _dateTime.timeUseSystemFormat;
  Future<bool> setTimeUseSystemFormat(bool value) => _dateTime.setTimeUseSystemFormat(value);
  bool get timeIs24Hour => _dateTime.timeIs24Hour;
  Future<bool> setTimeIs24Hour(bool value) => _dateTime.setTimeIs24Hour(value);
  String get timeDayFormat => _dateTime.timeDayFormat;
  Future<bool> setTimeDayFormat(String value) => _dateTime.setTimeDayFormat(value);
  String get timeMonthFormat => _dateTime.timeMonthFormat;
  Future<bool> setTimeMonthFormat(String value) => _dateTime.setTimeMonthFormat(value);
  String get timeYearFormat => _dateTime.timeYearFormat;
  Future<bool> setTimeYearFormat(String value) => _dateTime.setTimeYearFormat(value);
  String get timeSeparator => _dateTime.timeSeparator;
  Future<bool> setTimeSeparator(String value) => _dateTime.setTimeSeparator(value);
  List<String> get timeOrder => _dateTime.timeOrder;
  Future<bool> setTimeOrder(List<String> order) => _dateTime.setTimeOrder(order);

  // =========================================================================
  // 9. WORKSPACE SELECTION PREFERENCES
  // =========================================================================
  String? get activeWorkspaceId => _workspace.activeWorkspaceId;
  Future<bool> setActiveWorkspaceId(String value) => _workspace.setActiveWorkspaceId(value);
  bool get isEnableWorkspace => _workspace.isEnableWorkspace;
  bool get isWorkspaceEnabled => _workspace.isWorkspaceEnabled;
  Future<bool> setEnableWorkspace(bool value) => _workspace.setEnableWorkspace(value);
  Future<bool> setWorkspaceEnable(bool value) => _workspace.setWorkspaceEnable(value);
  bool get isShowDeviceFilter => _workspace.isShowDeviceFilter;
  Future<bool> setShowDeviceFilter(bool value) => _workspace.setShowDeviceFilter(value);

  // =========================================================================
  // 10. GENERAL / LIFECYCLE METHODS
  // =========================================================================
  Future<bool> clearAll() => _utility.clearAll();
}
