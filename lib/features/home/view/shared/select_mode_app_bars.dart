import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../../shared/note_card/core/note_action_controller.dart';
import '../../core/providers.dart';

import '../../viewmodel/viewmodel.dart';

/// App Bar displayed when selection mode is active on Home screens.
///
/// Features:
/// - Displays count of currently selected notes.
/// - Provides "Select All" / "Deselect All" button (defaults to toggling all filtered notes).
/// - Provides "Delete Selected" batch action button.
/// - Optional [onClearSelection] and [onSelectAll] overrides.
class SelectModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Set<String> noteIds;
  final VoidCallback? onClearSelection;
  final VoidCallback? onSelectAll;

  const SelectModeAppBar({
    super.key,
    required this.noteIds,
    this.onClearSelection,
    this.onSelectAll,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final currentNotes = ref.watch(filteredNotesProvider).value ?? [];
    final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

    // Use passed handlers or default to HomeViewModel Riverpod actions
    final handleClearSelection = onClearSelection ?? viewModel.clearSelection;
    final handleSelectAll = onSelectAll ??
        () {
          final allNoteUuids = currentNotes.map((noteWithFolder) => noteWithFolder.note.uuid).toList();
          viewModel.toggleSelectAll(allNoteUuids);
        };

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      foregroundColor: Colors.white,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: handleClearSelection),
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
            onPressed: handleSelectAll,
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final actionsController = ref.read(noteActionsControllerProvider);

            // Soft-delete selected notes, sync, log, and update active note state
            await actionsController.deleteNotes(noteIds.toList(), PlatformHelper.name);

            handleClearSelection();
          },
        ),
      ],
    );
  }
}

/// App Bar displayed when search mode is active.
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
