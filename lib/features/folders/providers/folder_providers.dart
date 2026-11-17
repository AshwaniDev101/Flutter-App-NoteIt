import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';

final activeFolderProvider = NotifierProvider<ActiveFolderNotifier, Folder?>(() {
  return ActiveFolderNotifier();
});

/// Holds target note UUIDs pending folder reassignment
final movingNoteIdsProvider = NotifierProvider<MovingNoteIdsNotifier, List<String>>(MovingNoteIdsNotifier.new);

final activeFoldersStreamProvider = StreamProvider<List<FolderWithCount>>((ref) {
  final foldersDao = ref.watch(foldersDaoProvider);
  return foldersDao.watchActiveFoldersWithCounts();
});

final totalNotesCountStreamProvider = StreamProvider<int>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchActiveNotesCount();
});

class MovingNoteIdsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setNoteIds(List<String> ids) {
    state = ids;
  }

  void clear() {
    state = [];
  }
}

class ActiveFolderNotifier extends Notifier<Folder?> {
  @override
  Folder? build() {
    // Initial state: null (means "All Notes" or no folder selected)
    return null;
  }

  // Action to select a folder
  void setFolder(Folder folder) {
    state = folder;
  }

  void clear() {
    state = null;
  }
}
