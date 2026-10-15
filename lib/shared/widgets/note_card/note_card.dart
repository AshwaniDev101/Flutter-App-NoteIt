import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/shared/widgets/note_card/widgets/lock_overlay.dart';

import '../../../core/helpers/time_helper.dart';
import '../../../database/drift/local_database.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/home/view/shared/tag_sort_view_menu.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
import '../highlighted_text.dart';


enum NoteContextMenuOption {
  // Common
  select('Select', Icons.check_circle_outline),
  pin('Pin', Icons.push_pin_outlined),
  unpin('Unpin', CupertinoIcons.pin_slash),
  lock('Lock', Icons.lock_outline),
  reminder('Remind me', Icons.notifications_none_outlined),
  moveTo('Move to...', Icons.drive_file_move_outlined),
  duplicate('Duplicate', Icons.copy_outlined),
  openNewWindow('Open in new window', Icons.open_in_new_outlined),

  // Filing
  archive('Archive', Icons.archive_outlined),
  unarchive('Unarchive', Icons.unarchive_outlined),

  // Destructive
  restore('Restore', Icons.restore),
  delete('Delete', Icons.delete_outline, isDestructive: true),
  deleteForever('Delete Forever', Icons.delete_forever, isDestructive: true);

  final String label;
  final IconData icon;
  final bool isDestructive;

  const NoteContextMenuOption(this.label, this.icon, {this.isDestructive = false});
}

class NoteCard extends ConsumerStatefulWidget {
  final Note note;
  final bool isSelected;
  final String searchQuery;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final void Function(NoteContextMenuOption)? onContextMenuAction;

  final List<NoteContextMenuOption> contextMenuOptions;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.searchQuery = '',
    this.onTap,
    this.onLongPress,
    this.onContextMenuAction,
    // Provide the Home Screen defaults here
    this.contextMenuOptions = const [
      NoteContextMenuOption.select,
      NoteContextMenuOption.pin,
      NoteContextMenuOption.lock,
      NoteContextMenuOption.reminder,
      NoteContextMenuOption.moveTo,
      NoteContextMenuOption.duplicate,
      NoteContextMenuOption.openNewWindow,
      NoteContextMenuOption.archive,
      NoteContextMenuOption.delete,
    ],
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  // Track if the keyboard spotlight is on this card
  bool _isFocused = false;

  final MenuController _menuController = MenuController();


  @override
  Widget build(BuildContext context) {
    final viewType = ref.watch(noteViewTypeProvider);
    final isPinned = widget.note.pinnedAt != null;

    return MenuAnchor(
      controller: _menuController,
      consumeOutsideTap: true,
      menuChildren: widget.contextMenuOptions
            // Hide 'Select' if this specific card is already selected
          .where((option) => !(option == NoteContextMenuOption.select && widget.isSelected))
          .map((option) {
        final effectiveOption = (isPinned && option == NoteContextMenuOption.pin)
            ? NoteContextMenuOption.unpin
            : (!isPinned && option == NoteContextMenuOption.unpin)
                ? NoteContextMenuOption.pin
                : option;

        return MenuItemButton(
          leadingIcon: Icon(
            effectiveOption.icon,
            // Paint destructive actions red
            color: effectiveOption.isDestructive ? Theme.of(context).colorScheme.error : null,
          ),
          onPressed: () {
            if (widget.onContextMenuAction != null) {
              widget.onContextMenuAction!(effectiveOption);
            }
          },
          child: Text(
            effectiveOption.label,
            style: TextStyle(
              color: effectiveOption.isDestructive ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        );
      }).toList(),

      child: GestureDetector(
        //Capture right-click (secondary tap) and open menu at exact pointer location
        onSecondaryTapDown: (details) {
          _menuController.open(position: details.localPosition);
        },
        child: FocusableActionDetector(
          onShowFocusHighlight: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                if (widget.onTap != null) widget.onTap!();
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _buildLayoutRouter(viewType),
          ),
        ),
      ),
    );
  }

  // ==== LAYOUT ROUTER ====
  Widget _buildLayoutRouter(NoteViewType viewType) {
    switch (viewType) {
      case NoteViewType.list:
      // Plain list gets the flat wrapper
        return _buildFlatListWrapper(child: _buildCompactList());

      case NoteViewType.detailedList:
      // Detailed list, Grids get the Card wrapper
        return _buildCardWrapper(child: _buildDetailedList());

      case NoteViewType.grid:
        return _buildCardWrapper(child: _buildGrid());

      case NoteViewType.largeGrid:
        return _buildCardWrapper(child: _buildLargeGrid());
    }
  }

  // ==== WRAPPERS ====

  /// Used for Grids and Detailed Lists
  Widget _buildCardWrapper({required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(4.0),
      elevation: widget.isSelected ? 1 : (_isFocused ? 4 : 0),
      clipBehavior: Clip.antiAlias,
      color: widget.isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        canRequestFocus: false,
        child: child,
      ),
    );
  }

  /// Used ONLY for the compact plain list
  Widget _buildFlatListWrapper({required Widget child}) {
    // Determine the correct background color
    Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    } else if (_isFocused) {
      // Show a slight highlight when hovered/focused
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    } else {
      // Solid surface color instead of transparent so it pops from the background
      backgroundColor = Theme.of(context).colorScheme.surface;
    }

    return Material(
      color: backgroundColor,
      // Add a subtle divider at the bottom of each list item
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        canRequestFocus: false,
        child: child,
      ),
    );
  }


  // ==== COMPACT LIST LAYOUT ====
  Widget _buildCompactList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: HighlightedText(
              text: widget.note.title.isEmpty ? "Untitled" : widget.note.title,
              query: widget.searchQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // normalStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              normalStyle: Theme.of(context).textTheme.bodyMedium,
              highlightStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (widget.note.pinnedAt != null) ...[
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

    final colorScheme = Theme.of(context).colorScheme;

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
              if (widget.note.pinnedAt != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ],
          ),
          // const SizedBox(height: 2),
          widget.note.lockedAt != null
              ? Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.lock_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          )
              : HighlightedText(
            // text: widget.note.content,
            text: _getNotePreviewText(widget.note),
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

          // Timestamp
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimeHelper.formatTimeAgo(widget.note.updatedAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (platform != null)
                Tooltip(
                  message: widget.note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
                  child: _getPlatformIcon(platform,),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==== GRID LAYOUT ====
  Widget _buildGrid() {

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
              if (widget.note.pinnedAt != null) ...[
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
                    text: (widget.note.lockedAt != null && !isSessionUnlocked) ? "" : _getNotePreviewText(widget.note),
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
              if (widget.note.pinnedAt != null) ...[
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
                    text: (widget.note.lockedAt != null && !isSessionUnlocked) ? "" : _getNotePreviewText(widget.note),
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

                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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


  // ==== PREVIEW HELPER ====
  String _getNotePreviewText(Note note) {
    // If it's a checklist (version 2), format the JSON into text boxes
    if (note.contentVersion == 2) {
      try {
        final List<dynamic> decoded = jsonDecode(note.content);
        return decoded.map((item) {
          bool isChecked = item['isChecked'] == true;
          String text = item['text'] ?? '';
          return '${isChecked ? "☑" : "☐"} $text';
        }).join('\n');
      } catch (_) {
        return note.content;
      }
    }
    // Otherwise, just return the plain text
    return note.content;
  }


  // ==== SHARED ICONS ====
  Widget _getPlatformIcon(String platform) {
    // Icons naturally inherit default colors too, but retaining the grey here
    // keeps them subtle as meta-information.
    final colorScheme = Theme.of(context).colorScheme;
    switch (platform.toLowerCase()) {
      case 'android':
        return Icon(Icons.phone_android_rounded, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
      case 'ios':
        return Icon(Icons.phone_iphone_rounded, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
      case 'windows':
        return Icon(Icons.desktop_windows_sharp, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
      default:
        return Icon(Icons.computer, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
    }
  }
}
