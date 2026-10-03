import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../../core/util/logger.dart';

// Set of all possible database sorting options (NOT FOR UI, Internal logic only)
enum NoteSortPreference { name, createdAt, updatedAt }

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

/// Listens directly to the Drift database stream and applies the sorting logic.
/// and passes it to `filteredNotesProvider`
/// Whenever a note is added, edited, or deleted in the database, Drift fires a new
/// list of notes through the stream. This provider catches it instantly, sorts it,
final sortedNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final sortOption = ref.watch(noteSortPreferenceProvider); // Watches the UI choice

  return notesDao.watchAllNotes().map((notes) {
    AppLogger.d("### Stream received ${notes.length} total notes from Drift");

    // FILTER OUT DELETED NOTES FIRST
    // It's much faster to remove trashed notes before you run expensive sorting logic.
    final activeNotes = notes.where((note) => note.deletedAt == null).toList();

    // APPLY THE SORTING MATH
    switch (sortOption) {
      case NoteSortPreference.name:
        // Alphabetical sort. .toLowerCase() ensures "apple" and "Zebra" sort correctly.
        activeNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;

      case NoteSortPreference.createdAt:
        // b.compareTo(a) means "Descending Order" (Newest at the top)
        activeNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case NoteSortPreference.updatedAt:
        activeNotes.sort((a, b) {
          final aTime = a.updatedAt;
          final bTime = b.updatedAt;
          return bTime.compareTo(aTime);
        });
        break;
    }

    return activeNotes; // Passes this list directly into filteredNotesProvider
  });
});
