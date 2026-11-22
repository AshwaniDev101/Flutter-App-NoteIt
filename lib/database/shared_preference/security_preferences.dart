import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final securityPreferencesProvider = Provider<SecurityPreferences>((ref) {
  return SecurityPreferences(ref.watch(sharedPreferencesProvider));
});

class SecurityPreferences {
  final SharedPreferences _prefs;
  SecurityPreferences(this._prefs);

  static const String _keyMasterPassword = 'master_password';
  static const String _keyHasMasterPassword = 'has_master_password';
  static const String _keyKeepUnlockedSession = 'keep_unlocked_session';

  Future<bool> setHasMasterPassword(bool hasPassword) async {
    if (_prefs.containsKey(_keyMasterPassword)) {
      await _prefs.remove(_keyMasterPassword);
    }
    return await _prefs.setBool(_keyHasMasterPassword, hasPassword);
  }

  bool get hasMasterPassword => _prefs.getBool(_keyHasMasterPassword) ?? _prefs.containsKey(_keyMasterPassword);

  Future<bool> removeMasterPassword() async {
    if (_prefs.containsKey(_keyMasterPassword)) {
      await _prefs.remove(_keyMasterPassword);
    }
    return await _prefs.remove(_keyHasMasterPassword);
  }

  bool get keepUnlockedDuringSession => _prefs.getBool(_keyKeepUnlockedSession) ?? false;

  Future<bool> setKeepUnlockedDuringSession(bool value) async {
    return await _prefs.setBool(_keyKeepUnlockedSession, value);
  }
}
