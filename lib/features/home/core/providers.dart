import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/db_sorting_filtering.dart';
import '../../../database/drift/local_database.dart';
import '../../lock/lock_manger/lock_manager.dart';
import '../view/shared/tag_sort_view_menu.dart';


/// MAIN FILTER: Combines all the filters (SORT + PLATFORM + SEARCH + LOCK-STATE)
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  // Watch dependencies. If any of these 4 change, this entire function re-runs automatically.
  final sortedNotesAsync = ref.watch(sortedNotesStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final platformFilter = ref.watch(platformFilterProvider);
  final lockState = ref.watch(lockManagerProvider);

  // states, and only runs filter logic if the database successfully returned data.
  return sortedNotesAsync.whenData((notes) {
    // Start with the full list
    List<Note> result = notes;

    // Apply Platform Filter
    if (platformFilter != FilterPlatformOptions.all) {
      final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
      result = result.where((note) {
        return note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    // Apply Text Search
    if (searchQuery.isNotEmpty) {
      result = result.where((note) {
        final matchesTitle = note.title.toLowerCase().contains(searchQuery);

        // Security check: Only search content if the note is unlocked or currently open in session
        final canReadContent = !note.isLocked || lockState.sessionUnlockedNoteIds.contains(note.uuid);
        final matchesContent = canReadContent && note.content.toLowerCase().contains(searchQuery);

        return matchesTitle || matchesContent;
      }).toList();
    }

    return result; // Return the final UI-ready list
  });
}); // it combines all the filter into one,  search query, platform filter, and lock state.

/// PLATFORM FILTER
enum FilterPlatformOptions { all, android, windows } // State Holder : holds for platform filter
final platformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
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
final activeNoteProvider = NotifierProvider<ActiveNoteNotifier, Note?>(() {
  return ActiveNoteNotifier();
});
class ActiveNoteNotifier extends Notifier<Note?> {
  @override
  Note? build() {
    // Initial state: no note is selected
    return null;
  }

  // Action to select a note
  void setNote(Note note) {
    state = note;
  }

  // Action to close/clear the editor
  void clear() {
    state = null;
  }
}

/// VIEW TYPE
final noteViewTypeProvider = NotifierProvider<NoteViewTypeNotifier, NoteViewType>(NoteViewTypeNotifier.new);
class NoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() => NoteViewType.grid;

  void updateView(NoteViewType view) {
    state = view;
  }
}

