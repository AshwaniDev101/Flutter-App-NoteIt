import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/core/helpers/time_helper.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/lock/lock_manger/lock_manager.dart';
import 'package:noteit/shared/note_card/widgets/lock_overlay.dart';
import 'package:noteit/shared/menus/view_menu_button.dart';

import '../text/highlighted_text.dart';
import 'core/note_action.dart';

/// A card widget displaying a note summary across list and grid layouts.
class NoteCard extends ConsumerStatefulWidget {
  final NoteWithFolder noteWithFolder;
  final bool isSelected;
  final String searchQuery;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(NoteAction)? onContextMenuAction;
  final List<NoteAction> contextMenuOptions;

  static const List<NoteAction> defaultContextMenuOptions = [
    NoteAction.select,
    NoteAction.pin,
    NoteAction.lock,
    NoteAction.reminder,
    NoteAction.moveTo,
    NoteAction.duplicate,
    NoteAction.openNewWindow,
    NoteAction.archive,
    NoteAction.delete,
  ];

  final NoteViewType? viewType;

  const NoteCard({
    super.key,
    required this.noteWithFolder,
    this.viewType,
    this.isSelected = false,
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
    final accentColor = _folderAccentColor;

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
            setState(() => _isFocused = hasFocus);
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
            child: _buildLayoutRouter(viewType, accentColor),
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

      final color = effectiveOption.isDestructive ? errorColor : null;

      return MenuItemButton(
        leadingIcon: Icon(
          effectiveOption.icon,
          color: color,
        ),
        onPressed: () => widget.onContextMenuAction?.call(effectiveOption),
        child: Text(
          effectiveOption.label,
          style: TextStyle(color: color),
        ),
      );
    }).toList();
  }

  Widget _buildLayoutRouter(NoteViewType viewType, Color? accentColor) {
    switch (viewType) {
      case NoteViewType.list:
        return _buildFlatListWrapper(child: _buildCompactList(), accentColor: accentColor);
      case NoteViewType.detailedList:
        return _buildCardWrapper(child: _buildDetailedList(), accentColor: accentColor);
      case NoteViewType.grid:
        return _buildCardWrapper(child: _buildGrid(), accentColor: accentColor);
      case NoteViewType.largeGrid:
        return _buildCardWrapper(child: _buildLargeGrid(), accentColor: accentColor);
    }
  }

  Widget _buildWithCornerAccent({
    required Widget child,
    required Color? accentColor,
    double size = 14,
  }) {
    if (accentColor == null) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(size, size),
              painter: CornerTrianglePainter(color: accentColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required Color? accentColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = _buildWithCornerAccent(child: child, accentColor: accentColor, size: 14);

    return Card(
      margin: const EdgeInsets.all(4.0),
      elevation: widget.isSelected ? 1 : (_isFocused ? 4 : 0),
      clipBehavior: Clip.antiAlias,
      color: widget.isSelected ? colorScheme.primary.withValues(alpha: 0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _isFocused
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        canRequestFocus: false,
        child: content,
      ),
    );
  }

  Widget _buildFlatListWrapper({required Widget child, required Color? accentColor}) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor;
    if (widget.isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.3);
    } else if (_isFocused) {
      backgroundColor = colorScheme.surfaceContainerHighest;
    } else {
      backgroundColor = colorScheme.surface;
    }

    final content = _buildWithCornerAccent(child: child, accentColor: accentColor, size: 10);

    return Material(
      color: backgroundColor,
      shape: Border(
        bottom: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        canRequestFocus: false,
        child: content,
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
        if (_isPinned) ...[
          const SizedBox(width: 8),
          Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
        ],
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, {TextStyle? textStyle}) {
    final colorScheme = Theme.of(context).colorScheme;
    final platform = _note.deletedPlatform ?? _note.creationPlatform;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            TimeHelper.formatTimeAgo(_note.updatedAt),
            style: textStyle ?? Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (platform != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: _note.deletedPlatform != null ? 'Deleted on $platform' : 'Created on $platform',
            child: _getPlatformIcon(platform, colorScheme),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactList() {
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
          if (_isPinned) ...[
            const SizedBox(width: 8),
            Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleHeader(
            context,
            textStyle: Theme.of(context).textTheme.titleMedium,
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
          _buildMetadataRow(context),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleHeader(
            context,
            textStyle: Theme.of(context).textTheme.titleMedium,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleHeader(
            context,
            textStyle: Theme.of(context).textTheme.titleMedium,
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
              ],
            ),
          ),
          if (PlatformHelper.isDesktopScreen) ...[
            const SizedBox(height: 4),
            _buildMetadataRow(
              context,
              textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotePreview(
    BuildContext context, {
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    final isSessionUnlocked =
        ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(_note.uuid);

    if (_isLocked && !isSessionUnlocked) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme.bodyMedium!.copyWith(color:Theme.of(context).colorScheme.onSurfaceVariant);

    if (_note.contentVersion == 2) {
      try {
        final List<dynamic> decoded = jsonDecode(_note.content);
        final itemsToRender = maxLines != null ? decoded.take(maxLines).toList() : decoded;

        return Column(
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
        );
      } catch (_) {
        // Fall back to standard text parsing if JSON decoding fails.
      }
    }

    return HighlightedText(
      text: _note.content,
      query: widget.searchQuery,
      maxLines: maxLines,
      overflow: overflow,
      normalStyle: textTheme,
      highlightStyle: textTheme?.copyWith(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _getPlatformIcon(String platform, ColorScheme colorScheme) {
    final iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    switch (platform.toLowerCase()) {
      case 'android':
        return Icon(Icons.phone_android_rounded, size: 14, color: iconColor);
      case 'ios':
        return Icon(Icons.phone_iphone_rounded, size: 14, color: iconColor);
      case 'windows':
        return Icon(Icons.desktop_windows_sharp, size: 14, color: iconColor);
      default:
        return Icon(Icons.computer, size: 14, color: iconColor);
    }
  }
}

/// Paints a triangle accent in the top-left corner of a card or list item.
class CornerTrianglePainter extends CustomPainter {
  final Color color;

  const CornerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CornerTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
