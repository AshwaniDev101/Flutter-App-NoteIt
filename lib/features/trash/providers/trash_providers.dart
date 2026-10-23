import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/menus/sort_menu_button.dart';
import '../../../shared/menus/view_menu_button.dart';
import '../../home/core/providers.dart';

// ==========================================
// PROVIDERS & NOTIFIERS
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
