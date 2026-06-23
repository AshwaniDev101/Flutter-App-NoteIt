import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/cupertino.dart' hide Table;
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
    return await (update(
          notes,
        )..where((t) => t.id.equals(id))).write(NotesCompanion(title: Value(title), content: Value(content))) >
        0;
  }

  Future<int> deleteNote(int id) async {
    return await (delete(notes)..where((t) => t.id.equals(id))).go();
  }

}