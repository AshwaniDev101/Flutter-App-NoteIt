import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/menus/view_menu_button.dart';
import '../../home/core/providers.dart';

export '../viewmodel/trash_view_model.dart';

// ==========================================
// BASE STREAMS & PREFERENCES
// ==========================================

final trashNotesProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchTrashNotes();
});

final trashFoldersProvider = StreamProvider.autoDispose<List<Folder>>((ref) {
  final foldersDao = ref.watch(foldersDaoProvider);
  return foldersDao.watchTrashFolders();
});

/// Dedicated Sort Preference Provider for Trash Page
final trashNoteSortPreferenceProvider = NotifierProvider<TrashNoteSortPreferenceNotifier, NoteSortPreference>(() {
  return TrashNoteSortPreferenceNotifier();
});

class TrashNoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() {
    return SharedPreferenceManager.instance.getPageSortOption('trash');
  }

  void updateSort(NoteSortPreference option) {
    state = option;
    SharedPreferenceManager.instance.setPageSortOption('trash', option);
  }
}

/// Dedicated View Type Provider for Trash Page
final trashNoteViewTypeProvider = NotifierProvider<TrashNoteViewTypeNotifier, NoteViewType>(
  TrashNoteViewTypeNotifier.new,
);

class TrashNoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() {
    return SharedPreferenceManager.instance.getPageViewType('trash');
  }

  void updateView(NoteViewType view) {
    state = view;
    SharedPreferenceManager.instance.setPageViewType('trash', view);
  }
}

/// Dedicated Platform Filter Provider for Trash Page
final trashPlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);

// ==========================================
// SEARCH & FOLDER FILTER NOTIFIERS
// ==========================================

final trashSearchQueryProvider = NotifierProvider<TrashSearchQueryNotifier, String>(
  TrashSearchQueryNotifier.new,
);

class TrashSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final trashSelectedFolderProvider = NotifierProvider<TrashSelectedFolderNotifier, Folder?>(
  TrashSelectedFolderNotifier.new,
);

class TrashSelectedFolderNotifier extends Notifier<Folder?> {
  @override
  Folder? build() => null;

  void selectFolder(Folder? folder) {
    state = folder;
  }

  void clear() {
    state = null;
  }
}

// ==========================================
// MEMOIZED COMPUTED PROVIDERS FOR PERFORMANCE
// ==========================================

final filteredTrashNotesProvider = Provider.autoDispose<AsyncValue<List<NoteWithFolder>>>((ref) {
  final trashNotesState = ref.watch(trashNotesProvider);
  final searchQuery = ref.watch(trashSearchQueryProvider).trim().toLowerCase();
  final selectedFolder = ref.watch(trashSelectedFolderProvider);
  final platformFilter = ref.watch(trashPlatformFilterProvider);
  final currentSort = ref.watch(trashNoteSortPreferenceProvider);

  return trashNotesState.whenData((notes) {
    var filtered = selectedFolder == null
        ? notes
        : notes.where((nwf) => nwf.note.folderId == selectedFolder.uuid).toList();

    if (platformFilter != FilterPlatformOptions.all) {
      final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
      filtered = filtered.where((nwf) {
        return nwf.note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((nwf) {
        return nwf.note.title.toLowerCase().contains(searchQuery) ||
            nwf.note.content.toLowerCase().contains(searchQuery);
      }).toList();
    }

    filtered.sort((a, b) {
      if (currentSort == NoteSortPreference.name) {
        return a.note.title.toLowerCase().compareTo(b.note.title.toLowerCase());
      } else if (currentSort == NoteSortPreference.createdAt) {
        return b.note.createdAt.compareTo(a.note.createdAt);
      } else if (currentSort == NoteSortPreference.updatedAt) {
        return b.note.updatedAt.compareTo(a.note.updatedAt);
      } else if (currentSort == NoteSortPreference.folder) {
        final folderA = a.folder?.name.toLowerCase() ?? '';
        final folderB = b.folder?.name.toLowerCase() ?? '';
        final cmp = folderA.compareTo(folderB);
        if (cmp != 0) return cmp;
        return b.note.updatedAt.compareTo(a.note.updatedAt);
      } else if (currentSort == NoteSortPreference.reminderAt) {
        final remA = a.note.reminderAt;
        final remB = b.note.reminderAt;
        if (remA == null && remB == null) {
          return b.note.updatedAt.compareTo(a.note.updatedAt);
        }
        if (remA == null) return 1;
        if (remB == null) return -1;
        final cmp = remA.compareTo(remB);
        if (cmp != 0) return cmp;
        return b.note.updatedAt.compareTo(a.note.updatedAt);
      }
      return b.note.createdAt.compareTo(a.note.createdAt);
    });

    return filtered;
  });
});

final filteredTrashFoldersProvider = Provider.autoDispose<AsyncValue<List<Folder>>>((ref) {
  final trashFoldersState = ref.watch(trashFoldersProvider);
  final searchQuery = ref.watch(trashSearchQueryProvider).trim().toLowerCase();
  final selectedFolder = ref.watch(trashSelectedFolderProvider);
  final currentSort = ref.watch(trashNoteSortPreferenceProvider);

  return trashFoldersState.whenData((folders) {
    var filtered = selectedFolder == null
        ? folders
        : folders.where((f) => f.uuid == selectedFolder.uuid).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    filtered.sort((a, b) {
      if (currentSort == NoteSortPreference.name) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (currentSort == NoteSortPreference.createdAt) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return filtered;
  });
});
