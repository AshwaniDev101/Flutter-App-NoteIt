import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceManager {
  SharedPreferenceManager._internal();
  static final SharedPreferenceManager _instance = SharedPreferenceManager._internal();

  factory SharedPreferenceManager() => _instance;

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  static const String _keyViewType = 'view_type';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyMasterPassword = 'master_password';
  static const String _keyIsDarkMode = 'is_dark_mode';


  int get viewType => _prefs.getInt(_keyViewType) ?? 0;
  Future<bool> setViewType(int value) async {
    return await _prefs.setInt(_keyViewType, value);
  }

  int get lastSyncTime => _prefs.getInt(_keyLastSyncTime) ?? 0;
  Future<bool> setLastSyncTime(int timestamp) async {
    return await _prefs.setInt(_keyLastSyncTime, timestamp);
  }

  String? get masterPassword => _prefs.getString(_keyMasterPassword);
  Future<bool> setMasterPassword(String password) async {
    return await _prefs.setString(_keyMasterPassword, password);
  }

  bool get isDarkMode => _prefs.getBool(_keyIsDarkMode) ?? false;
  Future<bool> setIsDarkMode(bool value) async {
    return await _prefs.setBool(_keyIsDarkMode, value);
  }

  bool get hasMasterPassword => _prefs.containsKey(_keyMasterPassword);

  Future<bool> removeMasterPassword() async {
    return await _prefs.remove(_keyMasterPassword);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}