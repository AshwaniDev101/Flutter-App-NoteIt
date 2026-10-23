import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/menus/sort_menu_button.dart';
import '../../../shared/menus/view_menu_button.dart';
import '../../home/core/providers.dart';

// ==========================================
// PROVIDERS & NOTIFIERS
// ==========================================

final archivedNotesStreamProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

/// Dedicated Sort Preference Provider for Archive Page
final archiveNoteSortPreferenceProvider = NotifierProvider<ArchiveNoteSortPreferenceNotifier, NoteSortPreference>(() {
  return ArchiveNoteSortPreferenceNotifier();
});

class ArchiveNoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() {
    return SharedPreferenceManager.instance.getPageSortOption('archive');
  }

  void updateSort(NoteSortPreference option) {
    state = option;
    SharedPreferenceManager.instance.setPageSortOption('archive', option);
  }
}

/// Dedicated View Type Provider for Archive Page
final archiveNoteViewTypeProvider = NotifierProvider<ArchiveNoteViewTypeNotifier, NoteViewType>(
  ArchiveNoteViewTypeNotifier.new,
);

class ArchiveNoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() {
    return SharedPreferenceManager.instance.getPageViewType('archive');
  }

  void updateView(NoteViewType view) {
    state = view;
    SharedPreferenceManager.instance.setPageViewType('archive', view);
  }
}

/// Dedicated Platform Filter Provider for Archive Page
final archivePlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);
