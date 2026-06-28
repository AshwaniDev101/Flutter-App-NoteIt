import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

enum NoteSortOption { name, createdAt, updatedAt }

// Create a Notifier to manage the state
class NoteSortNotifier extends Notifier<NoteSortOption> {
  @override
  NoteSortOption build() {
    // Return the initial state
    return NoteSortOption.createdAt;
  }

  void updateSort(NoteSortOption option) {
    state = option;
  }
}

// Create the NotifierProvider
final noteSortOptionProvider = NotifierProvider<NoteSortNotifier, NoteSortOption>(() {
  return NoteSortNotifier();
});

final sortedNotesProvider = StreamProvider<List<Note>>((ref) {
  final driftDatabase = ref.watch(noteDriftDatabaseProvider);
  final sortOption = ref.watch(noteSortOptionProvider);

  return driftDatabase.watchAllNotes().map((notes) {
    // Debug: Add this print to verify data flow in the console
    print("### Stream received ${notes.length} total notes from Drift");

    // UPDATED: Use deletedAt == null instead of !isDeleted
    final activeNotes = notes.where((note) => note.deletedAt == null).toList();

    switch (sortOption) {
      case NoteSortOption.name:
        activeNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.createdAt:
      // These are UTC timestamps now, which is perfect for accurate sorting!
        activeNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOption.updatedAt:
        activeNotes.sort((a, b) {
          final aTime = a.updatedAt ?? a.createdAt;
          final bTime = b.updatedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        break;
    }

    return activeNotes;
  });
});