import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';
import 'package:noteit/shared/menus/view_menu_button.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

final noteViewPreferencesProvider = Provider<NoteViewPreferences>((ref) {
  return NoteViewPreferences(ref.watch(sharedPreferencesProvider));
});

class NoteViewPreferences {
  final SharedPreferences _prefs;
  NoteViewPreferences(this._prefs);

  static const String _keyLastActiveFolderId = 'last_active_folder_id';
  static const String _keyLastActiveNoteId = 'last_active_note_id';
  static const String _keyViewType = 'view_type';
  static const String _keyPageViewPrefix = 'page_view_';
  static const String _keyDefaultPageViewPrefix = 'default_page_view_';
  static const String _keyPageSortPrefix = 'page_sort_';
  static const String _keyDefaultPageSortPrefix = 'default_page_sort_';

  String? get lastActiveFolderId => _prefs.getString(_keyLastActiveFolderId);

  Future<bool> setLastActiveFolderId(String? uuid) async {
    if (uuid == null) {
      return await _prefs.remove(_keyLastActiveFolderId);
    }
    return await _prefs.setString(_keyLastActiveFolderId, uuid);
  }

  String? get lastActiveNoteId => _prefs.getString(_keyLastActiveNoteId);

  Future<bool> setLastActiveNoteId(String? uuid) async {
    if (uuid == null) {
      return await _prefs.remove(_keyLastActiveNoteId);
    }
    return await _prefs.setString(_keyLastActiveNoteId, uuid);
  }

  int get viewType => _prefs.getInt(_keyViewType) ?? 0;

  Future<bool> setViewType(int value) async {
    return await _prefs.setInt(_keyViewType, value);
  }

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

  Future<bool> setPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('$_keyPageViewPrefix$pageId', view.name);
  }

  NoteViewType getDefaultPageViewType(String pageId, {NoteViewType fallback = NoteViewType.grid}) {
    final savedName = _prefs.getString('$_keyDefaultPageViewPrefix$pageId');
    if (savedName == null) return fallback;
    return NoteViewType.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  Future<bool> setDefaultPageViewType(String pageId, NoteViewType view) async {
    return await _prefs.setString('$_keyDefaultPageViewPrefix$pageId', view.name);
  }

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

  Future<bool> setPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('$_keyPageSortPrefix$pageId', sort.name);
  }

  NoteSortPreference getDefaultPageSortOption(String pageId, {NoteSortPreference fallback = NoteSortPreference.createdAt}) {
    final savedName = _prefs.getString('$_keyDefaultPageSortPrefix$pageId');
    if (savedName == null) return fallback;
    return NoteSortPreference.values.firstWhere((e) => e.name == savedName, orElse: () => fallback);
  }

  Future<bool> setDefaultPageSortOption(String pageId, NoteSortPreference sort) async {
    return await _prefs.setString('$_keyDefaultPageSortPrefix$pageId', sort.name);
  }

  Future<void> resetPageViewsAndSortsToDefaults() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPageViewPrefix) || key.startsWith(_keyPageSortPrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
