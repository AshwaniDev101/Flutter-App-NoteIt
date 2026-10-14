import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../../core/util/logger.dart';

export 'package:noteit/database/drift/notes/notes_dao.dart' show NoteSortPreference;

/// State Holder: holds the user current choice of sorting method.
final noteSortPreferenceProvider = NotifierProvider<NoteSortPreferenceNotifier, NoteSortPreference>(() {
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

/// Listens directly to the Drift database stream sorted by SQLite.
/// Passes the sorted list to `filteredNotesProvider`.
/// Filtering (active notes vs deleted/archived) and sorting (pinned notes first by pin timestamp,
/// followed by sort preference) are offloaded directly to SQLite for optimal performance.
final sortedNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final sortOption = ref.watch(noteSortPreferenceProvider); // Watches the UI choice

  AppLogger.d("DbSortingFiltering: Querying sorted notes from SQLite with option: $sortOption");
  return notesDao.watchSortedNotes(sortOption);
});
