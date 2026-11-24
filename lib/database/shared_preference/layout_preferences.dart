import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final layoutPreferencesProvider = Provider<LayoutPreferences>((ref) {
  return LayoutPreferences(ref.watch(sharedPreferencesProvider));
});

class LayoutPreferences {
  final SharedPreferences _prefs;
  LayoutPreferences(this._prefs);

  static const String _keyWindowWidth = 'window_width';
  static const String _keyDefaultWindowWidth = 'default_window_width';
  static const String _keyWindowHeight = 'window_height';
  static const String _keyDefaultWindowHeight = 'default_window_height';
  static const String _keyListPanelWidth = 'list_panel_width';
  static const String _keyDefaultListPanelWidth = 'default_list_panel_width';
  static const String _keyIsWindowMaximized = 'is_window_maximized';

  bool get isWindowMaximized => _prefs.getBool(_keyIsWindowMaximized) ?? false;

  Future<bool> setWindowMaximized(bool value) async {
    return await _prefs.setBool(_keyIsWindowMaximized, value);
  }

  double get listPanelWidth => _prefs.getDouble(_keyListPanelWidth) ?? getDefaultListPanelWidth();

  Future<bool> setListPanelWidth(double width) async {
    return await _prefs.setDouble(_keyListPanelWidth, width);
  }

  double getDefaultListPanelWidth() {
    return _prefs.getDouble(_keyDefaultListPanelWidth) ?? 340.0;
  }

  Future<bool> setDefaultListPanelWidth(double width) async {
    return await _prefs.setDouble(_keyDefaultListPanelWidth, width);
  }

  double get windowWidth => _prefs.getDouble(_keyWindowWidth) ?? getDefaultWindowWidth();

  Future<bool> setWindowWidth(double width) async {
    return await _prefs.setDouble(_keyWindowWidth, width);
  }

  double getDefaultWindowWidth() {
    return _prefs.getDouble(_keyDefaultWindowWidth) ?? 1400.0;
  }

  Future<bool> setDefaultWindowWidth(double width) async {
    return await _prefs.setDouble(_keyDefaultWindowWidth, width);
  }

  double get windowHeight => _prefs.getDouble(_keyWindowHeight) ?? getDefaultWindowHeight();

  Future<bool> setWindowHeight(double height) async {
    return await _prefs.setDouble(_keyWindowHeight, height);
  }

  double getDefaultWindowHeight() {
    return _prefs.getDouble(_keyDefaultWindowHeight) ?? 900.0;
  }

  Future<bool> setDefaultWindowHeight(double height) async {
    return await _prefs.setDouble(_keyDefaultWindowHeight, height);
  }

  Future<bool> setWindowSize(double width, double height) async {
    final results = await Future.wait([
      _prefs.setDouble(_keyWindowWidth, width),
      _prefs.setDouble(_keyWindowHeight, height),
    ]);
    return results.every((r) => r);
  }
}
