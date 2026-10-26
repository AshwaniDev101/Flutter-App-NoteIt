import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/router/router.dart';
import '../../core/util/platform_helper.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../home/core/providers.dart';
import '../home/view/desktop/content_panel/core/navigator.dart';

/// Standalone showcase window widget rendered in a secondary DesktopMultiWindow process.
class NoteShowcaseMultiWindow extends StatelessWidget {
  final int windowId;
  final String title;
  final String content;
  final String? folderName;
  final int? colorIndex;
  final String? reminderAtStr;

  const NoteShowcaseMultiWindow({
    super.key,
    required this.windowId,
    required this.title,
    required this.content,
    this.folderName,
    this.colorIndex,
    this.reminderAtStr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final folderAccentColor = folderName != null && colorIndex != null
        ? Colors.primaries[colorIndex! % Colors.primaries.length]
        : Colors.transparent;

    final displayTitle =
        title.trim().isNotEmpty ? title.trim() : 'Untitled Note';
    final displayContent =
        content.trim().isNotEmpty ? content.trim() : 'No content available.';

    DateTime? reminderDate;
    if (reminderAtStr != null && reminderAtStr!.isNotEmpty) {
      try {
        reminderDate = DateTime.parse(reminderAtStr!);
      } catch (_) {}
    }

    const double leftPadding = 48.0;
    const double rightPadding = 48.0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (folderName != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: folderAccentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: folderAccentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 14, color: folderAccentColor),
                      const SizedBox(width: 6),
                      Text(
                        folderName!,
                        style: textTheme.labelSmall?.copyWith(
                          color: folderAccentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (reminderDate != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: colorScheme.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(reminderDate),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Showcase Mode • Uneditable',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close Window',
            onPressed: () {
              windowManager.close();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (folderName != null)
            Container(
              height: 4,
              width: double.infinity,
              color: folderAccentColor,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: leftPadding, right: rightPadding, top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    displayTitle,
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        displayContent,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// In-app fallback showcase page styled like DesktopEditNotePage (Disabled/Read-only).
class NoteShowcasePage extends ConsumerWidget {
  final NoteWithFolder? noteWithFolder;

  const NoteShowcasePage({super.key, this.noteWithFolder});

  Future<void> _restoreFullApp(BuildContext context, WidgetRef ref) async {
    if (PlatformHelper.isNativeDesktop) {
      final savedWidth = SharedPreferenceManager.instance.windowWidth;
      final savedHeight = SharedPreferenceManager.instance.windowHeight;
      await windowManager.setSize(Size(savedWidth, savedHeight));
    }

    if (noteWithFolder != null) {
      ref.read(activeNoteProvider.notifier).setNote(noteWithFolder!);
      ref
          .read(desktopRightPanelViewProvider.notifier)
          .setView(RightPanelPageOptions.noteEditor);
    }

    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  String _getFormattedDate() {
    final now = noteWithFolder?.note.updatedAt ??
        noteWithFolder?.note.createdAt ??
        DateTime.now();
    return "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final panelColor = colorScheme.surfaceContainerLow;

    final note = noteWithFolder?.note;
    final currentFolder = noteWithFolder?.folder;

    final folderAccentColor = currentFolder != null
        ? Colors.primaries[currentFolder.colorIndex % Colors.primaries.length]
        : Colors.transparent;

    final titleText =
        note?.title.trim().isNotEmpty == true ? note!.title : 'Untitled Note';
    final contentText = note?.content.trim().isNotEmpty == true
        ? note!.content
        : 'No content available.';

    const double leftPadding = 48.0;
    const double rightPadding = 48.0;

    return Scaffold(
      backgroundColor: panelColor,
      appBar: AppBar(
        backgroundColor: panelColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (currentFolder != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: folderAccentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: folderAccentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 14, color: folderAccentColor),
                      const SizedBox(width: 6),
                      Text(
                        currentFolder.name,
                        style: textTheme.labelSmall?.copyWith(
                          color: folderAccentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                "Edited ${_getFormattedDate()}",
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 12, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Showcase • Read Only',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close Showcase',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                windowManager.close();
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Folder Accent Line
          if (currentFolder != null)
            Container(
              height: 4,
              width: double.infinity,
              color: folderAccentColor,
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: leftPadding, right: rightPadding, top: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read-Only Title
                  SelectableText(
                    titleText,
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),

                  // Read-Only Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        contentText,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: leftPadding, vertical: 12.0),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: Border(
                top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      'Disabled / Read Only Mode',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _restoreFullApp(context, ref),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open Full App 📝'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}