import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/helpers/time_helper.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/lock/lock_manger/lock_manager.dart';
import 'package:noteit/shared/menus/view_menu_button.dart';
import 'package:noteit/shared/note_card/overlays/lock_overlay.dart';
import 'package:noteit/shared/note_card/overlays/reminder_overlay.dart';

import '../text/highlighted_text.dart';
import 'core/note_action.dart';

/// A card widget displaying a note summary across list and grid layouts.
class NoteCard extends ConsumerStatefulWidget {
  final NoteWithFolder noteWithFolder;
  final bool isSelected;
  final bool isActive;
  final String searchQuery;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(NoteAction)? onContextMenuAction;
  final List<NoteAction> contextMenuOptions;
  final NoteViewType? viewType;

  static const double selectedAlpha = 0.2;
  static const double activeAlpha = 0.3;
  static const double outlineAlpha = 0.3;

  static const List<NoteAction> defaultContextMenuOptions = [
    NoteAction.select,
    NoteAction.pin,
    NoteAction.lock,
    NoteAction.reminder,
    NoteAction.moveTo,
    NoteAction.duplicate,
    NoteAction.archive,
    NoteAction.delete,
  ];

  const NoteCard({
    super.key,
    required this.noteWithFolder,
    this.viewType,
    this.isSelected = false,
    this.isActive = false,
    this.searchQuery = '',
    this.onTap,
    this.onLongPress,
    this.onContextMenuAction,
    this.contextMenuOptions = defaultContextMenuOptions,
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  bool _isFocused = false;
  final MenuController _menuController = MenuController();

  Note get _note => widget.noteWithFolder.note;
  Folder? get _folder => widget.noteWithFolder.folder;
  bool get _isPinned => _note.pinnedAt != null;
  bool get _isLocked => _note.lockedAt != null;

  Color? get _folderAccentColor {
    if (_folder == null) return null;
    return Colors.primaries[_folder!.colorIndex % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    final NoteViewType viewType = widget.viewType ?? ref.watch(homeNoteViewTypeProvider);

    return MenuAnchor(
      controller: _menuController,
      consumeOutsideTap: true,
      menuChildren: _buildMenuItems(context),
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _menuController.open(position: details.localPosition);
        },
        child: FocusableActionDetector(
          onShowFocusHighlight: (hasFocus) {
            if (_isFocused != hasFocus) {
              setState(() => _isFocused = hasFocus);
            }
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _buildLayoutRouter(context, viewType),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return widget.contextMenuOptions
        .where((option) => !(option == NoteAction.select && widget.isSelected))
        .map((option) {
      var effectiveOption = option;
      if (option == NoteAction.pin && _isPinned) {
        effectiveOption = NoteAction.unpin;
      } else if (option == NoteAction.unpin && !_isPinned) {
        effectiveOption = NoteAction.pin;
      }

      String label = effectiveOption.label;
      IconData iconData = effectiveOption.icon;

      if (option == NoteAction.reminder) {
        final hasReminder = _note.reminderAt != null;
        label = hasReminder ? 'Remove Reminder' : 'Remind me';
        iconData = hasReminder ? Icons.notifications_off_outlined : Icons.notifications_none_outlined;
      }

      final color = effectiveOption.isDestructive ? errorColor : null;

      return MenuItemButton(
        leadingIcon: Icon(
          iconData,
          color: color,
        ),
        onPressed: () => widget.onContextMenuAction?.call(effectiveOption),
        child: Text(
          label,
          style: TextStyle(color: color),
        ),
      );
    }).toList();
  }

  Widget _buildLayoutRouter(BuildContext context, NoteViewType viewType) {
    switch (viewType) {
      case NoteViewType.list:
        return _buildFlatListWrapper(context, child: _buildCompactList(context));
      case NoteViewType.detailedList:
        return _buildCardWrapper(context, child: _buildDetailedList(context));
      case NoteViewType.grid:
      case NoteViewType.largeGrid:
        return _buildCardWrapper(context, child: _buildGrid(context));
    }
  }

  Widget _buildCardWrapper(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool showPrimaryBorder = widget.isSelected || _isFocused;

    final Color? cardColor;
    if (widget.isSelected) {
      cardColor = colorScheme.primary.withValues(alpha: NoteCard.selectedAlpha);
    } else if (widget.isActive) {
      cardColor = colorScheme.primary.withValues(alpha: NoteCard.activeAlpha);
    } else {
      cardColor = null;
    }

    return Card(
      margin: const EdgeInsets.all(4.0),
      elevation: widget.isSelected ? 2 : (widget.isActive ? 1 : (_isFocused ? 4 : 0)),
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: showPrimaryBorder
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: NoteCard.outlineAlpha),
          width: showPrimaryBorder ? 2 : 1,
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

  Widget _buildFlatListWrapper(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: NoteCard.selectedAlpha);
    } else if (widget.isActive) {
      backgroundColor = colorScheme.primary.withValues(alpha: NoteCard.activeAlpha);
    } else if (_isFocused) {
      backgroundColor = colorScheme.surfaceContainerHighest;
    } else {
      backgroundColor = colorScheme.surface;
    }

    final bool showPrimaryBorder = widget.isSelected;

    return Material(
      color: backgroundColor,
      shape: Border(
        bottom: BorderSide(
          color: showPrimaryBorder
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: NoteCard.outlineAlpha),
          width: showPrimaryBorder ? 2 : 1,
        ),
        left: showPrimaryBorder
            ? BorderSide(
                color: colorScheme.primary,
                width: 4,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        canRequestFocus: false,
        child: child,
      ),
    );
  }

  Widget _buildTitleHeader(
    BuildContext context, {
    required TextStyle? textStyle,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayTitle = _note.title.isEmpty ? 'Untitled' : _note.title;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HighlightedText(
            text: displayTitle,
            query: widget.searchQuery,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            normalStyle: textStyle,
            highlightStyle: textStyle?.copyWith(
              fontWeight: FontWeight.bold,
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (widget.isSelected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
        ] else ...[
          if (_note.reminderAt != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.notifications_active_outlined, size: 14, color: colorScheme.primary),
          ],
          if (_isPinned) ...[
            const SizedBox(width: 8),
            Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, {TextStyle? textStyle}) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveStyle = textStyle ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_folder != null) _getFolderLabel(context, textStyle: effectiveStyle),
        const Spacer(),
        Text(
          TimeHelper.formatTimeAgo(_note.updatedAt),
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCompactList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: HighlightedText(
              text: _note.title.isEmpty ? 'Untitled' : _note.title,
              query: widget.searchQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              normalStyle: textStyle,
              highlightStyle: textStyle?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (_isLocked) ...[
            const SizedBox(width: 8),
            Icon(Icons.lock_outline, size: 16, color: colorScheme.onSurfaceVariant),
          ],
          if (widget.isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
          ] else if (_isPinned) ...[
            const SizedBox(width: 8),
            Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleHeader(
            context,
            textStyle: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          _isLocked
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.lock_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                )
              : _buildNotePreview(context, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          _buildMetadataRow(
            context,
            textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleHeader(
            context,
            textStyle: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _buildNotePreview(context, overflow: TextOverflow.fade),
                ),
                LockOverlayWidget(noteWithFolder: widget.noteWithFolder),
                ReminderOverlayWidget(noteWithFolder: widget.noteWithFolder),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildMetadataRow(
            context,
            textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotePreview(
    BuildContext context, {
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    // Select ONLY whether THIS note is unlocked, avoiding unnecessary rebuilds when other notes lock/unlock.
    final isSessionUnlocked = ref.watch(
      lockManagerProvider.select(
        (state) => state.sessionUnlockedNoteIds.contains(_note.uuid),
      ),
    );

    if (_isLocked && !isSessionUnlocked) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant);

    if (_note.contentVersion == 2 && _note.content.startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(_note.content);
        final itemsToRender = maxLines != null ? decoded.take(maxLines).toList() : decoded;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: itemsToRender.map((item) {
              final isChecked = item['isChecked'] == true;
              final text = item['text'] as String? ?? '';

              return Text(
                '${isChecked ? "◆" : "◇"} $text',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: textTheme,
              );
            }).toList(),
          ),
        );
      } catch (_) {
        // Fall back to standard text rendering if JSON parsing fails.
      }
    }

    return HighlightedText(
      text: _note.content,
      query: widget.searchQuery,
      maxLines: maxLines,
      overflow: overflow,
      normalStyle: textTheme,
      highlightStyle: textTheme.copyWith(
        backgroundColor: theme.colorScheme.primaryContainer,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _getFolderLabel(BuildContext context, {TextStyle? textStyle}) {
    final theme = Theme.of(context);
    final accent = _folderAccentColor;
    final effectiveStyle = textStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent ?? theme.colorScheme.outline,
          ),
        ),
        const SizedBox(width: 6.0),
        Flexible(
          child: Text(
            _folder!.name,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
