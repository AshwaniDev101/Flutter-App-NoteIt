export 'dialogs/folder_editor_dialog.dart';
export 'widgets/folder_list_item.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../shared/app_bars/app_search_bar.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import 'dialogs/folder_editor_dialog.dart';
import 'widgets/folder_list_item.dart';

final activeFoldersStreamProvider = StreamProvider<List<FolderWithCount>>((ref) {
  final foldersDao = ref.watch(foldersDaoProvider);
  return foldersDao.watchActiveFoldersWithCounts();
});

final totalNotesCountStreamProvider = StreamProvider<int>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchActiveNotesCount();
});

/// Reusable folder selection button and dropdown.
///
/// It relies on the parent to provide the [selectedFolder] and handle
/// the [onFolderSelected] action.
class FolderButton extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final bool showContextMenus;
  final String emptyLabel;
  final bool isShowTotalNoteCount;

  const FolderButton({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.showContextMenus = true,
    this.emptyLabel = 'All Notes',
    this.isShowTotalNoteCount = false,
  });

  @override
  ConsumerState<FolderButton> createState() => _FolderButtonState();
}

class _FolderButtonState extends ConsumerState<FolderButton> {
  final MenuController _menuController = MenuController();
  bool _isHovering = false;

  void _showMobileBottomSheet(BuildContext context) {
    Folder? localSelectedFolder = widget.selectedFolder;

    AppBottomSheet.show(
      context: context,
      heightFactor: 0.5,
      builder: (context, setModalState) {
        return FolderContainer(
          selectedFolder: localSelectedFolder,
          emptyLabel: widget.emptyLabel,
          showContextMenus: widget.showContextMenus,
          onFolderSelected: (folder) {
            widget.onFolderSelected(folder);
            setModalState(() {
              localSelectedFolder = folder;
            });
          },
        );
      },
    );
  }

  Widget _buildTriggerButton(BuildContext context, {required bool isOpen, required VoidCallback onTap}) {
    final Folder? activeFolder = widget.selectedFolder;
    final colorScheme = Theme.of(context).colorScheme;

    final currentName = activeFolder?.name ?? widget.emptyLabel;
    final currentColor = activeFolder != null
        ? Colors.primaries[activeFolder.colorIndex % Colors.primaries.length]
        : colorScheme.onSurfaceVariant;

    final totalNotesCountAsync = ref.watch(totalNotesCountStreamProvider);
    final allNoteCount = totalNotesCountAsync.value ?? 0;

    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    int displayCount = allNoteCount;

    if (activeFolder != null && foldersAsync.hasValue) {
      final match = foldersAsync.value!.where((f) => f.folder.uuid == activeFolder.uuid).firstOrNull;
      if (match != null) {
        displayCount = match.noteCount;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onHover: (val) => setState(() => _isHovering = val),
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isOpen || _isHovering
                      ? colorScheme.outlineVariant
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(10),
                color: isOpen
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                    : _isHovering
                    ? colorScheme.surfaceContainerLowest
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeFolder != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      currentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOpen ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isOpen ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isShowTotalNoteCount) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$displayCount',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !PlatformHelper.isWideLayout(context);

    if (isMobile) {
      return _buildTriggerButton(
        context,
        isOpen: false,
        onTap: () => _showMobileBottomSheet(context),
      );
    }

    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return _buildTriggerButton(
          context,
          isOpen: controller.isOpen,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 280,
              height: 480,
              child: FolderContainer(
                selectedFolder: widget.selectedFolder,
                emptyLabel: widget.emptyLabel,
                showContextMenus: widget.showContextMenus,
                onFolderSelected: (folder) {
                  widget.onFolderSelected(folder);
                  _menuController.close();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FolderContainer extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final bool showContextMenus;
  final String emptyLabel;

  const FolderContainer({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    required this.showContextMenus,
    required this.emptyLabel,
  });

  @override
  ConsumerState<FolderContainer> createState() => _FolderContainerState();
}

class _FolderContainerState extends ConsumerState<FolderContainer> {
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
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _folderSearchQuery = '';
    });
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
    if (!widget.showContextMenus) return;

    final Offset tapPosition = position ?? Offset.zero;
    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1,
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
        widget.onFolderSelected(folder);
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

          if (widget.selectedFolder?.uuid == folder.uuid) {
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
          await dao.softDeleteFolder(folder.uuid, platform: 'desktop');
          if (widget.selectedFolder?.uuid == folder.uuid) {
            widget.onFolderSelected(null);
          }
        }
        break;
    }
  }

  Future<void> _showCreateFolderDialog(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    final totalNotesCountAsync = ref.watch(totalNotesCountStreamProvider);
    final allNoteCount = totalNotesCountAsync.value ?? 0;
    final activeFolder = widget.selectedFolder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Label
          Padding(
            padding: const EdgeInsets.only(left: 6.0, right: 2.0, bottom: 8.0),
            child: Text(
              "Folders Filter",
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),

          // Folders List (Middle)
          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (folders) {
                if (folders.isEmpty && _folderSearchQuery.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.create_new_folder_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.showContextMenus
                                ? "No folders yet.\nPress + to create one."
                                : "No folders available.",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final lowerQuery = _folderSearchQuery.toLowerCase();
                final showEmptyOption = 'all notes'.contains(lowerQuery) ||
                    widget.emptyLabel.toLowerCase().contains(lowerQuery) ||
                    _folderSearchQuery.isEmpty;

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
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: activeFolder == null
                                    ? colorScheme.secondaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Center(
                                      child: Icon(
                                        Icons.format_align_left,
                                        size: 18,
                                        color: activeFolder == null
                                            ? colorScheme.onSecondaryContainer
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
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  // Badge for count
                                  Flexible(
                                    flex: 0,
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8.0, right: 4.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: activeFolder == null
                                            ? colorScheme.onSecondaryContainer.withValues(alpha: 0.1)
                                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$allNoteCount',
                                        style: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: activeFolder == null
                                              ? colorScheme.onSecondaryContainer
                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                        child: Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3)
                        ),
                      ),

                    ...filteredFolders.map((folderWithCount) {
                      final folderData = folderWithCount.folder;
                      final isSelected = activeFolder?.uuid == folderData.uuid;

                      return FolderListItem(
                        folderWithCount: folderWithCount,
                        isSelected: isSelected,
                        allowPinning: widget.showContextMenus,
                        onSelect: () => widget.onFolderSelected(folderData),
                        onContextMenu: widget.showContextMenus ? (details) {
                          _showFolderContextMenu(context, folderData, details?.globalPosition);
                        } : null,
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // Bottom Bar: Search Bar "+Add Folder" Button on the right
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search...',
                    fillColor: colorScheme.surfaceContainerLow,
                    onChanged: (value) => setState(() => _folderSearchQuery = value),
                    onClear: _clearSearch,
                  ),
                ),
                if (widget.showContextMenus) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showCreateFolderDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 22),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
