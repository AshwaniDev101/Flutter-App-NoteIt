import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../../database/drift/local_database.dart';


final noteActionsControllerProvider = Provider<NoteActionsController>((ref) {
  return NoteActionsController(db: ref.read(localDatabaseProvider));
});

class NoteActionsController {
  final LocalDatabase db;
  final _uuidGen = const Uuid();

  NoteActionsController({required this.db});

  Future<void> deleteNotes(List<String> uuids, String platform) async {
    await db.notesDao.softDeleteNotes(uuids, platform: platform);
  }

  Future<void> togglePinNotes(List<String> uuids) async {
    // Assuming you kept the togglePinStatus method in your DAO
    await db.notesDao.togglePinStatus(uuids);
  }

  Future<void> archiveNotes(List<String> uuids) async {
    await db.notesDao.archiveNotes(uuids);
  }

  Future<void> lockNotes(List<String> uuids) async {
    // You'll need a batch lock method in your DAO if you don't have one!
    // Example: await db.notesDao.lockMultipleNotes(uuids, isLocked: true);
    for (final uuid in uuids) {
      await db.notesDao.lockNote(uuid, isLocked: true);
    }
  }

  Future<void> duplicateNotes(List<String> uuids, String platform) async {
    final notesToDuplicate = await db.notesDao.getNotesByUuids(uuids);

    final newNotes = notesToDuplicate.map((note) {
      return NotesCompanion.insert(
        uuid: Value(_uuidGen.v4()),
        title: note.title.isEmpty ? 'Untitled (Copy)' : '${note.title} (Copy)',
        content: note.content,
        color: Value(note.color),
        tags: Value(note.tags),
        // Note: We omit pinnedAt and archivedAt so they default to null (unpinned/unarchived).
        lockedAt: Value(note.lockedAt), // Inherit the original's lock state
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        creationPlatform: Value(platform),

        // updateCounter automatically defaults to 1 on insert
      );
    }).toList();

    if (newNotes.isNotEmpty) {
      await db.notesDao.insertMultipleNotes(newNotes);
    }
  }

  Future<void> unarchiveNotes(List<String> uuids) async {
    await db.notesDao.unarchiveNotes(uuids);
  }


  Future<void> restoreNotes(List<String> uuids) async {
    await db.notesDao.restoreNotesBatch(uuids);
  }

  Future<void> deleteForever(List<String> uuids) async {
    await db.notesDao.hardDeleteNotesBatch(uuids);
  }

}

