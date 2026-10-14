import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_table.dart';

import '../local_database.dart';

part 'synced_devices_dao.g.dart';

// rebuild using 'dart run build_runner build --delete-conflicting-outputs'
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

  /// UPGRADED: Watches all active synced devices, hiding soft-deleted ones
  Stream<List<SyncedDevice>> watchAllDevices() {
    return (select(syncedDevices)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
    ).watch();
  }

  /// UPGRADED: Soft-deletes the device so the deletion can sync to other platforms
  Future<int> deleteDevice(String uuid) async {
    return await (update(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).write(
      SyncedDevicesCompanion.custom(
        deletedAt: Variable(DateTime.now().toUtc()),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: syncedDevices.updateCounter + const Constant(1),
      ),
    );
  }

  /// NEW: Helper to block/unblock a device using the new blockedAt timestamp
  Future<void> setDeviceBlocked(String uuid, {required bool isBlocked}) async {
    await (update(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).write(
      SyncedDevicesCompanion.custom(
        blockedAt: Variable(isBlocked ? DateTime.now().toUtc() : null),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: syncedDevices.updateCounter + const Constant(1),
      ),
    );
  }

  // =========================================================================
  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  // =========================================================================

  /// UPGRADED: Safely upserts without destroying the updateCounter
  Future<void> upsertDeviceAsHost({
    required String uuid,
    required String name,
    String? lastKnownIp,
    int? lastKnownPort,
    String? deviceType,
    int? protocolVersion,
  }) async {
    final existing = await (select(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).getSingleOrNull();
    final now = DateTime.now().toUtc();

    if (existing != null) {
      await (update(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).write(
        SyncedDevicesCompanion.custom(
          deviceName: Variable(name),

          // SAFE UPDATE: If new value is null, keep the old database value
          lastKnownIp: lastKnownIp == null ? syncedDevices.lastKnownIp : Variable(lastKnownIp),
          lastKnownPort: lastKnownPort == null ? syncedDevices.lastKnownPort : Variable(lastKnownPort),
          deviceType: deviceType == null ? syncedDevices.deviceType : Variable(deviceType),
          protocolVersion: protocolVersion == null ? syncedDevices.protocolVersion : Variable(protocolVersion),

          lastSeenAsHostAt: Variable(now),
          deletedAt: const Variable(null), // Restore if it was previously soft-deleted

          // SYNC ENGINE: Increment counter
          updatedAt: Variable(now),
          updateCounter: syncedDevices.updateCounter + const Constant(1),
        ),
      );
    } else {
      await into(syncedDevices).insert(
        SyncedDevicesCompanion.insert(
          deviceUuid: uuid,
          deviceName: name,
          lastKnownIp: lastKnownIp == null ? const Value.absent() : Value(lastKnownIp),
          lastKnownPort: lastKnownPort == null ? const Value.absent() : Value(lastKnownPort),
          deviceType: deviceType == null ? const Value.absent() : Value(deviceType),
          protocolVersion: protocolVersion == null ? const Value.absent() : Value(protocolVersion),

          lastSeenAsHostAt: Value(now),
          firstPairedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// UPGRADED: Safely upserts without destroying the updateCounter
  Future<void> upsertDeviceAsClient({
    required String uuid,
    required String name,
    String? lastKnownIp,
    int? lastKnownPort,
    String? deviceType,
    int? protocolVersion,
  }) async {
    final existing = await (select(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).getSingleOrNull();
    final now = DateTime.now().toUtc();

    if (existing != null) {
      await (update(syncedDevices)..where((t) => t.deviceUuid.equals(uuid))).write(
        SyncedDevicesCompanion.custom(
          deviceName: Variable(name),
          lastKnownIp: lastKnownIp == null ? syncedDevices.lastKnownIp : Variable(lastKnownIp),
          lastKnownPort: lastKnownPort == null ? syncedDevices.lastKnownPort : Variable(lastKnownPort),
          deviceType: deviceType == null ? syncedDevices.deviceType : Variable(deviceType),
          protocolVersion: protocolVersion == null ? syncedDevices.protocolVersion : Variable(protocolVersion),

          lastSeenAsClientAt: Variable(now),
          deletedAt: const Variable(null),

          updatedAt: Variable(now),
          updateCounter: syncedDevices.updateCounter + const Constant(1),
        ),
      );
    } else {
      await into(syncedDevices).insert(
        SyncedDevicesCompanion.insert(
          deviceUuid: uuid,
          deviceName: name,
          lastKnownIp: lastKnownIp == null ? const Value.absent() : Value(lastKnownIp),
          lastKnownPort: lastKnownPort == null ? const Value.absent() : Value(lastKnownPort),
          deviceType: deviceType == null ? const Value.absent() : Value(deviceType),
          protocolVersion: protocolVersion == null ? const Value.absent() : Value(protocolVersion),

          lastSeenAsClientAt: Value(now),
          firstPairedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  // =========================================================================
  // CONNECTION UTILITIES
  // =========================================================================

  /// UPGRADED: Use this query to instantly try reconnecting to past hosts.
  /// Now safely ignores devices you deleted or blocked!
  Future<List<SyncedDevice>> getRecentHostsForFastReconnect() async {
    return (select(syncedDevices)
      ..where((t) => t.lastKnownIp.isNotNull() & t.lastKnownPort.isNotNull())
      ..where((t) => t.lastSeenAsHostAt.isNotNull())
    // SECURITY & SYNC PROTECTIONS
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.blockedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
      ..limit(5))
        .get();
  }

  Future<SyncedDevice?> getMostRecentHost() async {
    return (select(syncedDevices)
      ..where((t) => t.lastSeenAsHostAt.isNotNull())
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.blockedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
      ..limit(1))
        .getSingleOrNull();
  }

  /// Checks if a device UUID already exists in our local pairs history.
  Future<bool> isDeviceKnown(String uuid) async {
    final countExp = syncedDevices.deviceUuid.count();
    final query = selectOnly(syncedDevices)
      ..addColumns([countExp])
      ..where(syncedDevices.deviceUuid.equals(uuid))
      ..where(syncedDevices.deletedAt.isNull()); // Ensure we don't count trashed devices

    final result = await query.map((row) => row.read(countExp)).getSingle();

    return (result ?? 0) > 0;
  }
}