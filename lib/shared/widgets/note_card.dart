
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/note_theme.dart';
import '../../database/drift/local_database.dart';
import '../../features/home/note_view.dart';
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

    // Watch the global view type! Any time it changes, this card redraws itself.
    final viewType = ref.watch(noteViewTypeProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: widget.isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: widget.isSelected ? 1 : 0,
          color: noteTheme.cardContentBackground,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: widget.isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Stack(
              children: [
                // ROUTER: Pick the right layout based on the view type
                _buildInternalLayout(context, noteTheme, colorScheme, viewType),

                // FLOATING HOVER ACTIONS
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
        return _buildGrid(noteTheme, colorScheme);
    }
  }

  // ==== GRID LAYOUT ====
  Widget _buildGrid(NoteTheme noteTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleHeader(noteTheme, colorScheme),
        Expanded( // Used securely here because Grids provide bounded height constraints
          child: _buildContentArea(noteTheme, colorScheme, maxLines: 5),
        ),
      ],
    );
  }

  // ==== DETAILED LIST LAYOUT ====
  Widget _buildDetailedList(NoteTheme noteTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // Vital to prevent ListView infinite height crashes
      children: [
        _buildTitleHeader(noteTheme, colorScheme),
        _buildContentArea(noteTheme, colorScheme, maxLines: 2), // Less text shown in a list format
      ],
    );
  }

  // ==== COMPACT LIST LAYOUT ====
  Widget _buildCompactList(NoteTheme noteTheme, ColorScheme colorScheme) {
    final title = widget.note.title.isEmpty ? "Untitled" : widget.note.title;
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            widget.note.isLocked ? Icons.lock_outline : Icons.notes_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (platform != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                child: _getPlatformIcon(platform),
              ),
            ),
        ],
      ),
    );
  }

  // ==== SHARED UI COMPONENTS ====

  Widget _buildTitleHeader(NoteTheme noteTheme, ColorScheme colorScheme) {
    return Ink(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: noteTheme.cardTitleBackground ?? colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: EdgeInsets.only(right: widget.hoverActions.isNotEmpty ? 24.0 : 0.0),
        child: HighlightedText(
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
            backgroundColor: colorScheme.primaryContainer,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(NoteTheme noteTheme, ColorScheme colorScheme, {required int maxLines}) {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;
    final displayAsLocked = widget.note.isLocked;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 32.0, bottom: 24.0),
          child: displayAsLocked
              ? Center(
            child: Icon(
              Icons.lock_outlined,
              size: 32,
              color: (noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant).withValues(alpha: 0.4),
            ),
          )
              : HighlightedText(
            text: widget.note.content,
            query: widget.searchQuery,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            normalStyle: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
            ),
            highlightStyle: TextStyle(
              fontSize: 13,
              height: 1.4,
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (platform != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: Tooltip(
              message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
              child: _getPlatformIcon(platform),
            ),
          ),
      ],
    );
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
      case 'ios': return const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey);
      case 'windows': return const Icon(Icons.desktop_windows_rounded, size: 14, color: Colors.grey);
      default: return const Icon(Icons.computer, size: 14, color: Colors.grey);
    }
  }
}
