import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod Provider for consistent dependency injection
final sharedPreferenceProvider = Provider<SharedPreferenceManager>((ref) {
  return SharedPreferenceManager.instance;
});

class SharedPreferenceManager {
  SharedPreferenceManager._internal();

  static final SharedPreferenceManager instance = SharedPreferenceManager._internal();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyViewType = 'view_type';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyMasterPassword = 'master_password';
  static const String _keyThemeType = 'theme_type';

  // Key for keeping notes unlocked during session
  static const String _keyKeepUnlockedSession = 'keep_unlocked_session';

  // --- View Type ---
  int get viewType => _prefs.getInt(_keyViewType) ?? 0;
  Future<bool> setViewType(int value) async {
    return await _prefs.setInt(_keyViewType, value);
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

  // --- Theme  ---
  String get themeType => _prefs.getString(_keyThemeType) ?? 'dark';
  Future<bool> setThemeType(String value) async {
    return await _prefs.setString(_keyThemeType, value);
  }

  // --- Global ---
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}