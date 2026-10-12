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
    String? deviceType,
    int? protocolVersion,
  }) async {
    await into(syncedDevices).insertOnConflictUpdate(
      SyncedDevicesCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        // SAFE UPDATE: Only overwrite IP/Port if new values are actually provided
        lastKnownIp: lastKnownIp == null ? const Value.absent() : Value(lastKnownIp),
        lastKnownPort: lastKnownPort == null ? const Value.absent() : Value(lastKnownPort),
        // Save metadata if available
        deviceType: deviceType == null ? const Value.absent() : Value(deviceType),
        protocolVersion: protocolVersion == null ? const Value.absent() : Value(protocolVersion),
        lastSeenAsHostAt: Value(DateTime.now()),
      ),
    );
  }

  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  Future<void> upsertDeviceAsClient({
    required String uuid,
    required String name,
    String? lastKnownIp,
    int? lastKnownPort,
    String? deviceType,
    int? protocolVersion,
  }) async {
    await into(syncedDevices).insertOnConflictUpdate(
      SyncedDevicesCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        lastKnownIp: lastKnownIp == null ? const Value.absent() : Value(lastKnownIp),
        lastKnownPort: lastKnownPort == null ? const Value.absent() : Value(lastKnownPort),
        deviceType: deviceType == null ? const Value.absent() : Value(deviceType),
        protocolVersion: protocolVersion == null ? const Value.absent() : Value(protocolVersion),
        lastSeenAsClientAt: Value(DateTime.now()),
      ),
    );
  }

  /// Use this query to instantly try reconnecting to past hosts
  /// before falling back to mDNS / UDP broadcasting
  Future<List<SyncedDevice>> getRecentHostsForFastReconnect() async {
    return (select(syncedDevices)
      ..where((t) => t.lastKnownIp.isNotNull() & t.lastKnownPort.isNotNull())
      ..where((t) => t.lastSeenAsHostAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
      ..limit(5))
        .get();
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
    final countExp = syncedDevices.deviceUuid.count();
    final query = selectOnly(syncedDevices)
      ..addColumns([countExp])
      ..where(syncedDevices.deviceUuid.equals(uuid));

    final result = await query.map((row) => row.read(countExp)).getSingle();

    // If result is somehow null, it defaults to 0.
    // This avoids the '!' operator completely.
    return (result ?? 0) > 0;
  }
}