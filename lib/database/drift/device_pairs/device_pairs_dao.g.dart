// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_pairs_dao.dart';

// ignore_for_file: type=lint
mixin _$DevicePairsDaoMixin on DatabaseAccessor<LocalDatabase> {
  $DevicePairsTable get devicePairs => attachedDatabase.devicePairs;
  DevicePairsDaoManager get managers => DevicePairsDaoManager(this);
}

class DevicePairsDaoManager {
  final _$DevicePairsDaoMixin _db;
  DevicePairsDaoManager(this._db);
  $$DevicePairsTableTableManager get devicePairs =>
      $$DevicePairsTableTableManager(_db.attachedDatabase, _db.devicePairs);
}
