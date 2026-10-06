import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../core/providers.dart';

class SelectModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Set<String> noteIds;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;

  const SelectModeAppBar({super.key, required this.noteIds, required this.onClearSelection, required this.onSelectAll});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNotes = ref.watch(filteredNotesProvider).value ?? [];
    final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: onClearSelection),
      title: Text('${noteIds.length} Selected', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: onSelectAll,
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final noteDao = ref.read(notesDaoProvider);

            await noteDao.softDeleteNotes(noteIds, platform: PlatformHelper.name);

            ref.read(syncOrchestratorProvider).triggerSync();
            onClearSelection();
          },
        ),
      ],
    );
  }
}

// SEARCH MODE APP BAR
class SearchModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onExitSearchMode;

  const SearchModeAppBar({super.key, required this.searchController, required this.onExitSearchMode});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onExitSearchMode),
      title: TextField(
        controller: searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(hintText: 'Search notes...', border: InputBorder.none),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
      ),
      actions: [
        if (ref.watch(searchQueryProvider).isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              searchController.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
      ],
    );
  }
}
