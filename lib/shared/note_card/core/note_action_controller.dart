import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';
import 'package:noteit/features/home/core/providers.dart';

import '../../../database/drift/notes/notes_dao.dart';

/// Provider for [NoteActionsController].
final noteActionsControllerProvider = Provider<NoteActionsController>((ref) {
  return NoteActionsController(ref: ref);
});

/// Central controller for executing note actions (delete, archive, pin, lock, duplicate, etc.).
///
/// Handles database mutations via [NotesDao], triggers background cloud sync via [SyncOrchestrator],
/// logs operations using [AppLogger], and ensures active note state ([activeNoteProvider])
/// remains consistent when active notes are deleted, archived, or locked.
class NoteActionsController {
  final Ref ref;
  final _uuidGen = const Uuid();

  NoteActionsController({required this.ref});

  LocalDatabase get db => ref.read(localDatabaseProvider);

  /// Helper to clear [activeNoteProvider] if the currently open note is in [targetUuids].
  void _clearActiveNoteIfAffected(List<String> targetUuids) {
    final activeNote = ref.read(activeNoteProvider);
    if (activeNote != null && targetUuids.contains(activeNote.note.uuid)) {
      ref.read(activeNoteProvider.notifier).clear();
    }
  }

  /// Helper to refresh [activeNoteProvider] if the currently open note is in [targetUuids].
  Future<void> _updateActiveNoteIfAffected(List<String> targetUuids) async {
    final activeNote = ref.read(activeNoteProvider);
    if (activeNote != null && targetUuids.contains(activeNote.note.uuid)) {
      try {
        final updatedNote = await db.notesDao.getNoteById(activeNote.note.uuid);
        ref.read(activeNoteProvider.notifier).setNote(updatedNote);
      } catch (_) {
        ref.read(activeNoteProvider.notifier).clear();
      }
    }
  }

  /// Soft-deletes a list of notes by UUIDs.
  Future<void> deleteNotes(List<String> uuids, String platform) async {
    await db.notesDao.softDeleteNotes(uuids, platform: platform);
    AppLogger.d('NoteActionsController: Soft deleted notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    _clearActiveNoteIfAffected(uuids);
  }

  /// Toggles the pin status for a list of notes.
  Future<void> togglePinNotes(List<String> uuids) async {
    await db.notesDao.togglePinStatus(uuids);
    AppLogger.d('NoteActionsController: Toggled pin status ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    await _updateActiveNoteIfAffected(uuids);
  }

  /// Sets notes as pinned.
  Future<void> pinNotes(List<String> uuids) async {
    await db.notesDao.setNotesPinStatus(uuids, isPinned: true);
    AppLogger.d('NoteActionsController: Pinned notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    await _updateActiveNoteIfAffected(uuids);
  }

  /// Sets notes as unpinned.
  Future<void> unpinNotes(List<String> uuids) async {
    await db.notesDao.setNotesPinStatus(uuids, isPinned: false);
    AppLogger.d('NoteActionsController: Unpinned notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    await _updateActiveNoteIfAffected(uuids);
  }

  /// Archives a list of notes.
  Future<void> archiveNotes(List<String> uuids) async {
    await db.notesDao.archiveNotes(uuids);
    AppLogger.d('NoteActionsController: Archived notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    _clearActiveNoteIfAffected(uuids);
  }

  /// Unarchives a list of notes.
  Future<void> unarchiveNotes(List<String> uuids) async {
    await db.notesDao.unarchiveNotes(uuids);
    AppLogger.d('NoteActionsController: Unarchived notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
  }

  /// Locks a list of notes.
  Future<void> lockNotes(List<String> uuids) async {
    for (final uuid in uuids) {
      await db.notesDao.lockNote(uuid, isLocked: true);
    }
    AppLogger.d('NoteActionsController: Locked notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    _clearActiveNoteIfAffected(uuids);
  }

  /// Duplicates a list of notes.
  Future<void> duplicateNotes(List<String> uuids, String platform) async {
    final notesToDuplicate = await db.notesDao.getNotesByUuids(uuids);

    final newNotes = notesToDuplicate.map((note) {
      return NotesCompanion.insert(
        uuid: Value(_uuidGen.v4()),
        title: note.title.isEmpty ? 'Untitled (Copy)' : '${note.title} (Copy)',
        content: note.content,
        color: Value(note.color),
        tags: Value(note.tags),
        lockedAt: Value(note.lockedAt),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        cloudSyncStatus: const Value(0),
        localSyncStatus: const Value(0),
        creationPlatform: Value(platform),
      );
    }).toList();

    if (newNotes.isNotEmpty) {
      await db.notesDao.insertMultipleNotes(newNotes);
      AppLogger.d('NoteActionsController: Duplicated notes ($uuids)');
      ref.read(syncOrchestratorProvider).triggerSync();
    }
  }

  /// Restores a list of notes from trash.
  Future<void> restoreNotes(List<String> uuids) async {
    await db.notesDao.restoreNotesBatch(uuids);
    AppLogger.d('NoteActionsController: Restored notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
  }

  /// Permanently deletes a list of notes.
  Future<void> deleteForever(List<String> uuids) async {
    await db.notesDao.hardDeleteNotesBatch(uuids);
    AppLogger.d('NoteActionsController: Permanently deleted notes ($uuids)');
    ref.read(syncOrchestratorProvider).triggerSync();
    _clearActiveNoteIfAffected(uuids);
  }

  /// Empties local notes and folders trash, and purges corresponding Firestore entries if online.
  Future<void> emptyLocalAndCloudTrash() async {
    final cloudNoteIdsToDelete = await db.notesDao.emptyLocalTrash();
    final cloudFolderIdsToDelete = await db.foldersDao.emptyLocalFolderTrash();

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb != null) {
      if (cloudNoteIdsToDelete.isNotEmpty) {
        await firebaseDb.deleteBatch('notes', cloudNoteIdsToDelete);
      }
      if (cloudFolderIdsToDelete.isNotEmpty) {
        await firebaseDb.deleteBatch('folders', cloudFolderIdsToDelete);
      }
    }

    AppLogger.d('NoteActionsController: Emptied local and cloud trash');
    ref.read(syncOrchestratorProvider).triggerSync();
  }

  /// Permanently deletes selected notes and folders.
  Future<void> hardDeleteSelection({
    Iterable<String>? noteUuids,
    Iterable<String>? folderUuids,
  }) async {
    final notesList = noteUuids?.toList() ?? [];
    final foldersList = folderUuids?.toList() ?? [];

    if (notesList.isNotEmpty) {
      await db.notesDao.hardDeleteNotesBatch(notesList);
    }
    if (foldersList.isNotEmpty) {
      for (final uuid in foldersList) {
        await db.foldersDao.hardDeleteFolder(uuid);
      }
    }

    final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
    if (firebaseDb != null) {
      if (notesList.isNotEmpty) {
        await firebaseDb.deleteBatch('notes', notesList);
      }
      if (foldersList.isNotEmpty) {
        await firebaseDb.deleteBatch('folders', foldersList);
      }
    }

    AppLogger.d('NoteActionsController: Hard deleted ${notesList.length} notes and ${foldersList.length} folders');
    ref.read(syncOrchestratorProvider).triggerSync();
    _clearActiveNoteIfAffected(notesList);
  }
}
