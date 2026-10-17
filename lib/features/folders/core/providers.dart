import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/local_database.dart';

final activeFolderProvider = NotifierProvider<ActiveFolderNotifier, Folder?>(() {
  return ActiveFolderNotifier();
});

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