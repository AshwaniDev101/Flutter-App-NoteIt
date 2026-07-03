import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notes_table.dart';

part 'drift_database.g.dart';

// Drift database location Windows : C:\Users\Ashwin\Documents\my_notes_db.sqlite

final noteDriftDatabaseProvider = Provider((ref) {
  return NoteDriftDatabase();
});

@DriftDatabase(tables: [Notes])
class NoteDriftDatabase extends _$NoteDriftDatabase {

  NoteDriftDatabase()
      : super(
    driftDatabase(
      name: 'my_notes_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  // STANDARD LOCAL CRUD OPERATIONS

  Future<int> addNote({
    required String title,
    required String content,
    String? creationPlatform,
    String? creationDevice,
  }) async {
    return await into(notes).insert(
      NotesCompanion.insert(
        title: title,
        content: content,
        creationPlatform: Value(creationPlatform),
        creationDevice: Value(creationDevice),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Stream<List<Note>> watchAllNotes() {
    return select(notes).watch();
  }

  Future<Note> getNoteById(int id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<bool> updateNote(int id, String title, String content) async {
    return await (update(notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          title: Value(title),
          content: Value(content),
          syncStatus: const Value(0), // Trigger the SyncManager
          updatedAt: Value(DateTime.now().toUtc()), // Enforce UTC
        )
    ) > 0;
  }

  Future<int> deleteNote(int id) async {
    // This is the "Hard Delete"
    return await (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> softDeleteNotes(Iterable<int> ids) async {
    // This is the "Soft Delete" used by the UI
    await (update(notes)..where((t) => t.id.isIn(ids))).write(
      NotesCompanion(
        // NEW: Swapped boolean for UTC Timestamp
        deletedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }



  Future<bool> lockNote(int id, {required bool isLocked}) async {
    return await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isLocked: Value(isLocked),
        syncStatus: const Value(0),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    ) > 0;
  }

  // SYNC MANAGER HELPER METHODS

  /// PUSH: Get all local notes waiting to be pushed to Firebase
  Future<List<Note>> getPendingNotes() {
    return (select(notes)..where((t) => t.syncStatus.equals(0))).get();
  }

  /// MERGE: Upsert (Update or Insert) notes pulled down from Firebase
  Future<void> upsertNoteFromCloud(Map<String, dynamic> cloudNote, String firestoreId) async {
    // Parse the cloud timestamps
    final cloudUpdatedAt = DateTime.fromMillisecondsSinceEpoch(cloudNote['updatedAt'] as int, isUtc: true);
    final cloudDeletedAt = cloudNote['deletedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(cloudNote['deletedAt'] as int, isUtc: true)
        : null;

    final noteCompanion = NotesCompanion(
      title: Value(cloudNote['title'] as String),
      content: Value(cloudNote['content'] as String),
      color: Value(cloudNote['color'] as int? ?? 0xFFFFFFFF),
      isPinned: Value(cloudNote['isPinned'] as bool? ?? false),
      isArchived: Value(cloudNote['isArchived'] as bool? ?? false),
      isLocked: Value(cloudNote['isLocked'] as bool? ?? false),
      position: Value(cloudNote['position'] as int? ?? 0),
      tags: Value(cloudNote['tags'] as String?),
      creationPlatform: Value(cloudNote['creationPlatform'] as String?),
      creationDevice: Value(cloudNote['creationDevice'] as String?),
      deletedAt: Value(cloudDeletedAt),
      syncStatus: const Value(1), // Already synced!
      firestoreId: Value(firestoreId),
      reminderAt: cloudNote['reminderAt'] != null
          ? Value(DateTime.fromMillisecondsSinceEpoch(cloudNote['reminderAt'] as int, isUtc: true))
          : const Value.absent(),
      updatedAt: Value(cloudUpdatedAt),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch(cloudNote['createdAt'] as int, isUtc: true)),
    );

    // Fetch the existing local note
    final existingNote = await (select(notes)..where((t) => t.firestoreId.equals(firestoreId))).getSingleOrNull();

    if (existingNote != null) {
      // CONFLICT RESOLUTION: Compare timestamps
      if (cloudUpdatedAt.isAfter(existingNote.updatedAt ?? existingNote.createdAt)) {
        // The cloud version is newer. Safe to overwrite local.
        await (update(notes)..where((t) => t.id.equals(existingNote.id))).write(noteCompanion);
      } else {
        // The local version is newer!
        // Do nothing. The local note retains its syncStatus == 0 and will be pushed to Firebase on the next batch.
        print("SyncManager: Ignored older cloud data for note ${existingNote.id}. Local is newer.");
      }
    } else {
      // Note doesn't exist locally, so insert it.
      await into(notes).insert(noteCompanion);
    }
  }

  /// CONFIRM: Mark local notes as successfully pushed to Firebase
  Future<void> markAsSynced(Iterable<int> localIds, Map<int, String> newFirestoreIds) async {
    await transaction(() async {
      for (final id in localIds) {
        final assignedFirestoreId = newFirestoreIds[id];
        if (assignedFirestoreId != null) {
          await (update(notes)..where((t) => t.id.equals(id))).write(
            NotesCompanion(
              syncStatus: const Value(1),
              firestoreId: Value(assignedFirestoreId),
            ),
          );
        }
      }
    });
  }


  // TRASH PAGE METHODS  ----------------------------------------

  /// VIEW TRASH: Watch only notes that have a deletedAt timestamp
  Stream<List<Note>> watchTrashNotes() {
    return (select(notes)
      ..where((t) => t.deletedAt.isNotNull())
    // Sort trash by most recently deleted
      ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)])
    ).watch();
  }

  /// RESTORE: Remove the deletedAt flag and trigger a sync
  Future<bool> restoreNote(int id) async {
    return await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        deletedAt: const Value(null), // Nullify the trash flag
        syncStatus: const Value(0),   // Flag as pending sync
        updatedAt: Value(DateTime.now().toUtc()), // Enforce Last-Write-Wins
      ),
    ) > 0;
  }

  /// EMPTY TRASH (LOCAL): Hard delete all trashed notes and return their Firestore IDs
  Future<List<String>> emptyLocalTrash() async {
    // Get all trashed notes before we delete them
    final trashedNotes = await (select(notes)..where((t) => t.deletedAt.isNotNull())).get();

    // Extract the Firestore IDs (ignore any notes that were never synced)
    final firestoreIdsToDelete = trashedNotes
        .map((note) => note.firestoreId)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    // Perform the actual hard delete locally
    final deletedCount = await (delete(notes)..where((t) => t.deletedAt.isNotNull())).go();
    print("Drift: Emptied $deletedCount notes from local trash.");

    //Return the IDs so Firebase knows what to delete
    return firestoreIdsToDelete;
  }
}