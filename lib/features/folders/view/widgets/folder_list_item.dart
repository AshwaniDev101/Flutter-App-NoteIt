import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/drift/folders/folders_dao.dart';

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
          borderRadius: BorderRadius.circular(10),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          onTap: widget.onSelect,
          onLongPress: widget.onContextMenu != null ? () => widget.onContextMenu!(null) : null,
          onSecondaryTapUp: widget.onContextMenu,
          onHover: (hovering) => setState(() => _isHovering = hovering),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: widget.isSelected ? colorScheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
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
                            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
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
                    // Badge for count
                    Flexible(
                      flex: 0,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? colorScheme.onSecondaryContainer.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          noteCount,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
