import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../../core/util/logger.dart';

export 'package:noteit/database/drift/notes/notes_dao.dart' show NoteSortPreference;

/// State Holder: holds the user's current choice of sorting method for Home / ListPanel.
final homeNoteSortPreferenceProvider = NotifierProvider<NoteSortPreferenceNotifier, NoteSortPreference>(() {
  return NoteSortPreferenceNotifier();
});

class NoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() {
    // Default to newest first
    return NoteSortPreference.createdAt;
  }

  void updateSort(NoteSortPreference option) {
    state = option;
  }
}

/// Listens directly to the Drift database stream sorted by SQLite for Home / ListPanel.
final sortedNotesStreamProvider = StreamProvider<List<NoteWithFolder>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final sortOption = ref.watch(homeNoteSortPreferenceProvider); // Watches Home UI choice

  AppLogger.d("DbSortingFiltering: Querying sorted notes from SQLite with option: $sortOption");
  return notesDao.watchSortedNotes(sortOption);
});
