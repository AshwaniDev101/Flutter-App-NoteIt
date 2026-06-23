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

  Future<int> addNote({
    required String title,
    required String content,
  }) async {
    print("### NoteDriftDatabase Note Added!");

    return await into(notes).insert(
      NotesCompanion.insert(
        title: title,
        content: content,
        // syncStatus defaults to 0 and createdAt defaults to now automatically based on our table definition
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
          syncStatus: const Value(0), // Trigger the SyncService
          updatedAt: Value(DateTime.now()), // Update timestamp for sorting
        )
    ) > 0;
  }

  Future<int> deleteNote(int id) async {
    // This is the "Hard Delete" used by the SyncService once Firebase confirms deletion
    return await (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> softDeleteNotes(Iterable<int> ids) async {
    // This is the "Soft Delete" used by the UI
    await (update(notes)..where((t) => t.id.isIn(ids))).write(
      NotesCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value(0), // Mark as pending sync so Firebase knows to delete it
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // LockNote method required by your ViewModel
  Future<bool> lockNote(int id, {required bool isLocked}) async {
    return await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isLocked: Value(isLocked),
        syncStatus: const Value(0), // Trigger the SyncService
        updatedAt: Value(DateTime.now()),
      ),
    ) > 0;
  }
}