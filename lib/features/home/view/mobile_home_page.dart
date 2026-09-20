import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/home/view/widgets/home_app_bars.dart';
import 'package:noteit/features/home/view/widgets/notes_grid_view.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../../drawer/homepage_drawer.dart';
import '../core/providers.dart';
import '../core/sort.dart';
import '../core/options.dart';
import '../viewmodel/home_view_model.dart';
import 'password_prompt_helper.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(homeViewModelProvider.notifier).exitSearchMode();
  }

  void _handleNoteTap(Note note) async {
    if (note.isLocked) {
      final success = await PasswordPromptHelper.promptAndVerify(context, ref, note);
      if (success && mounted) {
        context.push(AppRoutes.edit, extra: note);
      }
    } else {
      context.push(AppRoutes.edit, extra: note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        drawer: const HomepageDrawer(),
        appBar: _buildAppBar(homeState, viewModel),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.edit),
          child: const Icon(Icons.add),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearSearch)
                            : null,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onTap: () {
                        if (!homeState.isSearchMode) viewModel.enterSearchMode();
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
                        if (value.isEmpty) {
                          _clearSearch();
                        } else {
                          ref.read(searchQueryProvider.notifier).updateQuery(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterMenu(currentSortOption, currentPlatformFilter, colorScheme),
                ],
              ),
            ),
            Expanded(
              child: NotesGridView(
                isSelectMode: homeState.isSelectMode,
                noteIds: homeState.selectedNoteIds,
                // Make sure NotesGridView expects a Set<String> now!
                activeNoteId: null,
                onToggleSelection: viewModel.toggleSelection,
                onEnableSelectMode: viewModel.enableSelectMode,
                onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
                onNoteTap: _handleNoteTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomePageState state, HomeViewModel viewModel) {
    if (state.isSelectMode) {
      return SelectModeAppBar(
        noteIds: state.selectedNoteIds,
        onClearSelection: viewModel.clearSelection,
        onSelectAll: () {
          // FIXED: Map to UUIDs instead of integer IDs
          final allNoteUuids = (ref.read(filteredNotesProvider).value ?? []).map((n) => n.uuid).toList();
          viewModel.toggleSelectAll(allNoteUuids);
        },
      );
    }
    return AppBar(
      title: const Text('Notes'),
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Sync Notes',
          onPressed: () {
            ref.read(syncOrchestratorProvider).triggerSync();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing notes...')));
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterMenu(
    NoteSortOption currentSortOption,
    PlatformOptions? currentPlatformFilter,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Sort & Filter',
      onSelected: (String value) {
        switch (value) {
          case 'sortCreated':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt);
            break;
          case 'sortName':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name);
            break;
          case 'sortUpdated':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt);
            break;
          case 'filterPhone':
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.android);
            break;
          case 'filterWindows':
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.windows);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildSortItem('sortCreated', 'Created', currentSortOption == NoteSortOption.createdAt, colorScheme),
        _buildSortItem('sortName', 'Name', currentSortOption == NoteSortOption.name, colorScheme),
        _buildSortItem('sortUpdated', 'Last Updated', currentSortOption == NoteSortOption.updatedAt, colorScheme),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('FILTER PLATFORM', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildFilterItem(
          'filterPhone',
          Icons.phone_android_outlined,
          'Phone',
          currentPlatformFilter == PlatformOptions.android,
        ),
        _buildFilterItem(
          'filterWindows',
          Icons.desktop_windows_outlined,
          'Windows',
          currentPlatformFilter == PlatformOptions.windows,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, bool isSelected, ColorScheme colorScheme) {
    return PopupMenuItem<String>(
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

  PopupMenuItem<String> _buildFilterItem(String value, IconData icon, String label, bool isSelected) {
    return PopupMenuItem<String>(
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
          IgnorePointer(
            child: Checkbox(value: isSelected, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}
