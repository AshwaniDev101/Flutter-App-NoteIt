import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';

final activeFoldersStreamProvider = StreamProvider<List<FolderWithCount>>((ref) {
  final foldersDao = ref.watch(foldersDaoProvider);
  return foldersDao.watchActiveFoldersWithCounts();
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

  const FolderButton({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.showContextMenus = true,
    this.emptyLabel = 'All Notes',
  });

  @override
  ConsumerState<FolderButton> createState() => _FolderButtonState();
}

class _FolderButtonState extends ConsumerState<FolderButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final Folder? activeFolder = widget.selectedFolder;

    final currentName = activeFolder?.name ?? widget.emptyLabel;
    final currentColor = activeFolder != null
        ? Colors.primaries[activeFolder.colorIndex % Colors.primaries.length]
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        final isOpen = controller.isOpen;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
                color: isOpen
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Only show the circle AND its spacing if a folder is selected
                  if (activeFolder != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    currentName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 240,
              height: 500,
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
        Text(label, style: TextStyle(fontSize: 14, color: color)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 6,
      constraints: const BoxConstraints(minWidth: 160),
      items: [
        PopupMenuItem(
          value: 'open',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.folder_open, 'Select'),
        ),
        PopupMenuItem(
          value: 'pin',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(isPinned ? Icons.push_pin : Icons.push_pin_outlined, isPinned ? 'Unpin' : 'Pin'),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'update',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.edit_outlined, 'Update'),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuItem(Icons.delete_outline, 'Delete', color: errorColor),
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

          // If the updated folder was the selected one, bubble the updated folder up
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
    final activeFolder = widget.selectedFolder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "FOLDERS",
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.showContextMenus) // Only allow creation if context menus are enabled
                  IconButton(
                    onPressed: () => _showCreateFolderDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'New Folder',
                    visualDensity: VisualDensity.compact,
                    color: colorScheme.onSurfaceVariant,
                  )
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: TextField(
              controller: _searchController,
              style: textTheme.bodyMedium,
              onChanged: (value) {
                setState(() {
                  _folderSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'Search...',
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    return value.text.isNotEmpty
                        ? ExcludeFocus(
                      child: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                        : const SizedBox.shrink();
                  },
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Handle the Reactive Stream Data
          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                            size: 42,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.showContextMenus
                                ? "No folders yet.\nPress + to create one."
                                : "No folders available.",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Check against both "all notes" and whatever custom label was provided
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
                  children: [
                    if (showEmptyOption)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
                            onTap: () => widget.onFolderSelected(null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: activeFolder == null ? colorScheme.secondaryContainer : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    // child: Center(
                                    //   child: Icon(Icons.all_inbox, size: 18),
                                    // ),
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
                                ],
                              ),
                            ),
                          ),
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
        ],
      ),
    );
  }
}

class FolderListItem extends ConsumerStatefulWidget {
  final FolderWithCount folderWithCount;
  final bool isSelected;
  final bool allowPinning;
  final VoidCallback onSelect;
  final Function(TapUpDetails?)? onContextMenu;

  const FolderListItem({
    super.key,
    required this.folderWithCount,
    required this.isSelected,
    required this.allowPinning,
    required this.onSelect,
    required this.onContextMenu,
  });

  @override
  ConsumerState<FolderListItem> createState() => _FolderListItemState();
}

class _FolderListItemState extends ConsumerState<FolderListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final folderData = widget.folderWithCount.folder;
    final noteCount = widget.folderWithCount.noteCount.toString();
    final folderAccentColor = Colors.primaries[folderData.colorIndex % Colors.primaries.length];
    final bool isPinned = folderData.pinnedAt != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          onTap: widget.onSelect,
          onLongPress: widget.onContextMenu != null ? () => widget.onContextMenu!(null) : null,
          onSecondaryTapUp: widget.onContextMenu,
          onHover: (hovering) {
            setState(() {
              _isHovering = hovering;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: widget.isSelected ? colorScheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 100) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: (widget.allowPinning && (isPinned || _isHovering))
                            ? IconButton(
                          onPressed: () {
                            ref.read(foldersDaoProvider).toggleFolderPinStatus(folderData.uuid);
                          },
                          icon: Icon(
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 16,
                          ),
                          color: isPinned ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          splashRadius: 16,
                          tooltip: isPinned ? 'Unpin' : 'Pin Folder',
                        )
                            : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: folderAccentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        folderData.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: widget.isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                        child: Text(
                          noteCount,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.isSelected
                                ? colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class FolderEditorDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColorIndex;

  const FolderEditorDialog({
    super.key,
    this.initialName,
    this.initialColorIndex,
  });

  @override
  State<FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends State<FolderEditorDialog> {
  late final TextEditingController _nameController;
  late int _selectedColorIndex;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialName != null;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColorIndex = widget.initialColorIndex ?? Random().nextInt(Colors.primaries.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      title: Text(
        _isEditing ? 'Update Folder' : 'New Folder',
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: textTheme.bodyMedium,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                hintText: 'Folder name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "COLOR",
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(Colors.primaries.length, (index) {
                final color = Colors.primaries[index];
                final isSelected = _selectedColorIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: isSelected
                        ? Icon(
                      Icons.check_rounded,
                      color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      size: 16,
                    )
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'colorIndex': _selectedColorIndex,
            });
          },
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}