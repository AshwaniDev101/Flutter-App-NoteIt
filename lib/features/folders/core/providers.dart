import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/local_database.dart';

final activeFolderProvider = NotifierProvider<ActiveFolderNotifier, Folder?>(() {
  return ActiveFolderNotifier();
});

/// Holds target note UUIDs pending folder reassignment
final movingNoteIdsProvider = NotifierProvider<MovingNoteIdsNotifier, List<String>>(MovingNoteIdsNotifier.new);

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