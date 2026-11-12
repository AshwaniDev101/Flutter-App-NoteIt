import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/helpers/time_helper.dart';
import '../../../core/util/hlc.dart';
import '../../../core/util/logger.dart';
import '../../shared_preference/shared_preference_manager.dart';
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

  String _generateHlc({int counter = 1, DateTime? lastKnownTime}) {
    final deviceId = SharedPreferenceManager.instance.hostUuid;
    return Hlc.generate(
      deviceId: deviceId,
      counter: counter,
      lastKnownTime: lastKnownTime,
    );
  }

  Future<String> addFolder({
    required String name,
    int colorIndex = 0,
    String? creationPlatform,
    String? creationDevice,
  }) async {
    final newUuid = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final initialHlc = _generateHlc(counter: 1, lastKnownTime: now);

    await into(folders).insert(
      FoldersCompanion.insert(
        uuid: Value(newUuid),
        name: name,
        colorIndex: Value(colorIndex),
        creationPlatform: Value(creationPlatform),
        creationDevice: Value(creationDevice),
        createdAt: Value(now),
        updatedAt: Value(now),
        updateCounter: const Value(1),
        hlc: Value(initialHlc),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
      ),
    );
    AppLogger.d("FoldersDao: Added new folder '$name' (uuid: $newUuid)");
    return newUuid;
  }

  Future<bool> updateFolder({
    required String uuid,
    required String name,
    int? colorIndex,
  }) async {
    return await transaction(() async {
      final existing = await (select(folders)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      final success = await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
        FoldersCompanion.custom(
          name: Variable(name),
          colorIndex: colorIndex != null ? Variable<int>(colorIndex) : null,
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(now),
          updateCounter: Variable(newCounter),
          hlc: Variable(newHlc),
        ),
      ) > 0;
      if (success) {
        AppLogger.d("FoldersDao: Updated folder '$name' (uuid: $uuid)");
      }
      return success;
    });
  }

  Future<void> toggleFolderPinStatus(String uuid) async {
    await transaction(() async {
      final targetFolder = await (select(folders)..where((t) => t.uuid.equals(uuid))).getSingle();
      final newPinnedState = targetFolder.pinnedAt == null ? DateTime.now().toUtc() : null;
      final newCounter = targetFolder.updateCounter + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
        FoldersCompanion.custom(
          pinnedAt: Variable(newPinnedState),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(now),
          updateCounter: Variable(newCounter),
          hlc: Variable(newHlc),
        ),
      );
      AppLogger.d("FoldersDao: Toggled pin status for folder '$uuid' (pinned: ${newPinnedState != null})");
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
      final targetFolder = await (select(folders)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final now = DateTime.now().toUtc();
      final newFolderCounter = (targetFolder?.updateCounter ?? 0) + 1;
      final newFolderHlc = _generateHlc(counter: newFolderCounter, lastKnownTime: now);

      await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
        FoldersCompanion.custom(
          deletedAt: Variable(now),
          cloudSyncStatus: const Variable(0),
          localSyncStatus: const Variable(0),
          updatedAt: Variable(now),
          deletedPlatform: Variable(platform),
          updateCounter: Variable(newFolderCounter),
          hlc: Variable(newFolderHlc),
        ),
      );

      final affectedNotes = await (select(notes)..where((t) => t.folderId.equals(uuid))).get();
      for (final note in affectedNotes) {
        final newNoteCounter = note.updateCounter + 1;
        final newNoteHlc = _generateHlc(counter: newNoteCounter, lastKnownTime: now);

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            folderId: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(now),
            updateCounter: Variable(newNoteCounter),
            hlc: Variable(newNoteHlc),
          ),
        );
      }
      AppLogger.d("FoldersDao: Soft-deleted folder '$uuid' and unassigned ${affectedNotes.length} notes.");
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

  /// HLC DELTA SYNC: Get all active or tombstoned folders modified since [lastSyncedHlc].
  /// If [lastSyncedHlc] is null (e.g. brand new device), returns all folders for initial sync.
  Future<List<Folder>> getFoldersModifiedSince(String? lastSyncedHlc) {
    if (lastSyncedHlc == null || lastSyncedHlc.isEmpty) {
      return select(folders).get();
    }
    return (select(folders)..where((t) => t.hlc.isBiggerThan(Variable(lastSyncedHlc)))).get();
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

  /// Determines if an incoming folder payload should overwrite the local folder using HLC-First LWW precedence.
  bool _shouldOverwriteLocalFolder({
    required int incomingUpdateCounter,
    required DateTime incomingUpdatedAt,
    required String? incomingHlc,
    required Folder existingFolder,
  }) {
    // 1. Primary rule: HLC string comparison if both records have valid HLCs
    if (incomingHlc != null && incomingHlc.isNotEmpty && existingFolder.hlc != null && existingFolder.hlc!.isNotEmpty) {
      final hlcComparison = Hlc.compareStrings(incomingHlc, existingFolder.hlc);
      if (hlcComparison != 0) {
        return hlcComparison > 0;
      }
    }

    // 2. Secondary rule: Compare updateCounters
    if (incomingUpdateCounter != existingFolder.updateCounter) {
      return incomingUpdateCounter > existingFolder.updateCounter;
    }

    // 3. Fallback rule: Compare UTC timestamps
    if (incomingUpdatedAt.millisecondsSinceEpoch != existingFolder.updatedAt.millisecondsSinceEpoch) {
      return incomingUpdatedAt.isAfter(existingFolder.updatedAt);
    }

    // 4. Tie-breaker: If counter, HLC, and timestamp are identical, preserve local version
    return false;
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
      hlc: Value(incomingData['hlc'] as String?),
      cloudSyncStatus: Value(isCloud ? 1 : 0),
      localSyncStatus: Value(isCloud ? 0 : 1),
    );

    final existingFolder = await (select(folders)..where((t) => t.uuid.equals(incomingUuid))).getSingleOrNull();

    final sourceLabel = isCloud ? 'cloud' : 'local';

    if (existingFolder != null) {
      final incomingUpdateCounter = incomingData['updateCounter'] as int? ?? companion.updateCounter.value;
      final incomingHlc = companion.hlc.value;

      if (_shouldOverwriteLocalFolder(
        incomingUpdateCounter: incomingUpdateCounter,
        incomingUpdatedAt: incomingUpdatedAt,
        incomingHlc: incomingHlc,
        existingFolder: existingFolder,
      )) {
        await (update(folders)..where((t) => t.uuid.equals(incomingUuid))).write(companion);
        AppLogger.d("FoldersDao: Overwrote local folder $incomingUuid ('${incomingData['name']}') with newer incoming $sourceLabel network data.");
      } else {
        AppLogger.d("FoldersDao: Ignored older/equal incoming $sourceLabel data for folder $incomingUuid ('${incomingData['name']}'). Local is newer.");
      }
    } else {
      await into(folders).insert(companion);
      AppLogger.d("FoldersDao: Inserted new folder $incomingUuid ('${incomingData['name']}') from $sourceLabel network.");
    }

    // If folder is soft-deleted, unassign any local notes referencing this folder
    if (companion.deletedAt.present && companion.deletedAt.value != null) {
      final affectedNotes = await (select(notes)..where((t) => t.folderId.equals(incomingUuid))).get();
      for (final note in affectedNotes) {
        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          const NotesCompanion(folderId: Value(null)),
        );
      }
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
    return await transaction(() async {
      final existing = await (select(folders)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
      final newCounter = (existing?.updateCounter ?? 0) + 1;
      final now = DateTime.now().toUtc();
      final newHlc = _generateHlc(counter: newCounter, lastKnownTime: now);

      return await (update(folders)..where((t) => t.uuid.equals(uuid))).write(
            FoldersCompanion.custom(
              deletedAt: const Variable(null),
              cloudSyncStatus: const Variable(0),
              localSyncStatus: const Variable(0),
              updatedAt: Variable(now),
              updateCounter: Variable(newCounter),
              hlc: Variable(newHlc),
            ),
          ) >
          0;
    });
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
