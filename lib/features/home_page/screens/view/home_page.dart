import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/home_page/screens/view/widgets/home_app_bars.dart';
import 'package:noteit/features/home_page/screens/view/widgets/notes_grid_view.dart';
import 'package:noteit/features/home_page/screens/view/widgets/sort_options_bar.dart';
import 'package:noteit/features/home_page/screens/view/widgets/tab_view_state.dart';
import 'package:noteit/features/password_page/screens/view/password_page.dart';
import 'package:noteit/features/edit_note_page/screens/view/edit_note_page.dart';

import '../../../../shared/managers/lock_manger/lock_manager.dart';
import '../../../../database/sync_manager.dart';
import '../../../drawer_page/homepage_drawer.dart';
import '../core/providers.dart';
import '../viewmodel/home_view_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider.notifier).executeFullSync();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exitSearchMode() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(homeViewModelProvider.notifier).exitSearchMode();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // ViewModel State & Notifier
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Tab State & Notifier
    final tabState = ref.watch(tabViewModelProvider);
    final tabViewModel = ref.read(tabViewModelProvider.notifier);

    // Forces Riverpod to keep SyncManager awake
    ref.watch(syncNotifierProvider);

    return PopScope(
      canPop: !homeState.isSelectMode && !homeState.isSearchMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (homeState.isSelectMode) {
          viewModel.clearSelection();
        } else if (homeState.isSearchMode) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
        drawer: const HomepageDrawer(),
        appBar: _buildResponsiveAppBar(isAndroid, homeState, viewModel),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!isAndroid) {
              final emptyNote = Note(
                id: DateTime.now().millisecondsSinceEpoch,
                title: '',
                content: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isLocked: false,
                isPinned: false,
                color: 0,
                isArchived: false,
                position: 0,
                hasAttachments: false,
                contentType: 'text',
                isShared: false,
                syncStatus: 0,
                versionCounter: 1,
              );
              tabViewModel.openTab(emptyNote);
            } else {
              context.push(AppRoutes.edit);
            }
          },
          child: const Icon(Icons.add),
        ),
        // Permanently show Split View on Desktop/Web, Standard View on Android
        body: !isAndroid
            ? _buildSplitTabView(homeState, viewModel, tabState, tabViewModel, isAndroid)
            : _buildStandardGridView(homeState, viewModel, isAndroid),
      ),
    );
  }

  Widget _buildSplitTabView(
      HomePageState homeState,
      HomeViewModel viewModel,
      TabViewState tabState,
      TabViewModel tabViewModel,
      bool isAndroid,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: _buildStandardGridView(homeState, viewModel, isAndroid),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _buildDesktopTabView(tabState, tabViewModel),
        ),
      ],
    );
  }

  Widget _buildStandardGridView(HomePageState homeState, HomeViewModel viewModel, bool isAndroid) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!homeState.isSearchMode && !isAndroid) const SortOptionsBar(),
          Expanded(
            child: NotesGridView(
              isSelectMode: homeState.isSelectMode,
              noteIds: homeState.selectedNoteIds,
              onToggleSelection: viewModel.toggleSelection,
              onEnableSelectMode: viewModel.enableSelectMode,
              onPromptPassword: _promptForPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTabView(TabViewState tabState, TabViewModel tabViewModel) {
    if (tabState.openTabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No tabs open',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a note from the sidebar or click + to start editing.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 40,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabState.openTabs.length,
            itemBuilder: (context, index) {
              final note = tabState.openTabs[index];
              final isActive = index == tabState.activeTabIndex;

              return GestureDetector(
                onTap: () => tabViewModel.switchTab(index),
                child: Container(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                        onPressed: () => tabViewModel.closeTab(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: tabState.activeTabIndex,
            children: tabState.openTabs.map((note) {
              // --- RENDER THE ACTUAL EDITOR HERE ---
              return EditNotePage(
                key: ValueKey(note.id), // Important: Key ensures state refreshes correctly when switching tabs
                existingNote: note,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
      bool isAndroid,
      HomePageState state,
      HomeViewModel viewModel,
      ) {
    if (state.isSelectMode) {
      return SelectModeAppBar(
        noteIds: state.selectedNoteIds,
        onClearSelection: viewModel.clearSelection,
        onSelectAll: () {
          final currentNotes = ref.read(filteredNotesProvider).value ?? [];
          final allNoteIds = currentNotes.map((note) => note.id).toList();
          viewModel.toggleSelectAll(allNoteIds);
        },
      );
    }

    if (state.isSearchMode) {
      return SearchModeAppBar(
        searchController: _searchController,
        onExitSearchMode: _exitSearchMode,
      );
    }

    return DefaultHomeAppBar(
      isAndroid: isAndroid,
      searchController: _searchController,
      onEnterSearchMode: viewModel.enterSearchMode,
    );
  }

  Future<void> _promptForPassword(BuildContext context, Note note) async {
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const PasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null && enteredPassword.isNotEmpty && context.mounted) {
      final lockManager = ref.read(lockManagerProvider.notifier);

      if (!lockManager.hasMasterPassword) {
        await lockManager.setupMasterPassword(enteredPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Master Password Set!')),
        );
      }

      final success = lockManager.verifyAndSessionUnlock(note.id, enteredPassword);
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;

      if (success) {
        if (!isAndroid) {
          ref.read(tabViewModelProvider.notifier).openTab(note);
        } else {
          context.push(AppRoutes.edit, extra: note);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect Password')),
        );
      }
    }
  }
}