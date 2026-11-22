import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_utility.dart';

final workspacePreferencesProvider = Provider<WorkspacePreferences>((ref) {
  return WorkspacePreferences(ref.watch(sharedPreferencesProvider));
});

class WorkspacePreferences {
  final SharedPreferences _prefs;
  WorkspacePreferences(this._prefs);

  static const String _keyActiveWorkspaceId = 'active_workspace_id';
  static const String _keyEnableWorkspace = 'enable_workspace';
  static const String _keyShowDeviceFilter = 'show_device_filter';

  String? get activeWorkspaceId => _prefs.getString(_keyActiveWorkspaceId);

  Future<bool> setActiveWorkspaceId(String value) async => await _prefs.setString(_keyActiveWorkspaceId, value);

  bool get isEnableWorkspace => _prefs.getBool(_keyEnableWorkspace) ?? false;

  bool get isWorkspaceEnabled => isEnableWorkspace;

  Future<bool> setEnableWorkspace(bool value) async => await _prefs.setBool(_keyEnableWorkspace, value);

  Future<bool> setWorkspaceEnable(bool value) async => await setEnableWorkspace(value);

  bool get isShowDeviceFilter => _prefs.getBool(_keyShowDeviceFilter) ?? false;

  Future<bool> setShowDeviceFilter(bool value) async => await _prefs.setBool(_keyShowDeviceFilter, value);
}
