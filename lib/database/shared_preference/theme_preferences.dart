import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  return ThemePreferences(ref.watch(sharedPreferencesProvider));
});

class ThemePreferences {
  final SharedPreferences _prefs;
  ThemePreferences(this._prefs);

  static const String _keyThemeType = 'theme_type';
  static const String _keyShowDynamicKeyHints = 'show_dynamic_key_hints';
  static const String _keyAppendShortcutToTooltips = 'append_shortcut_to_tooltips';

  String get themeType => _prefs.getString(_keyThemeType) ?? 'dark';

  Future<bool> setThemeType(String value) async {
    return await _prefs.setString(_keyThemeType, value);
  }

  bool get showDynamicKeyHints => _prefs.getBool(_keyShowDynamicKeyHints) ?? true;

  Future<bool> setShowDynamicKeyHints(bool value) async {
    return await _prefs.setBool(_keyShowDynamicKeyHints, value);
  }

  bool get appendShortcutToTooltips => _prefs.getBool(_keyAppendShortcutToTooltips) ?? true;

  Future<bool> setAppendShortcutToTooltips(bool value) async {
    return await _prefs.setBool(_keyAppendShortcutToTooltips, value);
  }
}
