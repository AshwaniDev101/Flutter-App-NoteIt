import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/shared/widgets/note_card/widgets/lock_overlay.dart';

import '../../../core/helpers/time_helper.dart';
import '../../../database/drift/local_database.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/home/view/shared/tag_sort_view_menu.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
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
  // Track if the keyboard spotlight is on this card
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Watch the global view type! Any time it changes, this card redraws itself.
    final viewType = ref.watch(noteViewTypeProvider);

    return FocusableActionDetector(
      // Fires when arrow keys move onto or off of this widget
      onShowFocusHighlight: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },

      // THE ACTION: Pressing Enter or Space triggers the onTap
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            if (widget.onTap != null) widget.onTap!();
            return null; // Required return type
          },
        ),
      },

      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          elevation: widget.isSelected ? 1 : (_isFocused ? 4 : 0),
          clipBehavior: Clip.antiAlias,

          color: widget.isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _isFocused
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), // very dim card boarder
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            canRequestFocus: false,
            child: Stack(children: [_buildInternalLayout(viewType)]),
          ),
        ),
      ),
    );
  }

  // ==== LAYOUT ROUTER ====
  Widget _buildInternalLayout(NoteViewType viewType) {
    switch (viewType) {
      case NoteViewType.list:
        return _buildCompactList();
      case NoteViewType.detailedList:
        return _buildDetailedList();
      case NoteViewType.grid:
        return _buildGrid();
      case NoteViewType.largeGrid:
        return _buildLargeGrid();
    }
  }

  // ==== COMPACT LIST LAYOUT ====
  Widget _buildCompactList() {
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
              // normalStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              normalStyle: Theme.of(context).textTheme.titleMedium,
              highlightStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (widget.note.isPinned) ...[
            const SizedBox(width: 8),
            Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  // ==== DETAILED LIST LAYOUT ====
  Widget _buildDetailedList() {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  // normalStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  normalStyle: Theme.of(context).textTheme.titleMedium,
                  highlightStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          // const SizedBox(height: 2),
          widget.note.isLocked
              ? Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.lock_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          )
              : HighlightedText(
            text: widget.note.content,
            query: widget.searchQuery,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            // normalStyle: const TextStyle(fontSize: 13, height: 1.4),
            normalStyle: Theme.of(context).textTheme.bodyMedium,
            highlightStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimeHelper.formatTimeAgo(widget.note.updatedAt),
                style: Theme.of(context).textTheme.labelMedium,
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

  // ==== GRID LAYOUT ====
  Widget _buildGrid() {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    final isSessionUnlocked = ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(widget.note.uuid);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  normalStyle: Theme.of(context).textTheme.titleMedium,

                  highlightStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,

                  child: HighlightedText(
                    //  Pass empty string if locked & not verified, SECURITY: not doing so, ill allow screen reader to fetch the content
                    text: (widget.note.isLocked && !isSessionUnlocked) ? "" : widget.note.content,
                    query: widget.searchQuery,
                    // maxLines: maxLines,
                    overflow: TextOverflow.fade,
                    normalStyle: Theme.of(context).textTheme.bodyMedium,

                    highlightStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),

                  ),
                ),

                // Lock icon overlay
                LockOverlayWidget(note: widget.note),
              ],
            ),
          ),

          // Looks better in Android this way
          if (PlatformHelper.isDesktopScreen)...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeHelper.formatTimeAgo(widget.note.updatedAt),

                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (platform != null)
                  Tooltip(
                    message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                    child: _getPlatformIcon(platform),
                  ),
              ],
            ),
          ]



        ],
      ),
    );
  }

  // ==== Large GRID LAYOUT ====
  Widget _buildLargeGrid() {
    final platform = widget.note.deletedPlatform ?? widget.note.creationPlatform;

    final isSessionUnlocked = ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(widget.note.uuid);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  normalStyle: Theme.of(context).textTheme.titleMedium,

                  highlightStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,

                  child: HighlightedText(
                    //  Pass empty string if locked & not verified, SECURITY: not doing so, ill allow screen reader to fetch the content
                    text: (widget.note.isLocked && !isSessionUnlocked) ? "" : widget.note.content,
                    query: widget.searchQuery,
                    // maxLines: maxLines,
                    overflow: TextOverflow.fade,
                    normalStyle: Theme.of(context).textTheme.bodyMedium,

                    highlightStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),

                  ),
                ),

                // Lock icon overlay
                LockOverlayWidget(note: widget.note),
              ],
            ),
          ),

          // Looks better in Android this way
          if (PlatformHelper.isDesktopScreen)...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeHelper.formatTimeAgo(widget.note.updatedAt),

                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (platform != null)
                  Tooltip(
                    message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                    child: _getPlatformIcon(platform),
                  ),
              ],
            ),
          ]



        ],
      ),
    );
  }




  // ==== SHARED ICONS ====
  Widget _getPlatformIcon(String platform) {
    // Icons naturally inherit default colors too, but retaining the grey here
    // keeps them subtle as meta-information.
    switch (platform.toLowerCase()) {
      case 'android':
        return const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey);
      case 'ios':
        return const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey);
      case 'windows':
        return const Icon(Icons.desktop_windows_sharp, size: 14, color: Colors.grey);
      default:
        return const Icon(Icons.computer, size: 14, color: Colors.grey);
    }
  }
}
