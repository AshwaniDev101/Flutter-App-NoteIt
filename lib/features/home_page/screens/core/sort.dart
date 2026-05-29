import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/firebase/firebase_database.dart';
import '../../../../models/note_model.dart';

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

// The StreamProvider remains mostly the same, watching the new provider
final sortedNotesProvider = StreamProvider.autoDispose<List<NoteModel>>((ref) {
  final firestoreDatabase = ref.watch(noteFirebaseDatabaseProvider);
  final sortOption = ref.watch(noteSortOptionProvider);

  return firestoreDatabase.watchNotes().map((notes) {
    final sortedNotes = List<NoteModel>.from(notes);

    switch (sortOption) {
      case NoteSortOption.name:
        sortedNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.createdAt:
        sortedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOption.updatedAt:
        sortedNotes.sort((a, b) {
          final aTime = a.updatedAt ?? a.createdAt;
          final bTime = b.updatedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        break;
    }
    return sortedNotes;
  });
});