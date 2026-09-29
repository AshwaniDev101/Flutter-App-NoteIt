import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/time_helper.dart';
import '../../core/theme/note_theme.dart';
import '../../database/drift/local_database.dart';
import '../../features/home/note_view.dart';
import 'highlighted_text.dart';

class NoteCard extends ConsumerStatefulWidget {
  final Note note;
  final bool isSelected;
  final String searchQuery;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.searchQuery = '',
    this.onTap,
    this.onLongPress,
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {

  @override
  Widget build(BuildContext context) {
    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;

    // Watch the global view type! Any time it changes, this card redraws itself.
    final viewType = ref.watch(noteViewTypeProvider);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: widget.isSelected ? 1 : 0,
        clipBehavior: Clip.antiAlias,
        color: widget.isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : noteTheme.cardContentBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1, // Keep width at 1 so the size never jumps
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Stack(
            children: [
              _buildInternalLayout(context, noteTheme, colorScheme, viewType),
            ],
          ),
        ),
      ),
    );
  }

  // ==== LAYOUT ROUTER ====
  Widget _buildInternalLayout(BuildContext context, NoteTheme noteTheme, ColorScheme colorScheme, NoteViewType viewType) {
    switch (viewType) {
      case NoteViewType.list:
        return _buildCompactList(noteTheme, colorScheme);
      case NoteViewType.detailedList:
        return _buildDetailedList(noteTheme, colorScheme);
      case NoteViewType.grid:
      case NoteViewType.largeGrid:
        return _buildGrid(noteTheme, colorScheme, viewType);
    }
  }

  // ==== GRID LAYOUT ====
  Widget _buildGrid(NoteTheme noteTheme, ColorScheme colorScheme, NoteViewType viewType) {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;
    final int maxLines = viewType == NoteViewType.largeGrid ? 8 : 5;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Grids provide bounded height, so we use max to push the footer to the bottom
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HighlightedText(
                  text: widget.note.title.isEmpty ? "Untitled" : widget.note.title,
                  query: widget.searchQuery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  normalStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: noteTheme.cardTitleForeground,
                  ),
                  highlightStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Expanded forces the text to take up remaining space, pushing footer down
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: widget.note.isLocked
                  ? Icon(Icons.lock_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))
                  : HighlightedText(
                text: widget.note.content,
                query: widget.searchQuery,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                normalStyle: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: noteTheme.cardContentForeground,
                ),
                highlightStyle: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  backgroundColor: colorScheme.primaryContainer,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(

                TimeHelper.formatTimeAgo(widget.note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: noteTheme.cardContentForeground,
                ),
              ),
              if (platform != null)
                Tooltip(
                  message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                  child: _getPlatformIcon(platform),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==== DETAILED LIST LAYOUT ====
  Widget _buildDetailedList(NoteTheme noteTheme, ColorScheme colorScheme) {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Lists dictate their own height, so we use min
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HighlightedText(
                  text: widget.note.title.isEmpty ? "Untitled" : widget.note.title,
                  query: widget.searchQuery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  normalStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: noteTheme.cardTitleForeground,
                  ),
                  highlightStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          const SizedBox(height: 6),

          widget.note.isLocked
              ? Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.lock_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          )
              : HighlightedText(
            text: widget.note.content,
            query: widget.searchQuery,
            maxLines: 2, // Fixed to 2 lines for detailed lists
            overflow: TextOverflow.ellipsis,
            normalStyle: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: noteTheme.cardContentForeground,
            ),
            highlightStyle: TextStyle(
              fontSize: 13,
              height: 1.4,
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimeHelper.formatTimeAgo(widget.note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: noteTheme.cardContentForeground,
                ),
              ),
              if (platform != null)
                Tooltip(
                  message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                  child: _getPlatformIcon(platform),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==== COMPACT LIST LAYOUT ====
  Widget _buildCompactList(NoteTheme noteTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: HighlightedText(
              text: widget.note.title.isEmpty ? "Untitled" : widget.note.title,
              query: widget.searchQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              normalStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: noteTheme.cardTitleForeground,
              ),
              highlightStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (widget.note.isPinned) ...[
            const SizedBox(width: 8),
            Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  // ==== SHARED ICONS ====
  Widget _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
      case 'ios': return const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey);
      case 'windows': return const Icon(Icons.desktop_windows_sharp, size: 14, color: Colors.grey);
      default: return const Icon(Icons.computer, size: 14, color: Colors.grey);
    }
  }
}