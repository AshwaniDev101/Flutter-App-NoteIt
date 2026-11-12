import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/logger.dart';
import '../../../../database/drift/folders/folders_dao.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../shared/app_bars/app_search_bar.dart';
import '../../viewmodel/folder_view_model.dart';
import '../folder_selector.dart';

enum SearchBarPosition { top, bottom }

class FolderSelectorContainer extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final String title;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool showEmptyNoteCount;
  final SearchBarPosition searchBarPosition;
  final bool allowContextMenus;
  final EdgeInsetsGeometry padding;

  const FolderSelectorContainer({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.title = 'Folders Filter',
    this.emptyLabel = 'All Notes',
    this.emptyIcon = Icons.format_align_left,
    this.showEmptyNoteCount = false,
    this.searchBarPosition = SearchBarPosition.bottom,
    this.allowContextMenus = true,
    this.padding = const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
  });

  @override
  ConsumerState<FolderSelectorContainer> createState() => _FolderSelectorContainerState();
}

class _FolderSelectorContainerState extends ConsumerState<FolderSelectorContainer> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(folderViewModelProvider.notifier).clearSearchQuery();
  }

  Widget _buildMenuItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showFolderContextMenu(BuildContext context, Folder folder, Offset? position) async {
    if (!widget.allowContextMenus) return;

    final Offset tapPosition = position ?? Offset.zero;
    RelativeRect menuPosition;

    if (tapPosition != Offset.zero) {
      menuPosition = RelativeRect.fromLTRB(
        tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1,
      );
    } else {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        final topLeft = box.localToGlobal(Offset.zero);
        final size = box.size;
        menuPosition = RelativeRect.fromLTRB(
          topLeft.dx + 16,
          topLeft.dy + size.height / 2,
          topLeft.dx + size.width,
          topLeft.dy + size.height,
        );
      } else {
        menuPosition = const RelativeRect.fromLTRB(100, 100, 101, 101);
      }
    }

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
          value: 'pin',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(
            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            isPinned ? 'Unpin' : 'Pin',
          ),
        ),
        PopupMenuItem(
          value: 'update',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.edit_outlined, 'Edit'),
        ),
        const PopupMenuDivider(height: 8),
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
    final viewModel = ref.read(folderViewModelProvider.notifier);

    switch (action) {
      case 'pin':
        await viewModel.togglePinStatus(folder.uuid);
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
          await viewModel.updateFolder(
            uuid: folder.uuid,
            name: result['name'],
            colorIndex: result['colorIndex'],
          );

          if (widget.selectedFolder?.uuid == folder.uuid) {
            final dao = ref.read(foldersDaoProvider);
            final updatedFolder = (await dao.select(dao.folders).get()).firstWhere((f) => f.uuid == folder.uuid);
            widget.onFolderSelected(updatedFolder);
          }
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
          await viewModel.softDeleteFolder(folder.uuid, platform: 'desktop');
          if (widget.selectedFolder?.uuid == folder.uuid) {
            widget.onFolderSelected(null);
          }
        }
        break;
    }
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FolderEditorDialog(),
    );

    if (result != null && mounted) {
      AppLogger.d("FolderSelectorContainer: User triggered folder creation '${result['name']}'");
      final viewModel = ref.read(folderViewModelProvider.notifier);
      final newUuid = await viewModel.createFolder(
        name: result['name'],
        colorIndex: result['colorIndex'],
      );

      final dao = ref.read(foldersDaoProvider);
      final allFolders = await dao.select(dao.folders).get();
      final newFolder = allFolders.where((f) => f.uuid == newUuid).firstOrNull;
      if (newFolder != null) {
        widget.onFolderSelected(newFolder);
      }
    }
  }

  Widget _buildSearchBarAndAddButton(BuildContext context, ColorScheme colorScheme) {
    final viewModel = ref.read(folderViewModelProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: AppSearchBar(
            controller: _searchController,
            hintText: 'Search folders...',
            fillColor: colorScheme.surfaceContainerLow,
            onChanged: (value) => viewModel.updateSearchQuery(value),
            onClear: _clearSearch,
          ),
        ),
        if (widget.allowContextMenus) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showCreateFolderDialog(context),
              icon: Icon(Icons.add_rounded, size: 22, color: colorScheme.onPrimaryContainer,),
              tooltip: 'New Folder',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final folderState = ref.watch(folderViewModelProvider);
    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    final totalNotesCountAsync = ref.watch(totalNotesCountStreamProvider);
    final allNoteCount = totalNotesCountAsync.value ?? 0;
    final activeFolder = widget.selectedFolder;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 6.0, right: 2.0, bottom: 8.0),
              child: Text(
                widget.title,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (widget.searchBarPosition == SearchBarPosition.top) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildSearchBarAndAddButton(context, colorScheme),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (folders) {
                final lowerQuery = folderState.searchQuery.toLowerCase().trim();
                final showEmptyOption = lowerQuery.isEmpty ||
                    widget.emptyLabel.toLowerCase().contains(lowerQuery) ||
                    'all notes'.contains(lowerQuery) ||
                    'no folder'.contains(lowerQuery) ||
                    'none'.contains(lowerQuery);

                final filteredFolders = folders.where((f) {
                  return f.folder.name.toLowerCase().contains(lowerQuery);
                }).toList();

                if (filteredFolders.isEmpty && !showEmptyOption) {
                  return Center(
                    child: Text(
                      "No results found",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (showEmptyOption)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
                            onTap: () => widget.onFolderSelected(null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: activeFolder == null
                                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Center(
                                      child: Icon(
                                        widget.emptyIcon,
                                        size: 18,
                                        color: activeFolder == null
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.emptyLabel,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: activeFolder == null ? FontWeight.w600 : FontWeight.w500,
                                        color: activeFolder == null
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (widget.showEmptyNoteCount)
                                    Flexible(
                                      flex: 0,
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: activeFolder == null
                                              ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$allNoteCount',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: activeFolder == null
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (showEmptyOption && filteredFolders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),

                    ...filteredFolders.map((folderWithCount) {
                      final folderData = folderWithCount.folder;
                      final isSelected = activeFolder?.uuid == folderData.uuid;

                      return FolderListItem(
                        folderWithCount: folderWithCount,
                        isSelected: isSelected,
                        allowPinning: widget.allowContextMenus,
                        onSelect: () => widget.onFolderSelected(folderData),
                        onContextMenu: widget.allowContextMenus ? (details) {
                          _showFolderContextMenu(context, folderData, details?.globalPosition);
                        } : null,
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          if (widget.searchBarPosition == SearchBarPosition.bottom) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 16.0),
              child: _buildSearchBarAndAddButton(context, colorScheme),
            ),
          ],
        ],
      ),
    );
  }
}
