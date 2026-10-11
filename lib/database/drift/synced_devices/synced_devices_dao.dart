import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_table.dart';

import '../local_database.dart';

part 'synced_devices_dao.g.dart';


// rebuild using 'flutter pub run build_runner build --delete-conflicting-outputs'
final syncedDevicesDaoProvider = Provider(
  (ref) => ref.watch(localDatabaseProvider).syncedDevicesDao,
);

final syncedDevicesStreamProvider = StreamProvider<List<SyncedDevice>>((ref) {
  final dao = ref.watch(syncedDevicesDaoProvider);
  return dao.watchAllDevices();
});

@DriftAccessor(tables: [SyncedDevices])
class SyncedDevicesDao extends DatabaseAccessor<LocalDatabase>
    with _$SyncedDevicesDaoMixin {
  SyncedDevicesDao(super.db);

  /// Watches all synced devices in real-time
  Stream<List<SyncedDevice>> watchAllDevices() {
    return select(syncedDevices).watch();
  }

  /// Deletes a device by its UUID
  Future<int> deleteDevice(String uuid) {
    return (delete(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).go();
  }

  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  Future<void> upsertDeviceAsHost({
    required String uuid,
    required String name,
    String? lastKnownIp,
    int? lastKnownPort,
  }) async {
    await into(syncedDevices).insertOnConflictUpdate(
      SyncedDevicesCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        lastKnownIp: Value(lastKnownIp),
        lastKnownPort: Value(lastKnownPort),
        lastSeenAsHostAt: Value(DateTime.now()),
      ),
    );
  }
  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  Future<void> upsertDeviceAsClient({
    required String uuid,
    required String name,
  }) async {
    await into(syncedDevices).insertOnConflictUpdate(
      SyncedDevicesCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        lastSeenAsClientAt: Value(DateTime.now()),
      ),
    );
  }

  Future<SyncedDevice?> getMostRecentHost() async {
    return (select(syncedDevices)
      ..where((t) => t.lastSeenAsHostAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
      ..limit(1))
        .getSingleOrNull();
  }


  /// Checks if a device UUID already exists in our local pairs history.
  Future<bool> isDeviceKnown(String uuid) async {
    final existingDevice = await (select(syncedDevices)
      ..where((t) => t.deviceUuid.equals(uuid)))
        .getSingleOrNull();

    return existingDevice != null; // Returns true if found, false if unknown
  }
}
