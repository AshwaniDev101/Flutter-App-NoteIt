import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/db_sorting_filtering.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/view_menu_button.dart';
import '../../folders/core/providers.dart';
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

/// SEARCH FILTER
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// ACTIVE NOTE STATE HOLDER
final activeNoteProvider = NotifierProvider<ActiveNoteNotifier, NoteWithFolder?>(() {
  return ActiveNoteNotifier();
});
class ActiveNoteNotifier extends Notifier<NoteWithFolder?> {
  @override
  NoteWithFolder? build() {
    // Initial state: no note is selected
    return null;
  }

  // Action to select a note
  void setNote(NoteWithFolder noteWithFolder) {
    state = noteWithFolder;
  }

  // Action to close/clear the editor
  void clear() {
    state = null;
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