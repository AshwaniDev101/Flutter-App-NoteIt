import 'package:flutter/material.dart';
import '../../database/drift/local_database.dart';
import 'core/note_action.dart';

class FolderTrashCard extends StatefulWidget {
  final Folder folder;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(NoteAction)? onContextMenuAction;

  const FolderTrashCard({
    super.key,
    required this.folder,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onContextMenuAction,
  });

  @override
  State<FolderTrashCard> createState() => _FolderTrashCardState();
}

class _FolderTrashCardState extends State<FolderTrashCard> {
  bool _isFocused = false;
  final MenuController _menuController = MenuController();

  Color get _folderAccentColor {
    return Colors.primaries[widget.folder.colorIndex % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _folderAccentColor;

    return MenuAnchor(
      controller: _menuController,
      consumeOutsideTap: true,
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.restore),
          onPressed: () => widget.onContextMenuAction?.call(NoteAction.restore),
          child: const Text('Restore'),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_forever, color: colorScheme.error),
          onPressed: () => widget.onContextMenuAction?.call(NoteAction.deleteForever),
          child: Text('Delete Forever', style: TextStyle(color: colorScheme.error)),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.check_circle_outline),
          onPressed: () => widget.onContextMenuAction?.call(NoteAction.select),
          child: const Text('Select'),
        ),
      ],
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _menuController.open(position: details.localPosition);
        },
        child: FocusableActionDetector(
          onShowFocusHighlight: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: widget.isSelected
                  ? accentColor.withValues(alpha: 0.3)
                  : accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!();
                  } else {
                    _menuController.open();
                  }
                },
                onLongPress: widget.onLongPress,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isSelected
                          ? colorScheme.primary
                          : (_isFocused ? accentColor : accentColor.withValues(alpha: 0.3)),
                      width: widget.isSelected || _isFocused ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.folder.name,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
