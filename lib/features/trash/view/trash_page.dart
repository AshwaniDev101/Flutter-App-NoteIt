import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import '../../../shared/app_bars/floating_bottom_app_bar.dart';
import '../../../shared/app_bars/top_select_mode_appbar.dart';
import '../../../shared/note_card/core/note_action.dart';
import '../../../shared/overlays/app_scaffold.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../home/view/shared/desktop_close_button.dart';
import '../providers/trash_providers.dart';
import 'widgets/trash_content_area.dart';
import 'widgets/trash_control_bar.dart';

// ==========================================
// TRASH PAGE WIDGET (VIEW LAYER)
// ==========================================

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> with WidgetsBindingObserver {
  bool _wasKeyboardOpen = false;
  late final TrashViewModel _trashViewModel;

  @override
  void initState() {
    super.initState();
    _trashViewModel = ref.read(trashViewModelProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    Future.microtask(() => _trashViewModel.clearSelection());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    if (_wasKeyboardOpen && !isKeyboardOpen) {
      final searchQuery = ref.read(trashSearchQueryProvider);
      if (searchQuery.isNotEmpty && !PlatformHelper.isWideLayout(context) && mounted) {
        ref.read(trashSearchQueryProvider.notifier).clear();
      }
    }
    _wasKeyboardOpen = isKeyboardOpen;
  }

  // ------------------------------------------
  // ASYNC DIALOG ACTIONS
  // ------------------------------------------

  Future<void> _handleEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all notes and folders in the trash. Action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        SnackBarManager.show(msg: 'Emptying trash...', type: SnackBarMessageType.info);

        await ref.read(trashViewModelProvider.notifier).emptyTrash();

        if (mounted) {
          SnackBarManager.show(msg: 'Trash emptied successfully.', type: SnackBarMessageType.acknowledgment);
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(msg: 'Error emptying trash', description: '$e', type: SnackBarMessageType.error);
        }
      }
    }
  }

  Future<void> _restoreItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    try {
      final restoredCount = await ref.read(trashViewModelProvider.notifier).restoreItems(
            noteUuids: noteUuids,
            folderUuids: folderUuids,
          );

      if (mounted) {
        SnackBarManager.show(
          msg: restoredCount == 1 ? 'Item restored.' : '$restoredCount items restored.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarManager.show(msg: 'Error restoring items', description: '$e', type: SnackBarMessageType.error);
      }
    }
  }

  Future<void> _handleDeleteItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    final totalCount = (noteUuids?.length ?? 0) + (folderUuids?.length ?? 0);
    if (totalCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'This will permanently delete ${totalCount == 1 ? 'this item' : 'the $totalCount selected items'}. Action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(trashViewModelProvider.notifier).deleteItems(
              noteUuids: noteUuids,
              folderUuids: folderUuids,
            );

        if (mounted) {
          SnackBarManager.show(
            msg: totalCount == 1 ? 'Item deleted permanently.' : 'Selected items deleted permanently.',
            type: SnackBarMessageType.acknowledgment,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(msg: 'Error deleting items', description: '$e', type: SnackBarMessageType.error);
        }
      }
    }
  }

  // ------------------------------------------
  // APP BAR BUILDERS WITH ANIMATION
  // ------------------------------------------

  PreferredSizeWidget _buildAppBar(
    TrashState trashState,
    List<NoteWithFolder> currentNotes,
    List<Folder> currentFolders,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(trashState.isSelectMode),
          child: trashState.isSelectMode
              ? _buildSelectionAppBar(trashState, currentNotes, currentFolders)
              : _buildStandardAppBar(currentNotes.length + currentFolders.length),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    TrashState trashState,
    List<NoteWithFolder> currentNotes,
    List<Folder> currentFolders,
  ) {
    final combinedSelectedCount = trashState.selectedNoteIds.length + trashState.selectedFolderIds.length;

    return TopSelectModeAppBar(
      selectedCount: combinedSelectedCount,
      onClearSelection: () => ref.read(trashViewModelProvider.notifier).clearSelection(),
      onSelectAll: () {
        ref.read(trashViewModelProvider.notifier).toggleSelectAll(currentNotes, currentFolders);
      },
      noteActions: const [
        NoteAction.restore,
        NoteAction.deleteForever,
      ],
      onActionSelected: (action) {
        if (action == NoteAction.restore) {
          _restoreItems(
            noteUuids: trashState.selectedNoteIds.toList(),
            folderUuids: trashState.selectedFolderIds.toList(),
          );
        } else if (action == NoteAction.deleteForever) {
          _handleDeleteItems(
            noteUuids: trashState.selectedNoteIds.toList(),
            folderUuids: trashState.selectedFolderIds.toList(),
          );
        }
      },
    );
  }

  PreferredSizeWidget _buildStandardAppBar(int totalItems) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Trash Bin'),
      backgroundColor: colorScheme.surfaceContainerLowest,
      centerTitle: true,
      actions: [
        if (totalItems > 0)
          IconButton(
            onPressed: _handleEmptyTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty Trash',
          ),
        const SizedBox(width: 8),
        const DesktopCloseButton(),
      ],
    );
  }

  // ------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final trashState = ref.watch(trashViewModelProvider);
    final viewModel = ref.read(trashViewModelProvider.notifier);

    final trashNotesState = ref.watch(trashNotesProvider);
    final trashFoldersState = ref.watch(trashFoldersProvider);

    final filteredNotesAsync = ref.watch(filteredTrashNotesProvider);
    final filteredFoldersAsync = ref.watch(filteredTrashFoldersProvider);

    final currentView = ref.watch(trashNoteViewTypeProvider);
    final searchQuery = ref.watch(trashSearchQueryProvider);

    final rawNotes = trashNotesState.value ?? [];
    final rawFolders = trashFoldersState.value ?? [];
    final hasAnyTrashItems = rawNotes.isNotEmpty || rawFolders.isNotEmpty;

    return AppScaffold(
      appBar: _buildAppBar(trashState, rawNotes, rawFolders),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Column(
          children: [
            if (PlatformHelper.isWideLayout(context)) const TrashControlBar(),

            Expanded(
              child: filteredNotesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (filteredNotes) {
                  return filteredFoldersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                    data: (filteredFolders) {
                      return TrashContentArea(
                        filteredNotes: filteredNotes,
                        filteredFolders: filteredFolders,
                        hasAnyTrashItems: hasAnyTrashItems,
                        currentView: currentView,
                        searchQuery: searchQuery,
                        isSelectMode: trashState.isSelectMode,
                        selectedNoteIds: trashState.selectedNoteIds,
                        selectedFolderIds: trashState.selectedFolderIds,
                        onToggleNoteSelection: viewModel.toggleNoteSelection,
                        onToggleFolderSelection: viewModel.toggleFolderSelection,
                        onEnterSelectMode: viewModel.enableSelectMode,
                        onRestoreItems: _restoreItems,
                        onDeleteItems: _handleDeleteItems,
                      );
                    },
                  );
                },
              ),
            ),

            if (!PlatformHelper.isWideLayout(context) && !trashState.isSelectMode)
              const FloatingBottomAppBar(
                child: TrashControlBar(),
              ),
          ],
        ),
      ),
    );
  }
}
