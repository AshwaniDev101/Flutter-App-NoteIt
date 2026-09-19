import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'notes_table.dart';

part 'drift_database.g.dart';

/// Riverpod provider exposing a single, shared instance of [NoteDriftDatabase].
///
/// Automatically binds database lifecycle disposal to Riverpod's [Ref.onDispose],
/// guaranteeing underlying SQLite file locks are cleanly released during app teardown or testing.

final noteDriftDatabaseProvider = Provider((ref) {
  return NoteDriftDatabase();
});


@DriftDatabase(tables: [Notes])
class NoteDriftDatabase extends _$NoteDriftDatabase {
  NoteDriftDatabase()
    : super(
        driftDatabase(
          name: 'my_notes_db',
          // Routes native persistent storage to the application's sandboxed support directory (`AppData` on Windows)
          // to comply with MSIX packaging and avoid OneDrive locking collisions.
          // Without this the 'my_notes_db' will be created in Windows Document folder
          native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),

          web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
        ),
      );

  @override
  int get schemaVersion => 1;

  // STANDARD LOCAL CRUD OPERATIONS =====================

  Future<String> addNote({
    required String title,
    required String content,
    String? creationPlatform,
    String? creationDevice,
  }) async {
    final newUuid = const Uuid().v4();
    await into(notes).insert(
      NotesCompanion.insert(
        uuid: Value(newUuid),
        title: title,
        content: content,
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

  Stream<List<Note>> watchAllNotes() {
    return select(notes).watch();
  }

  Future<Note> getNoteById(String uuid) {
    return (select(notes)..where((t) => t.uuid.equals(uuid))).getSingle();
  }


  Future<bool> updateNote(String uuid, String title, String content) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
      NotesCompanion(
        title: Value(title),
        content: Value(content),
        cloudSyncStatus: const Value(0), // Trigger Cloud Worker
        localSyncStatus: const Value(0), // Trigger Local Worker
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    ) > 0;
  }

  Future<int> deleteNote(String uuid) async {
    // Hard Delete
    return await (delete(notes)..where((t) => t.uuid.equals(uuid))).go();
  }

  Future<void> softDeleteNotes(Iterable<String> uuids, {required String platform}) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
        deletedPlatform: Value(platform),
      ),
    );
  }

  Future<bool> lockNote(String uuid, {required bool isLocked}) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
      NotesCompanion(
        isLocked: Value(isLocked),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    ) > 0;
  }

  // SYNC MANAGER HELPER METHODS

  /// CLOUD PUSH: Get local notes waiting for Firebase
  Future<List<Note>> getPendingCloudNotes() {
    return (select(notes)..where((t) => t.cloudSyncStatus.equals(0))).get();
  }

  /// LOCAL PUSH: Get local notes waiting for Wi-Fi P2P
  Future<List<Note>> getPendingLocalNotes() {
    return (select(notes)..where((t) => t.localSyncStatus.equals(0))).get();
  }

  /// MERGE: Upsert notes pulled down from Firebase OR Local Wi-Fi
  Future<void> upsertNoteFromCloud(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;

    final incomingUpdatedAt = DateTime.fromMillisecondsSinceEpoch(incomingData['updatedAt'] as int, isUtc: true);
    final incomingDeletedAt = incomingData['deletedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(incomingData['deletedAt'] as int, isUtc: true)
        : null;

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),
      isPinned: Value(incomingData['isPinned'] as bool? ?? false),
      isArchived: Value(incomingData['isArchived'] as bool? ?? false),
      isLocked: Value(incomingData['isLocked'] as bool? ?? false),
      position: Value(incomingData['position'] as int? ?? 0),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),
      deletedAt: Value(incomingDeletedAt),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(DateTime.fromMillisecondsSinceEpoch(incomingData['reminderAt'] as int, isUtc: true))
          : const Value.absent(),
      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch(incomingData['createdAt'] as int, isUtc: true)),

      // CRITICAL: Since this came from the network, mark it as synced for the network that received it.
      // But leave the other status as 0 so it passes the data along!
      cloudSyncStatus: const Value(1),
      localSyncStatus: const Value(0),
    );

    final existingNote = await (select(notes)..where((t) => t.uuid.equals(incomingUuid))).getSingleOrNull();

    if (existingNote != null) {
      if (incomingUpdatedAt.isAfter(existingNote.updatedAt)) {
        // Network version is newer. Overwrite local.
        await (update(notes)..where((t) => t.uuid.equals(incomingUuid))).write(noteCompanion);
      } else {
        print("Drift: Ignored older incoming data for note $incomingUuid. Local is newer.");
      }
    } else {
      // Note doesn't exist locally, insert it.
      await into(notes).insert(noteCompanion);
    }
  }


  /// CONFIRM CLOUD: Mark notes as successfully pushed to Firebase
  Future<void> markAsCloudSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      const NotesCompanion(cloudSyncStatus: Value(1)),
    );
  }


  /// MERGE: Upsert notes pulled down from Local Wi-Fi
  Future<void> upsertNoteFromLocal(Map<String, dynamic> incomingData) async {
    final incomingUuid = incomingData['uuid'] as String;

    final incomingUpdatedAt = DateTime.fromMillisecondsSinceEpoch(incomingData['updatedAt'] as int, isUtc: true);
    final incomingDeletedAt = incomingData['deletedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(incomingData['deletedAt'] as int, isUtc: true)
        : null;

    final noteCompanion = NotesCompanion(
      uuid: Value(incomingUuid),
      title: Value(incomingData['title'] as String),
      content: Value(incomingData['content'] as String),
      color: Value(incomingData['color'] as int? ?? 0xFFFFFFFF),
      isPinned: Value(incomingData['isPinned'] as bool? ?? false),
      isArchived: Value(incomingData['isArchived'] as bool? ?? false),
      isLocked: Value(incomingData['isLocked'] as bool? ?? false),
      position: Value(incomingData['position'] as int? ?? 0),
      tags: Value(incomingData['tags'] as String?),
      creationPlatform: Value(incomingData['creationPlatform'] as String?),
      creationDevice: Value(incomingData['creationDevice'] as String?),
      deletedAt: Value(incomingDeletedAt),
      reminderAt: incomingData['reminderAt'] != null
          ? Value(DateTime.fromMillisecondsSinceEpoch(incomingData['reminderAt'] as int, isUtc: true))
          : const Value.absent(),
      updatedAt: Value(incomingUpdatedAt),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch(incomingData['createdAt'] as int, isUtc: true)),

      // INVERTED: Came from Wi-Fi, so mark local synced, but leave cloud pending!
      cloudSyncStatus: const Value(0),
      localSyncStatus: const Value(1),
    );

    final existingNote = await (select(notes)..where((t) => t.uuid.equals(incomingUuid))).getSingleOrNull();

    if (existingNote != null) {
      if (incomingUpdatedAt.isAfter(existingNote.updatedAt)) {
        await (update(notes)..where((t) => t.uuid.equals(incomingUuid))).write(noteCompanion);
      }
    } else {
      await into(notes).insert(noteCompanion);
    }
  }


  /// CONFIRM LOCAL: Mark notes as successfully pushed over Wi-Fi
  Future<void> markAsLocalSynced(Iterable<String> uuids) async {
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      const NotesCompanion(localSyncStatus: Value(1)),
    );
  }

  // TRASH PAGE METHODS  ----------------------------------------

  /// VIEW TRASH: Watch only notes that have a deletedAt timestamp
  Stream<List<Note>> watchTrashNotes() {
    return (select(notes)
      ..where((t) => t.deletedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<bool> restoreNote(String uuid) async {
    return await (update(notes)..where((t) => t.uuid.equals(uuid))).write(
      NotesCompanion(
        deletedAt: const Value(null),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    ) > 0;
  }

  /// EMPTY TRASH: Hard delete all trashed notes and return their UUIDs to delete them from Firebase
  Future<List<String>> emptyLocalTrash() async {
    final trashedNotes = await (select(notes)..where((t) => t.deletedAt.isNotNull())).get();

    final uuidsToDelete = trashedNotes.map((note) => note.uuid).toList();

    final deletedCount = await (delete(notes)..where((t) => t.deletedAt.isNotNull())).go();
    print("Drift: Emptied $deletedCount notes from local trash.");

    return uuidsToDelete;
  }
}