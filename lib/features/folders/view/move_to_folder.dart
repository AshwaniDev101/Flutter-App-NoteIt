import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../shared/app_bars/app_search_bar.dart';
import '../../../shared/overlays/app_scaffold.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../core/providers.dart';
import 'folder_selector.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Auto-clean target note IDs state if user leaves without selecting
    Future.microtask(() {
      ref.read(movingNoteIdsProvider.notifier).clear();
    });
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
      final dao = ref.read(foldersDaoProvider);
      await dao.addFolder(
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
      final notesDao = ref.read(notesDaoProvider);
      int updatedCount = 0;

      for (final uuid in targetUuids) {
        final success = await notesDao.updateNoteFolder(uuid, folder.uuid);
        if (success) updatedCount++;
      }

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

  Widget _buildMenuItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showFolderContextMenu(BuildContext context, Folder folder, Offset? position) async {
    final Offset tapPosition = position ?? Offset.zero;
    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      tapPosition.dx,
      tapPosition.dy,
      tapPosition.dx + 1,
      tapPosition.dy + 1,
    );

    final isPinned = folder.pinnedAt != null;
    final errorColor = Theme.of(context).colorScheme.error;

    final selectedAction = await showMenu<String>(
      context: context,
      position: menuPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 160),
      items: [
        PopupMenuItem(
          value: 'open',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.folder_open_rounded, 'Select'),
        ),
        PopupMenuItem(
          value: 'pin',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(
            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            isPinned ? 'Unpin' : 'Pin',
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'update',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.edit_outlined, 'Update'),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.delete_outline_rounded, 'Delete', color: errorColor),
        ),
      ],
    );

    if (selectedAction != null && mounted) {
      _handleContextMenuAction(selectedAction, folder);
    }
  }

  Future<void> _handleContextMenuAction(String action, Folder folder) async {
    final dao = ref.read(foldersDaoProvider);

    switch (action) {
      case 'open':
        await _handleFolderSelected(folder);
        break;

      case 'pin':
        await dao.toggleFolderPinStatus(folder.uuid);
        break;

      case 'update':
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => FolderEditorDialog(
            initialName: folder.name,
            initialColorIndex: folder.colorIndex,
          ),
        );

        if (result != null && mounted) {
          await dao.updateFolder(
            uuid: folder.uuid,
            name: result['name'],
            colorIndex: result['colorIndex'],
          );
        }
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Folder?'),
            content: Text('Are you sure you want to delete "${folder.name}"?\nNotes inside will be kept safely.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          await dao.softDeleteFolder(folder.uuid, platform: 'desktop');
        }
        break;
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
                          _showFolderContextMenu(context, item.folder, details?.globalPosition);
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
    final folderAccentColor = Colors.primaries[folder.colorIndex % Colors.primaries.length];

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
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          size: 14,
                          color: isPinned ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
