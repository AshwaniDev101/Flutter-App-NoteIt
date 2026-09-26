// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synced_devices_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncedDevicesDaoMixin on DatabaseAccessor<LocalDatabase> {
  $SyncedDevicesTable get syncedDevices => attachedDatabase.syncedDevices;
  SyncedDevicesDaoManager get managers => SyncedDevicesDaoManager(this);
}

class SyncedDevicesDaoManager {
  final _$SyncedDevicesDaoMixin _db;
  SyncedDevicesDaoManager(this._db);
  $$SyncedDevicesTableTableManager get syncedDevices =>
      $$SyncedDevicesTableTableManager(_db.attachedDatabase, _db.syncedDevices);
}
