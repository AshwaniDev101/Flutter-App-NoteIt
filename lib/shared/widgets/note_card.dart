import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/note_theme.dart';
import '../../database/drift/drift_database.dart';
import '../managers/lock_manger/lock_manager.dart';
import 'highlighted_text.dart';

class NoteCard extends ConsumerStatefulWidget {
  final Note note;
  final bool isSelected;
  final String searchQuery;
  final List<Widget> hoverActions;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.searchQuery = '',
    this.hoverActions = const [],
    this.onTap,
    this.onLongPress,
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
    final highlightColor = colorScheme.primaryContainer;
    final onHighlightColor = colorScheme.onPrimaryContainer;

    final isSessionUnlocked = ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(widget.note.id);
    final displayAsLocked = widget.note.isLocked && !isSessionUnlocked;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      // Moved the AnimatedScale here from SelectableCard
      child: AnimatedScale(
        scale: widget.isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: widget.isSelected ? 1 : 0,
          color: noteTheme.cardContentBackground,
          clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple stays inside corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: widget.isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          // InkWell for taps
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
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
                        padding: EdgeInsets.only(right: widget.hoverActions.isNotEmpty ? 24.0 : 0.0),
                        child: displayAsLocked
                            ? Center(
                          child: Icon(
                            Icons.lock_outlined,
                            size: 32,
                            color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant)
                                .withValues(alpha: 0.4),
                          ),
                        )
                            : HighlightedText(
                          text: widget.note.title.isEmpty ? "Untitled" : widget.note.title,
                          query: widget.searchQuery,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          normalStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: noteTheme.cardTitleForeground ?? colorScheme.onSurface,
                          ),
                          highlightStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            backgroundColor: highlightColor,
                            color: onHighlightColor,
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
                            child: widget.note.isLocked
                                ? Center(
                              child: Icon(
                                Icons.lock_outlined,
                                size: 32,
                                color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant)
                                    .withValues(alpha: 0.4),
                              ),
                            )
                                : HighlightedText(
                              text: widget.note.content,
                              query: widget.searchQuery,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              normalStyle: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
                              ),
                              highlightStyle: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                backgroundColor: highlightColor,
                                color: onHighlightColor,
                              ),
                            ),
                          ),

                          // PLATFORM ICON
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
                    // selection icon and hover actions are in ONE unified column
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.hoverActions,
                    ),
                  ),
              ],
            ),
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