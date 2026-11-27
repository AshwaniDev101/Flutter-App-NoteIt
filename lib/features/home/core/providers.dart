import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/db_sorting_filtering.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/menus/view_menu_button.dart';
import '../../folders/providers/folder_providers.dart';
import '../../lock/lock_manger/lock_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';


/// MAIN FILTER: Combines all the filters (FOLDER + SORT + PLATFORM + SEARCH + LOCK-STATE)
final filteredNotesProvider = Provider<AsyncValue<List<NoteWithFolder>>>((ref) {
  // Watch dependencies. If any of these 5 change, this entire function re-runs automatically.
  final sortedNotesAsync = ref.watch(sortedNotesStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final platformFilter = ref.watch(homePlatformFilterProvider);
  final lockState = ref.watch(lockManagerProvider);

  // Watch the currently active folder
  final activeFolder = ref.watch(activeFolderProvider);

  return sortedNotesAsync.whenData((notes) {
    // Start with the full list
    List<NoteWithFolder> result = notes;

    // Apply Folder Filter
    // If a folder is selected (not 'All Notes'), only keep notes with a matching folderId
    if (activeFolder != null) {
      result = result.where((noteWithFolder) => noteWithFolder.note.folderId == activeFolder.uuid).toList();
    }

    // Apply Platform Filter
    if (platformFilter != FilterPlatformOptions.all) {
      final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
      result = result.where((noteWithFolder) {
        return noteWithFolder.note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    // Apply Text Search
    if (searchQuery.isNotEmpty) {
      result = result.where((noteWithFolder) {
        final matchesTitle = noteWithFolder.note.title.toLowerCase().contains(searchQuery);

        // Security check: Only search content if the note is unlocked or currently open in session
        final canReadContent = noteWithFolder.note.lockedAt == null || lockState.sessionUnlockedNoteIds.contains(noteWithFolder.note.uuid);
        final matchesContent = canReadContent && noteWithFolder.note.content.toLowerCase().contains(searchQuery);

        return matchesTitle || matchesContent;
      }).toList();
    }

    return result; // Return the final UI-ready list
  });
});

/// Indicates whether locked notes exist that are omitted from content search
final hasExcludedLockedNotesFromSearchProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider).trim();
  if (searchQuery.isEmpty) return false;
  final notesAsync = ref.watch(sortedNotesStreamProvider);
  final lockState = ref.watch(lockManagerProvider);

  return notesAsync.maybeWhen(
    data: (notes) => notes.any((n) => n.note.lockedAt != null && !lockState.sessionUnlockedNoteIds.contains(n.note.uuid)),
    orElse: () => false,
  );
});


/// PLATFORM FILTER FOR HOME / LIST PANEL
enum FilterPlatformOptions { all, android, windows } // State Holder : holds for platform filter
final homePlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);
class PlatformFilterNotifier extends Notifier<FilterPlatformOptions> {
  @override
  FilterPlatformOptions build() => FilterPlatformOptions.all;

  void toggleFilter(FilterPlatformOptions filter) {
    // Toggle off if tapping the same active filter
    if (state == filter) {
      state = FilterPlatformOptions.all;
    } else {
      state = filter;
    }
  }

  void setFilter(FilterPlatformOptions filter) {
    state = filter;
  }
}

/// DEVICE FILTER VISIBILITY PROVIDER
final showDeviceFilterProvider = NotifierProvider<ShowDeviceFilterNotifier, bool>(() {
  return ShowDeviceFilterNotifier();
});

class ShowDeviceFilterNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferenceProvider);
    return prefs.isShowDeviceFilter;
  }

  Future<void> setShowDeviceFilter(bool enabled) async {
    final prefs = ref.read(sharedPreferenceProvider);
    await prefs.setShowDeviceFilter(enabled);
    state = enabled;
  }

  Future<void> toggleShowDeviceFilter() async {
    await setShowDeviceFilter(!state);
  }
}

/// SEARCH FILTER
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  void updateQuery(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = '';
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      state = query;
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = '';
  }
}

/// ACTIVE NOTE STATE HOLDER
final activeNoteProvider = NotifierProvider<ActiveNoteNotifier, NoteWithFolder?>(() {
  return ActiveNoteNotifier();
});
class ActiveNoteNotifier extends Notifier<NoteWithFolder?> {
  final NoteWithFolder? initialState;
  
  ActiveNoteNotifier({this.initialState});

  @override
  NoteWithFolder? build() {
    // Reactive Validation: Clear active note if it is soft-deleted or archived in background
    ref.listen(notesDaoProvider.select((dao) => dao.watchActiveNotesCount()), (previous, next) async {
      final currentNote = state;
      if (currentNote == null) return;
      
      final db = ref.read(notesDaoProvider);
      final updatedNote = await db.getNoteById(currentNote.note.uuid);
      
      if (updatedNote == null || updatedNote.note.deletedAt != null || updatedNote.note.archivedAt != null) {
        clear();
      }
    });

    return initialState;
  }

  // Action to select a note
  void setNote(NoteWithFolder noteWithFolder) {
    state = noteWithFolder;
    SharedPreferenceManager.instance.setLastActiveNoteId(noteWithFolder.note.uuid);
  }

  // Action to close/clear the editor
  void clear() {
    state = null;
    SharedPreferenceManager.instance.setLastActiveNoteId(null);
  }
}

/// VIEW TYPE FOR HOME / LIST PANEL
final homeNoteViewTypeProvider = NotifierProvider<NoteViewTypeNotifier, NoteViewType>(NoteViewTypeNotifier.new);
class NoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() {
    return SharedPreferenceManager.instance.getPageViewType('home');
  }

  void updateView(NoteViewType view) {
    state = view;
    SharedPreferenceManager.instance.setPageViewType('home', view);
  }
}


/// RIGHT PANEL VIEW
final desktopRightPanelViewProvider = NotifierProvider<DesktopRightPanelViewNotifier, List<RightPanelPageOptions>>(
  DesktopRightPanelViewNotifier.new,
);

class DesktopRightPanelViewNotifier extends Notifier<List<RightPanelPageOptions>> {
  @override
  List<RightPanelPageOptions> build() {
    return [RightPanelPageOptions.noteEditor];
  }

  RightPanelPageOptions get currentView => state.isEmpty ? RightPanelPageOptions.noteEditor : state.last;

  bool get canPop => state.length > 1;

  /// Sets/replaces the entire view stack with a single view (defaults to resetting)
  void setView(RightPanelPageOptions view) {
    resetView(view);
  }

  /// Pushes a new view onto the history stack if different from current view
  void pushView(RightPanelPageOptions view) {
    if (currentView == view) return;
    state = [...state, view];
  }

  /// Pops the top view from the history stack if possible
  void popView() {
    if (canPop) {
      state = state.sublist(0, state.length - 1);
    }
  }

  /// Resets the history stack back to a root option (defaults to noteEditor)
  void resetView([RightPanelPageOptions root = RightPanelPageOptions.noteEditor]) {
    state = [root];
  }
}

/// MIDDLE PANEL WIDTH FOR DESKTOP
final listPanelWidthProvider = NotifierProvider<ListPanelWidthNotifier, double>(
  ListPanelWidthNotifier.new,
);

class ListPanelWidthNotifier extends Notifier<double> {
  @override
  double build() {
    return SharedPreferenceManager.instance.listPanelWidth;
  }

  void updateWidth(double width) {
    state = width;
  }

  void saveWidth([double? width]) {
    final target = width ?? state;
    state = target;
    SharedPreferenceManager.instance.setListPanelWidth(target);
  }
}

/// RIGHT PANEL SELECTION MODE STATE (Used to dim/blur DesktopListPanel)
class RightPanelSelectionState {
  final bool isSelecting;
  final void Function()? onClearSelection;

  const RightPanelSelectionState({
    this.isSelecting = false,
    this.onClearSelection,
  });
}

final rightPanelSelectionProvider =
    NotifierProvider<RightPanelSelectionNotifier, RightPanelSelectionState>(
  RightPanelSelectionNotifier.new,
);

class RightPanelSelectionNotifier extends Notifier<RightPanelSelectionState> {
  @override
  RightPanelSelectionState build() => const RightPanelSelectionState();

  void enterSelection({required void Function() onClear}) {
    state = RightPanelSelectionState(
      isSelecting: true,
      onClearSelection: onClear,
    );
  }

  void exitSelection() {
    state = const RightPanelSelectionState(
      isSelecting: false,
      onClearSelection: null,
    );
  }
}