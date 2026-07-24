import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/theme/note_theme.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/home_page/screens/core/sort.dart';
import '../core/options.dart';
import '../core/providers.dart';
import '../../../../database/sync_manager.dart';

// DEFAULT APP BAR
class DefaultHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isAndroid;
  final TextEditingController searchController;
  final VoidCallback onEnterSearchMode;

  const DefaultHomeAppBar({
    super.key,
    required this.isAndroid,
    required this.searchController,
    required this.onEnterSearchMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);
    final isSyncing = ref.watch(syncNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Note-it', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        if (!isAndroid)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 250,
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  )
                      : null,
                ),
                onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
              ),
            ),
          ),
        if (isAndroid)
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: onEnterSearchMode
          ),
        if (!isAndroid)
          isSyncing
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: () => ref.read(syncNotifierProvider.notifier).executeFullSync(),
            child: const Row(
              children: [
                Icon(Icons.sync),
                SizedBox(width: 8),
                Text("Sync"),
              ],
            ),
          ),
        const SizedBox(width: 8),
        if (isAndroid)
          _buildFilterMenu(ref, currentSortOption, currentPlatformFilter, colorScheme),
      ],
    );
  }

  Widget _buildFilterMenu(WidgetRef ref, NoteSortOption sortOption, PlatformOptions? platformFilter, ColorScheme colorScheme) {
    return PopupMenuButton<MenuOption>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Sort & Filter',
      onSelected: (MenuOption value) {
        switch (value) {
          case MenuOption.sortCreated:
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt);
            break;
          case MenuOption.sortName:
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name);
            break;
          case MenuOption.sortUpdated:
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt);
            break;
          case MenuOption.filterPhone:
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.android);
            break;
          case MenuOption.filterWindows:
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.windows);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
        const PopupMenuItem<MenuOption>(
          enabled: false,
          child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildSortItem(MenuOption.sortCreated, 'Created', sortOption == NoteSortOption.createdAt, colorScheme),
        _buildSortItem(MenuOption.sortName, 'Name', sortOption == NoteSortOption.name, colorScheme),
        _buildSortItem(MenuOption.sortUpdated, 'Last Updated', sortOption == NoteSortOption.updatedAt, colorScheme),
        const PopupMenuDivider(),
        const PopupMenuItem<MenuOption>(
          enabled: false,
          child: Text('FILTER PLATFORM', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildFilterItem(MenuOption.filterPhone, Icons.phone_android_outlined, 'Phone', platformFilter == PlatformOptions.android),
        _buildFilterItem(MenuOption.filterWindows, Icons.desktop_windows_outlined, 'Windows', platformFilter == PlatformOptions.windows),
      ],
    );
  }

  PopupMenuItem<MenuOption> _buildSortItem(MenuOption value, String label, bool isSelected, ColorScheme colorScheme) {
    return PopupMenuItem<MenuOption>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? colorScheme.primary : Colors.grey,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MenuOption> _buildFilterItem(MenuOption value, IconData icon, String label, bool isSelected) {
    return PopupMenuItem<MenuOption>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          IgnorePointer(child: Checkbox(value: isSelected, onChanged: (_) {})),
        ],
      ),
    );
  }
}

// SELECT MODE APP BAR
class SelectModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Set<int> noteIds;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;

  const SelectModeAppBar({
    super.key,
    required this.noteIds,
    required this.onClearSelection,
    required this.onSelectAll,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final currentNotes = ref.watch(filteredNotesProvider).value ?? [];
    final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

    return AppBar(
      backgroundColor: noteTheme.selectedAppBar,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClearSelection,
      ),
      title: Text('${noteIds.length} Selected', style: const TextStyle(color: Colors.white)),
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
            final driftDatabase = ref.read(noteDriftDatabaseProvider);
            await driftDatabase.softDeleteNotes(noteIds, platform: defaultTargetPlatform.name);
            ref.read(syncNotifierProvider.notifier).executeFullSync();
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

  const SearchModeAppBar({
    super.key,
    required this.searchController,
    required this.onExitSearchMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onExitSearchMode,
      ),
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