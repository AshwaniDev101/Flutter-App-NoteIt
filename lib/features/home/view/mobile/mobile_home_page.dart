import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/view/shared/select_mode_app_bars.dart';
import 'package:noteit/features/home/view/shared/websocket_connection_indicator.dart';

import '../../../../../database/sync/sync_orchestrator.dart';
import '../../../../database/sync/local_sync_service.dart';
import '../../viewmodel/viewmodel.dart';
import '../shared/spinning_sync_icon.dart';
import '../../../drawer/homepage_drawer.dart';
import '../../core/providers.dart';
import '../shared/dynamic_notes_layout.dart';
import '../../../lock/password_prompt_helper.dart';
import '../shared/tag_sort_view_menu.dart';

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

    // _searchController.addListener(() => setState(() {}));
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

    final colorScheme = Theme.of(context).colorScheme;

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        drawer: const Drawer(child: HomepageDrawer()),
        appBar: _buildAppBar(homeState, viewModel),
        floatingActionButton: FloatingActionButton(

          onPressed: () => context.push(AppRoutes.edit),
            elevation: 3,
          child: const Icon(Icons.edit),
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

                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, child) {
                            return value.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearSearch)
                                : const SizedBox.shrink();
                          },
                        ),

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

                  FolderSortViewButton(),

                  // SortFilterOptionMenu(),
                  // _buildFilterMenu(
                  //   currentSortOption,
                  //   currentPlatformFilter,
                  //   colorScheme,
                  // ),
                ],
              ),
            ),
            Expanded(

              child: DynamicNotesLayout(
                isSelectMode: homeState.isSelectMode,
                noteIds: homeState.selectedNoteIds,
                activeNoteId: null,
                onToggleSelection: viewModel.toggleSelection,
                onEnableSelectMode: viewModel.enableSelectMode,
                onNoteTap: _handleNoteTap,
              ),
              // child: NotesGridView(
              //   isSelectMode: homeState.isSelectMode,
              //   noteIds: homeState.selectedNoteIds,
              //   // NotesGridView expects a Set<String>
              //   activeNoteId: null,
              //   onToggleSelection: viewModel.toggleSelection,
              //   onEnableSelectMode: viewModel.enableSelectMode,
              //   onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
              //   onNoteTap: _handleNoteTap,
              // ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomePageState state, HomeViewModel viewModel) {
    // Just to get Connection state from local sync service
    final SyncConnectionState syncConnectionState = ref.watch(localSyncServiceProvider);
    final isConnected = syncConnectionState == SyncConnectionState.connected;
    // Getting the sync state from the orchestrator
    final isSyncing = ref.watch(isSyncingProvider);

    if (state.isSelectMode) {
      return SelectModeAppBar(
        noteIds: state.selectedNoteIds,
        onClearSelection: viewModel.clearSelection,
        onSelectAll: () {
          // Map to UUIDs instead of integer IDs
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
        WebSocketConnectionIndicator(isConnected: isConnected),
        IconButton(
          // icon: const Icon(Icons.sync),
          icon: SpinningSyncIcon(isSyncing: isSyncing, color: Theme.of(context).colorScheme.primary),
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
}
