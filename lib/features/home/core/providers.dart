import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/sort.dart';
import '../../../../../database/drift/drift_database.dart';
import '../../unlock/lock_manger/lock_manager.dart';
import 'options.dart';

final platformFilterProvider = NotifierProvider<PlatformFilterNotifier, PlatformOptions>(PlatformFilterNotifier.new);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final sortedNotesAsync = ref.watch(sortedNotesProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
  final platformFilter = ref.watch(platformFilterProvider);

  final lockState = ref.watch(lockManagerProvider);

  return sortedNotesAsync.whenData((notes) {
    List<Note> result = notes;

    if (platformFilter != PlatformOptions.all) {
      final targetPlatform = platformFilter == PlatformOptions.android ? 'android' : 'windows';
      result = result.where((note) {
        return note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((note) {
        final matchesTitle = note.title.toLowerCase().contains(searchQuery);

        final canReadContent = !note.isLocked || lockState.sessionUnlockedNoteIds.contains(note.uuid);
        final matchesContent = canReadContent && note.content.toLowerCase().contains(searchQuery);
        // final matchesContent = !note.isLocked && note.content.toLowerCase().contains(searchQuery);
        return matchesTitle || matchesContent;
      }).toList();
    }

    return result;
  });
});

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class PlatformFilterNotifier extends Notifier<PlatformOptions> {
  @override
  PlatformOptions build() => PlatformOptions.all;

  void toggleFilter(PlatformOptions filter) {
    if (state == filter) {
      state = PlatformOptions.all;
    } else {
      state = filter;
    }
  }
}

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
