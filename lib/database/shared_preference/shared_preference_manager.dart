import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../sync/sync_engine.dart';

// The Global Settings Provider
final sharedPreferenceProvider = Provider<SharedPreferenceManager>((ref) {
  return SharedPreferenceManager.instance;
});

class SharedPreferenceManager {
  SharedPreferenceManager._internal();

  static final SharedPreferenceManager instance =
      SharedPreferenceManager._internal();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyViewType = 'view_type';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyMasterPassword = 'master_password';
  static const String _keyThemeType = 'theme_type';
  static const String _keySyncEngine = 'sync_engine';
  static const String _keyHostUuid = 'host_uuid';

  // Key for keeping notes unlocked during session
  static const String _keyKeepUnlockedSession = 'keep_unlocked_session';

  // --- Sync Engine Mode ---
  // Defaults to offline if the user has never chosen one
  SyncEngine get currentEngine {
    final engineName =
        _prefs.getString(_keySyncEngine) ?? SyncEngine.offline.name;
    return SyncEngine.values.firstWhere(
      (e) => e.name == engineName,
      orElse: () => SyncEngine.offline,
    );
  }

  Future<bool> setCurrentEngine(SyncEngine engine) async {
    return await _prefs.setString(_keySyncEngine, engine.name);
  }

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
  bool get keepUnlockedDuringSession =>
      _prefs.getBool(_keyKeepUnlockedSession) ?? false;

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
}
