import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/device_pairs/pairs_table.dart';

import '../local_database.dart';

part 'device_pairs_dao.g.dart';

final devicePairsDaoProvider = Provider(
  (ref) => ref.watch(localDatabaseProvider).devicePairsDao,
);

@DriftAccessor(tables: [DevicePairs])
class DevicePairsDao extends DatabaseAccessor<LocalDatabase>
    with _$DevicePairsDaoMixin {
  DevicePairsDao(super.db);

  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  Future<void> upsertDeviceAsHost({
    required String uuid,
    required String name,
  }) async {
    await into(devicePairs).insertOnConflictUpdate(
      DevicePairsCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        lastSeenAsHostAt: Value(DateTime.now()),
      ),
    );
  }
  // LOCAL SYNC: DEVICE PAIRS (P2P HISTORY)
  Future<void> upsertDeviceAsClient({
    required String uuid,
    required String name,
  }) async {
    await into(devicePairs).insertOnConflictUpdate(
      DevicePairsCompanion(
        deviceUuid: Value(uuid),
        deviceName: Value(name),
        // Update a client timestamp, or just save the device if you don't have this column
        lastSeenAsClientAt: Value(DateTime.now()),
      ),
    );
  }

  Future<DevicePair?> getMostRecentHost() async {
    return (select(devicePairs)
          ..where((t) => t.lastSeenAsHostAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Checks if a device UUID already exists in our local pairs history.
  Future<bool> isDeviceKnown(String uuid) async {
    final existingDevice = await (select(devicePairs)
      ..where((t) => t.deviceUuid.equals(uuid)))
        .getSingleOrNull();

    return existingDevice != null; // Returns true if found, false if unknown
  }
}
