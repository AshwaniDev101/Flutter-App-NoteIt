import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/folders/view/folder_selector.dart';
import 'package:noteit/shared/menus/app_bottom_sheet.dart';
import 'package:noteit/shared/app_bars/app_search_bar.dart';

/// A dropdown selector widget for choosing a folder for a note.
///
/// Designed specifically as a streamlined option menu / selector for the
/// Note Editor, featuring a search bar and list of available folders with
/// their leading color indicators.
class FolderOptionMenu extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final String emptyLabel;

  const FolderOptionMenu({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.emptyLabel = 'none',
  });

  @override
  ConsumerState<FolderOptionMenu> createState() => _FolderOptionMenuState();
}

class _FolderOptionMenuState extends ConsumerState<FolderOptionMenu> {
  final MenuController _menuController = MenuController();
  bool _isHovering = false;

  void _showMobileBottomSheet(BuildContext context) {
    Folder? localSelectedFolder = widget.selectedFolder;

    AppBottomSheet.show(
      context: context,
      heightFactor: 0.5,
      builder: (context, setModalState) {
        return _FolderOptionMenuContent(
          selectedFolder: localSelectedFolder,
          emptyLabel: widget.emptyLabel,
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
    final textTheme = Theme.of(context).textTheme;

    final currentName = activeFolder?.name ?? widget.emptyLabel;
    final currentColor = activeFolder != null
        ? Colors.primaries[activeFolder.colorIndex % Colors.primaries.length]
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onHover: (val) => setState(() => _isHovering = val),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  currentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isOpen ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isOpen ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          padding: const EdgeInsets.only(top: 6.0),
          child: Material(
            color: colorScheme.surfaceContainerLowest,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 260,
              height: 320,
              child: _FolderOptionMenuContent(
                selectedFolder: widget.selectedFolder,
                emptyLabel: widget.emptyLabel,
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

class _FolderOptionMenuContent extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final String emptyLabel;

  const _FolderOptionMenuContent({
    required this.selectedFolder,
    required this.onFolderSelected,
    required this.emptyLabel,
  });

  @override
  ConsumerState<_FolderOptionMenuContent> createState() => _FolderOptionMenuContentState();
}

class _FolderOptionMenuContentState extends ConsumerState<_FolderOptionMenuContent> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    final activeFolder = widget.selectedFolder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search folders...',
            fillColor: colorScheme.surfaceContainerLow,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClear: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          const SizedBox(height: 8),

          // Folder list stream
          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(
                child: Text(
                  'Error loading folders',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
              data: (foldersWithCount) {
                final lowerQuery = _searchQuery.toLowerCase().trim();
                final showEmptyOption = lowerQuery.isEmpty ||
                    widget.emptyLabel.toLowerCase().contains(lowerQuery) ||
                    'no folder'.contains(lowerQuery) ||
                    'none'.contains(lowerQuery);

                final matchingFolders = foldersWithCount.where((f) {
                  return f.folder.name.toLowerCase().contains(lowerQuery);
                }).toList();

                if (matchingFolders.isEmpty && !showEmptyOption) {
                  return Center(
                    child: Text(
                      'No folders found',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // "None" / Clear option
                    if (showEmptyOption) ...[
                      AppMenuTile(
                        label: widget.emptyLabel,
                        isSelected: activeFolder == null,
                        leading: Icon(
                          Icons.format_align_left_rounded,
                          size: 18,
                          color: activeFolder == null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        onTap: () => widget.onFolderSelected(null),
                      ),
                      if (matchingFolders.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                    ],

                    // List of folders with leading colors
                    ...matchingFolders.map((item) {
                      final folder = item.folder;
                      final folderColor = Colors.primaries[folder.colorIndex % Colors.primaries.length];
                      final isSelected = activeFolder?.uuid == folder.uuid;

                      return AppMenuTile(
                        label: folder.name,
                        isSelected: isSelected,
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: folderColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: folderColor.withValues(alpha: 0.35),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => widget.onFolderSelected(folder),
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
