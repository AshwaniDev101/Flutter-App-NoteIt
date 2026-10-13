import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/drift/local_database.dart';
import '../../../../features/home/viewmodel/viewmodel.dart';


final noteActionsControllerProvider = Provider<NoteActionsController>((ref) {
  final db = ref.read(localDatabaseProvider);
  return NoteActionsController(
    db: db,
    onClearSelection: () => ref.read(homeViewModelProvider.notifier).clearSelection(),
  );
});


class NoteActionsController {
  final LocalDatabase db;
  final VoidCallback onClearSelection;


  NoteActionsController({required this.db, required this.onClearSelection});

  // --- Helper to clean up the UI after a batch action ---
  void _clearSelectionAfterAction() => onClearSelection();

  Future<void> deleteNotes(List<String> uuids) async {
    // TODO: Call your Drift DAO to delete/soft-delete these notes
    // Example: await _db.notesDao.deleteNotesByUuids(uuids);

    _clearSelectionAfterAction();
  }

  Future<void> togglePinNotes(List<String> uuids) async {
    // TODO: Call your Drift DAO to flip the 'isPinned' status
    // Example: await _db.notesDao.togglePinStatus(uuids);

    _clearSelectionAfterAction();
  }

  Future<void> archiveNotes(List<String> uuids) async {
    // TODO: Call your Drift DAO to archive

    _clearSelectionAfterAction();
  }

  Future<void> lockNotes(List<String> uuids) async {
    // TODO: Integrate with your lockManagerProvider and DB
    _clearSelectionAfterAction();
  }

  Future<void> duplicateNotes(List<String> uuids) async {
    // TODO: Fetch the notes, change their UUIDs, append " (Copy)" to the title, and insert
    _clearSelectionAfterAction();
  }



}
