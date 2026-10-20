import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/helpers/time_helper.dart';
import '../local_database.dart';
import 'folders_table.dart';
import '../notes/notes_table.dart';

part 'folders_dao.g.dart';

final foldersDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).foldersDao);

class FolderWithCount {
  final Folder folder;
  final int noteCount;

  FolderWithCount({required this.folder, required this.noteCount});
}

@DriftAccessor(tables: [Folders, Notes])
class FoldersDao extends DatabaseAccessor<LocalDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  Future<String> addFolder({
    required String name,
    int colorIndex = 0,
    String? creationPlatform,
    String? creationDevice,
  }) async {
    final newUuid = const Uuid().v4();
    await into(folders).insert(
      FoldersCompanion.insert(
        uuid: Value(newUuid),
        name: name,
        colorIndex: Value(colorIndex),
        creationPlatform: Value(creationPlatform),
        creationDevice: Value(creationDevice),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
      ),
    );
    return newUuid;
  }

  Future<bool> updateFolder({
    required String uuid,
    required String name,
    int? colorIndex,
  }) async {
    return await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
      FoldersCompanion.custom(
        name: Variable(name),
        colorIndex: colorIndex != null ? Variable<int>(colorIndex) : null,
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: folders.updateCounter + const Constant(1),
      ),
    ) > 0;
  }


  Future<void> toggleFolderPinStatus(String uuid) async {
    await transaction(() async {
      final targetFolder = await (select(folders)..where((t) => t.uuid.equals(uuid))).getSingle();
      final newPinnedState = targetFolder.pinnedAt == null ? DateTime.now().toUtc() : null;

      await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
        FoldersCompanion.custom(
          pinnedAt: Variable(newPinnedState),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(DateTime.now().toUtc()),
          updateCounter: folders.updateCounter + const Constant(1),
        ),
      );
    });
  }

  Stream<List<FolderWithCount>> watchActiveFoldersWithCounts() {
    final amountOfNotes = notes.uuid.count();

    final query = select(folders).join([
      leftOuterJoin(
        notes,
        notes.folderId.equalsExp(folders.uuid) & notes.deletedAt.isNull() & notes.archivedAt.isNull(),
      ),
    ]);

    query
      ..where(folders.deletedAt.isNull())
      ..addColumns([amountOfNotes])
      ..groupBy([folders.uuid])
      ..orderBy([
        OrderingTerm(expression: folders.pinnedAt, mode: OrderingMode.desc, nulls: NullsOrder.last),
        OrderingTerm(expression: folders.name.collate(Collate.noCase), mode: OrderingMode.asc)
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return FolderWithCount(
          folder: row.readTable(folders),
          noteCount: row.read(amountOfNotes) ?? 0,
        );
      }).toList();
    });
  }

  Future<void> softDeleteFolder(String uuid, {required String platform}) async {
    await transaction(() async {
      await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
        FoldersCompanion.custom(
          deletedAt: Variable(DateTime.now().toUtc()),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(DateTime.now().toUtc()),
          deletedPlatform: Variable(platform),
          updateCounter: folders.updateCounter + const Constant(1),
        ),
      );

      await (update(notes)..where((t) => t.folderId.equals(uuid))).write(
        NotesCompanion.custom(
          folderId: const Variable(null),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(DateTime.now().toUtc()),
          updateCounter: notes.updateCounter + const Constant(1),
        ),
      );
    });
  }

  DateTime? _parseNetworkTimestamp(dynamic timestamp) => TimeHelper.parseToUtcDateTime(timestamp);

  // =========================================================================
  // SYNC HELPER METHODS
  // =========================================================================

  Future<List<Folder>> getPendingCloudFolders() {
    return (select(folders)..where((t) => t.cloudSyncStatus.equals(0))).get();
  }

  Future<List<Folder>> getPendingLocalFolders() {
    return (select(folders)..where((t) => t.localSyncStatus.equals(0))).get();
  }

  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    if (uuids.isEmpty) return;
    await (update(folders)..where((t) => t.uuid.isIn(uuids)))
        .write(const FoldersCompanion(cloudSyncStatus: Value(1)));
  }

  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    if (uuids.isEmpty) return;
    await (update(folders)..where((t) => t.uuid.isIn(uuids)))
        .write(const FoldersCompanion(localSyncStatus: Value(1)));
  }

  Future<void> upsertFolderFromLocal(Map<String, dynamic> incomingData) async {
    await _upsertFolder(incomingData, isCloud: false);
  }

  Future<void> upsertFolderFromCloud(Map<String, dynamic> incomingData) async {
    await _upsertFolder(incomingData, isCloud: true);
  }

  Future<void> _upsertFolder(Map<String, dynamic> incomingData, {required bool isCloud}) async {
    final incomingUuid = incomingData['uuid'] as String;
    final incomingUpdatedAt = _parseNetworkTimestamp(incomingData['updatedAt']) ?? DateTime.now().toUtc();

    final companion = FoldersCompanion(
      uuid: Value(incomingUuid),
      name: Value(incomingData['name'] as String),
      colorIndex: Value(incomingData['colorIndex'] as int? ?? 0),
      ownerUid: Value(incomingData['ownerUid'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),
      lastEditedPlatform: Value(incomingData['lastEditedPlatform'] as String?),
      lastEditedDevice: Value(incomingData['lastEditedDevice'] as String?),
      deletedPlatform: Value(incomingData['deletedPlatform'] as String?),
      deletedDevice: Value(incomingData['deletedDevice'] as String?),
      deletedAt: Value(_parseNetworkTimestamp(incomingData['deletedAt'])),
      pinnedAt: Value(_parseNetworkTimestamp(incomingData['pinnedAt'])),
      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(_parseNetworkTimestamp(incomingData['createdAt']) ?? DateTime.now().toUtc()),
      updateCounter: Value(incomingData['updateCounter'] as int? ?? 1),
      cloudSyncStatus: Value(isCloud ? 1 : 0),
      localSyncStatus: Value(isCloud ? 0 : 1),
    );

    final existingFolder = await (select(folders)..where((t) => t.uuid.equals(incomingUuid))).getSingleOrNull();

    if (existingFolder != null) {
      if (incomingUpdatedAt.isAfter(existingFolder.updatedAt)) {
        await (update(folders)..where((t) => t.uuid.equals(incomingUuid))).write(companion);
      }
    } else {
      await into(folders).insert(companion);
    }
  }

  Future<List<Folder>> getAllFolders() async {
    return await select(folders).get();
  }

  Future<void> importFolders(List<Folder> importedFolders) async {
    if (importedFolders.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(folders, importedFolders);
    });
  }

  Stream<List<Folder>> watchTrashFolders() {
    return (select(folders)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<bool> restoreFolder(String uuid) async {
    return await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
          FoldersCompanion.custom(
            deletedAt: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(DateTime.now().toUtc()),
            updateCounter: folders.updateCounter + const Constant(1),
          ),
        ) >
        0;
  }

  Future<int> hardDeleteFolder(String uuid) async {
    return await (delete(folders)..where((t) => t.uuid.equals(uuid))).go();
  }

  Future<List<String>> emptyLocalFolderTrash() async {
    final trashedFolders = await (select(folders)..where((t) => t.deletedAt.isNotNull())).get();
    final uuidsToDelete = trashedFolders.map((f) => f.uuid).toList();
    await (delete(folders)..where((t) => t.deletedAt.isNotNull())).go();
    return uuidsToDelete;
  }
}