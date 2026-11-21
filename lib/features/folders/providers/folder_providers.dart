import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';

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
  final Folder? initialState;
  
  ActiveFolderNotifier({this.initialState});

  @override
  Folder? build() {
    // Reactive Validation (Industry Standard): 
    // Watch the active folders list. If a background sync (or local action) 
    // soft-deletes the currently active folder, this listener will detect it
    // and instantly revert the UI to "All Notes" to prevent stale/invalid state.
    ref.listen(activeFoldersStreamProvider, (previous, next) {
      final currentFolder = state;
      if (currentFolder == null) return;
      
      final activeFolders = next.value;
      if (activeFolders != null) {
        final folderStillExists = activeFolders.any((f) => f.folder.uuid == currentFolder.uuid);
        if (!folderStillExists) {
          // Folder no longer valid (e.g. soft-deleted via sync), fallback to All Notes
          clear();
        }
      }
    });

    return initialState;
  }

  // Action to select a folder
  void setFolder(Folder folder) {
    state = folder;
    SharedPreferenceManager.instance.setLastActiveFolderId(folder.uuid);
  }

  void clear() {
    state = null;
    SharedPreferenceManager.instance.setLastActiveFolderId(null);
  }
}
