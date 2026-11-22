import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app_preferences_utility.dart';
import 'package:noteit/core/sync/sync_engine.dart';

final syncPreferencesProvider = Provider<SyncPreferences>((ref) {
  return SyncPreferences(ref.watch(sharedPreferencesProvider));
});

class SyncPreferences {
  final SharedPreferences _prefs;
  SyncPreferences(this._prefs);

  static const String _keySyncMode = 'sync_mode';
  static const String _keyHostUuid = 'host_uuid';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyLastCloudSyncTime = 'last_cloud_sync_time';

  SyncMode get syncMode {
    final modeName = _prefs.getString(_keySyncMode) ?? SyncMode.offline.name;
    return SyncMode.values.firstWhere((e) => e.name == modeName, orElse: () => SyncMode.offline);
  }

  Future<bool> setSyncMode(SyncMode mode) async {
    return await _prefs.setString(_keySyncMode, mode.name);
  }

  SyncEngine get currentEngine {
    if (syncMode.isCloud) return SyncEngine.cloud;
    if (syncMode.isLocal) return SyncEngine.local;
    return SyncEngine.offline;
  }

  Future<bool> setCurrentEngine(SyncEngine engine) async {
    switch (engine) {
      case SyncEngine.cloud:
        return await setSyncMode(SyncMode.cloud);
      case SyncEngine.offline:
        return await setSyncMode(SyncMode.offline);
      case SyncEngine.local:
        if (syncMode.isLocal) return true;
        return await setSyncMode(SyncMode.localUndefined);
    }
  }

  String get hostUuid {
    String? uuid = _prefs.getString(_keyHostUuid);
    if (uuid == null) {
      uuid = const Uuid().v4();
      _prefs.setString(_keyHostUuid, uuid);
    }
    return uuid;
  }

  SyncRole get syncRole {
    if (syncMode.isHost) return SyncRole.host;
    if (syncMode.isClient) return SyncRole.client;
    return SyncRole.undefine;
  }

  void setSyncRole(SyncRole role) {
    switch (role) {
      case SyncRole.undefine:
        if (syncMode.isLocal) setSyncMode(SyncMode.localUndefined);
        break;
      case SyncRole.host:
        setSyncMode(SyncMode.localHost);
        break;
      case SyncRole.client:
        setSyncMode(SyncMode.localClient);
        break;
    }
  }

  int get lastSyncTime => _prefs.getInt(_keyLastSyncTime) ?? 0;

  Future<bool> setLastSyncTime(int timestamp) async {
    return await _prefs.setInt(_keyLastSyncTime, timestamp);
  }

  Future<bool> clearSyncTime() async {
    return await _prefs.remove(_keyLastSyncTime);
  }

  int get lastCloudSyncTime => _prefs.getInt(_keyLastCloudSyncTime) ?? 0;

  Future<bool> setLastCloudSyncTime(int timestamp) async {
    return await _prefs.setInt(_keyLastCloudSyncTime, timestamp);
  }
}
