import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/util/logger.dart';
import '../local_database.dart';
import 'notes_table.dart';

part 'notes_dao.g.dart';

final notesDaoProvider = Provider((ref) => ref.watch(localDatabaseProvider).notesDao);

/// Database sorting options for active notes query
enum NoteSortPreference { name, createdAt, updatedAt }

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<LocalDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // =========================================================================
  // STANDARD LOCAL CRUD OPERATIONS
  // =========================================================================

  Future<String> addNote({
    required String title,
    required String content,
    String? folderId,
    String? creationPlatform,
    String? creationDevice,
    required int contentVersion,
  }) async {
    final newUuid = const Uuid().v4();
    await into(notes).insert(
      NotesCompanion.insert(
        uuid: Value(newUuid),
        title: title,
        content: content,
        folderId: Value(folderId),
        creationPlatform: Value(creationPlatform),
        creationDevice: Value(creationDevice),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        contentVersion: Value(contentVersion),
      ),
    );
    return newUuid;
  }

  Future<bool> updateNote({
    required String uuid,
    required String title,
    required String content,
    required int contentVersion,
  }) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
          NotesCompanion.custom(
            title: Variable(title),
            content: Variable(content),
            cloudSyncStatus: const Variable(0),
            // Trigger Cloud Worker
            localSyncStatus: const Variable(0),
            // Trigger Local Worker
            updatedAt: Variable(DateTime.now().toUtc()),
            updateCounter: notes.updateCounter + const Constant(1),
            contentVersion: Variable(contentVersion),
          ),
        ) >
        0;
  }

  Stream<List<Note>> watchAllNotes() {
    return select(notes).watch();
  }

  /// Watches active (non-deleted, non-archived) notes sorted directly by SQLite:
  /// 1. Pinned notes first (pinnedAt IS NOT NULL), sorted by pinnedAt timestamp descending.
  /// 2. Unpinned notes sorted according to [sortOption] (name, createdAt, or updatedAt).
  Stream<List<Note>> watchSortedNotes(NoteSortPreference sortOption) {
    return (select(notes)
          ..where((t) => t.deletedAt.isNull() & t.archivedAt.isNull())
          ..orderBy([
            // Pinned notes first (pinnedAt != null), newest pinned first
            (t) => OrderingTerm(expression: t.pinnedAt, mode: OrderingMode.desc, nulls: NullsOrder.last),
            // Secondary sort choice
            (t) {
              switch (sortOption) {
                case NoteSortPreference.name:
                  return OrderingTerm(expression: t.title.collate(Collate.noCase), mode: OrderingMode.asc);
                case NoteSortPreference.createdAt:
                  return OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc);
                case NoteSortPreference.updatedAt:
                  return OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc);
              }
            },
          ]))
        .watch();
  }

  Future<Note> getNoteById(String uuid) {
    return (select(notes)..where((t) => t.uuid.equals(uuid))).getSingle();
  }

  Future<int> deleteNote(String uuid) async {
    // Hard Delete
    return await (delete(notes)..where((t) => t.uuid.equals(uuid))).go();
  }

  Future<void> softDeleteNotes(Iterable<String> uuids, {required String platform}) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion.custom(
        deletedAt: Variable(DateTime.now().toUtc()),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        deletedPlatform: Variable(platform),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  /// Updates only the folder assignment of a note and triggers sync workers
  Future<bool> updateNoteFolder(String uuid, String? folderId) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
      NotesCompanion.custom(
        folderId: Variable(folderId),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1), // Crucial for conflict resolution
      ),
    ) > 0;
  }

  Future<bool> lockNote(String uuid, {required bool isLocked}) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
          NotesCompanion.custom(
            // Set timestamp if locked, null if unlocked
            lockedAt: Variable(isLocked ? DateTime.now().toUtc() : null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(DateTime.now().toUtc()),
            updateCounter: notes.updateCounter + const Constant(1),
          ),
        ) >
        0;
  }

  Future<int> unlockAllNotes() async {
    return await (update(notes)..where((t) => t.lockedAt.isNotNull())).write(
      NotesCompanion.custom(
        lockedAt: const Variable(null),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  // =========================================================================
  // SYNC MANAGER HELPER METHODS
  // =========================================================================

  /// CLOUD PUSH: Get local notes waiting for Firebase
  Future<List<Note>> getPendingCloudNotes() {
    return (select(notes)..where((t) => t.cloudSyncStatus.equals(0))).get();
  }

  /// LOCAL PUSH: Get local notes waiting for Wi-Fi P2P
  Future<List<Note>> getPendingLocalNotes() {
    return (select(notes)..where((t) => t.localSyncStatus.equals(0))).get();
  }

  /// Helper to safely parse incoming network timestamps
  DateTime? _parseNetworkTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp as int, isUtc: true);
  }

  /// MERGE: Upsert notes pulled down from Firebase OR Local Wi-Fi
  Future<void> upsertNoteFromCloud(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;
    final incomingUpdatedAt = _parseNetworkTimestamp(incomingData['updatedAt'])!;

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),

      // UX Timestamps parsed from network payload
      pinnedAt: Value(_parseNetworkTimestamp(incomingData['pinnedAt'])),
      archivedAt: Value(_parseNetworkTimestamp(incomingData['archivedAt'])),
      lockedAt: Value(_parseNetworkTimestamp(incomingData['lockedAt'])),

      folderId: Value(incomingData['folderId'] as String?),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),

      deletedAt: Value(_parseNetworkTimestamp(incomingData['deletedAt'])),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(_parseNetworkTimestamp(incomingData['reminderAt'])!)
          : const Value.absent(),

      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(_parseNetworkTimestamp(incomingData['createdAt'])!),

      // Apply the network's conflict resolver counter
      updateCounter: Value(incomingData['updateCounter'] as int? ?? 1),

      // CRITICAL: Mark synced for Cloud, but keep pending for Local Wi-Fi
      cloudSyncStatus: const Value(1),
      localSyncStatus: const Value(0),
    );

    await _executeUpsert(incomingUuid, incomingUpdatedAt, noteCompanion);
  }

  /// MERGE: Upsert notes pulled down from Local Wi-Fi
  Future<void> upsertNoteFromLocal(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;
    final incomingUpdatedAt = _parseNetworkTimestamp(incomingData['updatedAt'])!;

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),

      pinnedAt: Value(_parseNetworkTimestamp(incomingData['pinnedAt'])),
      archivedAt: Value(_parseNetworkTimestamp(incomingData['archivedAt'])),
      lockedAt: Value(_parseNetworkTimestamp(incomingData['lockedAt'])),

      folderId: Value(incomingData['folderId'] as String?),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),

      deletedAt: Value(_parseNetworkTimestamp(incomingData['deletedAt'])),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(_parseNetworkTimestamp(incomingData['reminderAt'])!)
          : const Value.absent(),

      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(_parseNetworkTimestamp(incomingData['createdAt'])!),
      updateCounter: Value(incomingData['updateCounter'] as int? ?? 1),

      // INVERTED: Mark synced for Local Wi-Fi, but keep pending for Cloud
      cloudSyncStatus: const Value(0),
      localSyncStatus: const Value(1),
    );

    await _executeUpsert(incomingUuid, incomingUpdatedAt, noteCompanion);
  }

  /// Private helper to handle the actual write logic for upserts
  Future<void> _executeUpsert(String uuid, DateTime incomingUpdatedAt, NotesCompanion companion) async {
    final existingNote = await (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

    if (existingNote != null) {
      if (incomingUpdatedAt.isAfter(existingNote.updatedAt)) {
        // Network version is newer. Overwrite local.
        await (update(notes)..where((t) => t.uuid.equals(uuid))).write(companion);
      } else {
        AppLogger.d("NotesDao: Ignored older incoming data for note $uuid. Local is newer.");
      }
    } else {
      // Note doesn't exist locally, insert it.
      await into(notes).insert(companion);
    }
  }

  /// CONFIRM CLOUD: Mark notes as successfully pushed to Firebase
  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(const NotesCompanion(cloudSyncStatus: Value(1)));
  }

  /// CONFIRM LOCAL: Mark notes as successfully pushed over Wi-Fi
  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(const NotesCompanion(localSyncStatus: Value(1)));
  }

  // =========================================================================
  // TRASH PAGE METHODS
  // =========================================================================

  /// VIEW TRASH: Watch only notes that have a deletedAt timestamp
  Stream<List<Note>> watchTrashNotes() {
    return (select(notes)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<bool> restoreNote(String uuid) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
          NotesCompanion.custom(
            deletedAt: const Variable(null),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(DateTime.now().toUtc()),
            updateCounter: notes.updateCounter + const Constant(1),
          ),
        ) >
        0;
  }

  /// EMPTY TRASH: Hard delete all trashed notes and return their UUIDs
  Future<List<String>> emptyLocalTrash() async {
    final trashedNotes = await (select(notes)..where((t) => t.deletedAt.isNotNull())).get();
    final uuidsToDelete = trashedNotes.map((note) => note.uuid).toList();

    final deletedCount = await (delete(notes)..where((t) => t.deletedAt.isNotNull())).go();
    AppLogger.d("NotesDao: Emptied $deletedCount notes from local trash.");

    return uuidsToDelete;
  }

  Future<void> importNotes(List<Note> importedNotes) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(notes, importedNotes);
    });
  }

  // =========================================================================
  // BATCH ACTIONS (PIN, ARCHIVE, FETCH, DUPLICATE)
  // =========================================================================

  /// Sets the pin status for multiple notes
  Future<void> setNotesPinStatus(Iterable<String> uuids, {required bool isPinned}) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion.custom(
        pinnedAt: Variable(isPinned ? DateTime.now().toUtc() : null),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  /// Toggles the pin status for multiple notes (Resolved TODO)
  Future<void> togglePinStatus(Iterable<String> uuids) async {
    // Because we are conditionally changing a DateTime rather than just flipping a boolean,
    // wrapping this in a transaction ensures it happens safely and instantly.
    await transaction(() async {
      final targetNotes = await (select(notes)..where((t) => t.uuid.isIn(uuids))).get();

      for (final note in targetNotes) {
        final newPinnedState = note.pinnedAt == null ? DateTime.now().toUtc() : null;

        await (update(notes)..where((t) => t.uuid.equals(note.uuid))).write(
          NotesCompanion.custom(
            pinnedAt: Variable(newPinnedState),
            cloudSyncStatus: const Variable(0),
            localSyncStatus: const Variable(0),
            updatedAt: Variable(DateTime.now().toUtc()),
            updateCounter: notes.updateCounter + const Constant(1),
          ),
        );
      }
    });
  }

  /// Archives multiple notes
  Future<void> archiveNotes(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion.custom(
        archivedAt: Variable(DateTime.now().toUtc()),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  /// UNARCHIVE: Helper to restore notes back to the main home screen
  Future<void> unarchiveNotes(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion.custom(
        archivedAt: const Variable(null),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  /// VIEW ARCHIVE: Watch only notes that are archived and not in the trash
  Stream<List<Note>> watchArchivedNotes() {
    return (select(notes)
          ..where((t) => t.archivedAt.isNotNull()) // Replaced boolean check
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Fetches specific notes (Used for duplication)
  Future<List<Note>> getNotesByUuids(Iterable<String> uuids) {
    return (select(notes)..where((t) => t.uuid.isIn(uuids))).get();
  }

  /// Inserts multiple notes at once (Used for duplication)
  Future<void> insertMultipleNotes(List<NotesCompanion> newNotes) async {
    await batch((batch) {
      batch.insertAll(notes, newNotes);
    });
  }

  /// RESTORE BATCH: Restores multiple notes from the trash
  Future<void> restoreNotesBatch(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion.custom(
        deletedAt: const Variable(null),
        cloudSyncStatus: const Variable(0),
        localSyncStatus: const Variable(0),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: notes.updateCounter + const Constant(1),
      ),
    );
  }

  /// HARD DELETE BATCH: Permanently deletes specific notes (Returns UUIDs for Firebase sync)
  Future<List<String>> hardDeleteNotesBatch(Iterable<String> uuids) async {
    await (delete(notes)..where((t) => t.uuid.isIn(uuids))).go();
    return uuids.toList();
  }
}
