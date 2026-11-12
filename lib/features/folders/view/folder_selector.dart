export 'dialogs/folder_editor_dialog.dart';
export 'widgets/folder_list_item.dart';
export 'widgets/folder_selector_container.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import 'widgets/folder_selector_container.dart';

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
        return FolderSelectorContainer(
          selectedFolder: localSelectedFolder,
          emptyLabel: widget.emptyLabel,
          title: 'Folders Filter',
          emptyIcon: Icons.format_align_left,
          showEmptyNoteCount: true,
          searchBarPosition: SearchBarPosition.bottom,
          allowContextMenus: widget.showContextMenus,
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
              child: FolderSelectorContainer(
                selectedFolder: widget.selectedFolder,
                emptyLabel: widget.emptyLabel,
                title: 'Folders Filter',
                emptyIcon: Icons.format_align_left,
                showEmptyNoteCount: true,
                searchBarPosition: SearchBarPosition.bottom,
                allowContextMenus: widget.showContextMenus,
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
