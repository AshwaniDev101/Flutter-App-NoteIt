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

  Future<DevicePair?> getMostRecentHost() async {
    return (select(devicePairs)
          ..where((t) => t.lastSeenAsHostAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastSeenAsHostAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
