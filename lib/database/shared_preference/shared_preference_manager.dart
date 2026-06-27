import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod

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
  static const String _keyIsDarkMode = 'is_dark_mode';

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

  // Added to allow forcing a full re-sync without wiping all user settings
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

  // --- Theme ---
  bool get isDarkMode => _prefs.getBool(_keyIsDarkMode) ?? false;
  Future<bool> setIsDarkMode(bool value) async {
    return await _prefs.setBool(_keyIsDarkMode, value);
  }

  // --- Global ---
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}