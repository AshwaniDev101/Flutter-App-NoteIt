import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/theme/folder_theme_colors.dart';

import '../../../core/sync/sync_orchestrator.dart';
import '../../../core/util/logger.dart';
import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../shared/app_bars/app_search_bar.dart';
import '../../../shared/overlays/app_scaffold.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../providers/folder_providers.dart';
import '../viewmodel/folder_view_model.dart';
import 'dialogs/folder_editor_dialog.dart';
import 'widgets/folder_context_menu.dart';

/// Full-page / right-panel folder selector & management page in a Grid format.
class MoveToFolderPage extends ConsumerStatefulWidget {
  final List<String>? targetNoteUuids;
  final ValueChanged<Folder?>? onFolderSelected;

  const MoveToFolderPage({
    super.key,
    this.targetNoteUuids,
    this.onFolderSelected,
  });

  @override
  ConsumerState<MoveToFolderPage> createState() => _MoveToFolderPageState();
}

class _MoveToFolderPageState extends ConsumerState<MoveToFolderPage> {
  String _folderSearchQuery = '';
  late final TextEditingController _searchController;
  late final MovingNoteIdsNotifier _movingNoteNotifier;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _movingNoteNotifier = ref.read(movingNoteIdsProvider.notifier);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Auto-clean target note IDs state if user leaves without selecting
    Future.microtask(() => _movingNoteNotifier.clear());
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _folderSearchQuery = '';
    });
  }

  Future<void> _showCreateFolderDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FolderEditorDialog(),
    );

    if (result != null && mounted) {
      AppLogger.d("MoveToFolderPage: User triggered folder creation '${result['name']}'");
      await ref.read(folderViewModelProvider.notifier).createFolder(
        name: result['name'],
        colorIndex: result['colorIndex'],
      );
    }
  }

  Future<void> _handleFolderSelected(Folder folder) async {
    if (widget.onFolderSelected != null) {
      widget.onFolderSelected!(folder);
      return;
    }

    final List<String> targetUuids = widget.targetNoteUuids ?? ref.read(movingNoteIdsProvider);

    if (targetUuids.isNotEmpty) {
      final updatedCount = await ref.read(folderViewModelProvider.notifier).moveNotesToFolder(
            targetUuids: targetUuids,
            folderUuid: folder.uuid,
          );

      // Clear pending moving note IDs state
      ref.read(movingNoteIdsProvider.notifier).clear();

      if (mounted) {
        final String message = updatedCount > 0
            ? (updatedCount == 1
                ? 'Moved 1 note to "${folder.name}"'
                : 'Moved $updatedCount notes to "${folder.name}"')
            : 'Note(s) already in "${folder.name}"';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        ref.read(drawerNavigationProvider).pop(context);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    final pendingMovingNoteIds = ref.watch(movingNoteIdsProvider);
    final effectiveTargetIds = widget.targetNoteUuids ?? pendingMovingNoteIds;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.moveToFolder,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Action Bar: Search Bar + Add Folder Button
            Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search folders...',
                    fillColor: colorScheme.surfaceContainerLow,
                    onChanged: (value) => setState(() => _folderSearchQuery = value),
                    onClear: _clearSearch,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showCreateFolderDialog,
                    icon: const Icon(Icons.add_rounded, size: 24),
                    tooltip: 'New Folder',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (effectiveTargetIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.drive_file_move_outlined,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select a folder to move ${effectiveTargetIds.length} ${effectiveTargetIds.length == 1 ? 'note' : 'notes'}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Grid View Content
            Expanded(
              child: foldersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (folders) {
                  final lowerQuery = _folderSearchQuery.toLowerCase();
                  final filteredFolders = folders.where((f) {
                    return f.folder.name.toLowerCase().contains(lowerQuery);
                  }).toList();

                  if (filteredFolders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _folderSearchQuery.isEmpty
                                ? Icons.create_new_folder_outlined
                                : Icons.folder_off_outlined,
                            size: 56,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _folderSearchQuery.isEmpty
                                ? "No folders yet.\nPress + to create one."
                                : "No folders found matching \"$_folderSearchQuery\".",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredFolders.length,
                    itemBuilder: (context, index) {
                      final item = filteredFolders[index];
                      return _FolderGridCard(
                        folderWithCount: item,
                        onTap: () => _handleFolderSelected(item.folder),
                        onContextMenu: (details) {
                          FolderContextMenu.show(
                            context: context,
                            ref: ref,
                            folder: item.folder,
                            position: details?.globalPosition,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderGridCard extends ConsumerStatefulWidget {
  final FolderWithCount folderWithCount;
  final VoidCallback onTap;
  final Function(TapUpDetails?) onContextMenu;

  const _FolderGridCard({
    required this.folderWithCount,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  ConsumerState<_FolderGridCard> createState() => _FolderGridCardState();
}

class _FolderGridCardState extends ConsumerState<_FolderGridCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final folder = widget.folderWithCount.folder;
    final noteCount = widget.folderWithCount.noteCount;
    final isPinned = folder.pinnedAt != null;
    final folderAccentColor = FolderThemeColors.of(context, folder.colorIndex);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () => widget.onContextMenu(null),
        onSecondaryTapUp: widget.onContextMenu,
        onHover: (hovering) => setState(() => _isHovering = hovering),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovering
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovering
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Color indicator dot & Pin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: folderAccentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: folderAccentColor.withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  if (isPinned || _isHovering)
                    GestureDetector(
                      onTap: () {
                        ref.read(foldersDaoProvider).toggleFolderPinStatus(folder.uuid);
                        ref.read(syncOrchestratorProvider).triggerSync();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          size: 14,
                          color: isPinned ? folderAccentColor : folderAccentColor.withValues(alpha: 0.2),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                ],
              ),

              // Center: Big Folder Icon inside a soft tinted circular container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: folderAccentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_rounded,
                  size: 32,
                  color: folderAccentColor,
                ),
              ),

              // Bottom: Folder Name & Note Count
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
