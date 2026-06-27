import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notes_table.dart';

part 'drift_database.g.dart';

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
  }) async {
    print("### NoteDriftDatabase Note Added!");

    return await into(notes).insert(
      NotesCompanion.insert(
        title: title,
        content: content,
        // Enforce UTC for accurate multi-device syncing
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
        isDeleted: const Value(true),
        syncStatus: const Value(0), // Trigger the SyncManager
        updatedAt: Value(DateTime.now().toUtc()), // Enforce UTC
      ),
    );
  }

  Future<bool> lockNote(int id, {required bool isLocked}) async {
    return await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isLocked: Value(isLocked),
        syncStatus: const Value(0), // Trigger the SyncManager
        updatedAt: Value(DateTime.now().toUtc()), // Enforce UTC
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
    final noteCompanion = NotesCompanion(
      title: Value(cloudNote['title'] as String),
      content: Value(cloudNote['content'] as String),
      color: Value(cloudNote['color'] as int? ?? 0xFFFFFFFF),
      isPinned: Value(cloudNote['isPinned'] as bool? ?? false),
      isArchived: Value(cloudNote['isArchived'] as bool? ?? false),
      isLocked: Value(cloudNote['isLocked'] as bool? ?? false),
      isDeleted: Value(cloudNote['isDeleted'] as bool? ?? false),
      position: Value(cloudNote['position'] as int? ?? 0),
      tags: Value(cloudNote['tags'] as String?),
      syncStatus: const Value(1), // Already synced!
      firestoreId: Value(firestoreId),
      // Safely parse timestamps
      reminderAt: cloudNote['reminderAt'] != null
          ? Value(DateTime.fromMillisecondsSinceEpoch(cloudNote['reminderAt'] as int, isUtc: true))
          : const Value.absent(),
      updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(cloudNote['updatedAt'] as int, isUtc: true)),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch(cloudNote['createdAt'] as int, isUtc: true)),
    );

    final existingNote = await (select(notes)..where((t) => t.firestoreId.equals(firestoreId))).getSingleOrNull();

    if (existingNote != null) {
      await (update(notes)..where((t) => t.id.equals(existingNote.id))).write(noteCompanion);
    } else {
      await into(notes).insert(noteCompanion);
    }
  }

  /// CONFIRM: Mark local notes as successfully pushed to Firebase
  Future<void> markAsSynced(Iterable<int> localIds, Map<int, String> newFirestoreIds) async {
    // Run in a transaction so they all update securely at once
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
}