import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/note_theme.dart';
import '../database/drift/drift_database.dart';

class NoteCard extends ConsumerStatefulWidget {
  final Note note;
  final bool isSelected;

  /// We Pass the icons here (e.g., Delete, Restore, Select)
  final List<Widget> hoverActions;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.hoverActions = const [],
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;

    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: widget.isSelected ? 1 : 0,
        color: noteTheme.cardContentBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: widget.isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // BASE CARD CONTENT
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TITLE HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: noteTheme.cardTitleBackground ?? colorScheme.surfaceContainerHigh,
                    child: Padding(
                      // Pushes text away from the right edge so stacked icons don't cover it
                      padding: EdgeInsets.only(right: widget.hoverActions.isNotEmpty ? 24.0 : 0.0),
                      child: Text(
                        widget.note.title.isEmpty ? "Untitled" : widget.note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: noteTheme.cardTitleForeground ?? colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                  // CONTENT AREA
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 32.0, bottom: 12.0),
                          child: widget.note.isLocked // Lock state from Homepage
                              ? Center(
                            child: Icon(
                              Icons.lock_outlined,
                              size: 32,
                              color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant)
                                  .withValues(alpha: 0.4),
                            ),
                          )
                              : Text(
                            widget.note.content,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // PLATFORM ICON (Bottom Right)
                        if (platform != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Tooltip(
                              message: widget.note.deletedPlatform != null
                                  ? 'Deleted on $platform'
                                  : 'Created on $platform',
                              child: _getPlatformIcon(platform),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // FLOATING STACKED ICONS
              if ((_isHovering || widget.isSelected) && widget.hoverActions.isNotEmpty)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.hoverActions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
      case 'ios':
        return const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey);
      case 'windows':
        return const Icon(Icons.desktop_windows_rounded, size: 14, color: Colors.grey);
      default:
        return const Icon(Icons.computer, size: 14, color: Colors.grey);
    }
  }
}