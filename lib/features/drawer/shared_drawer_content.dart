import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

import '../../core/config/app_env.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import '../archive/providers/archive_providers.dart';
import '../trash/providers/trash_providers.dart';

class SharedDrawerContent extends ConsumerStatefulWidget {
  final RightPanelPageOptions? selectedOption;
  final void Function(RightPanelPageOptions) onOptionSelected;
  final VoidCallback onClose;

  const SharedDrawerContent({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onClose,
  });

  @override
  ConsumerState<SharedDrawerContent> createState() => _SharedDrawerContentState();
}

class _SharedDrawerContentState extends ConsumerState<SharedDrawerContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showTrashContextMenu(BuildContext context, TapUpDetails details) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'clear_trash',
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.delete_forever_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Clear trash',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == 'clear_trash' && context.mounted) {
      _handleEmptyTrash(context);
    }
  }

  Future<void> _handleEmptyTrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all notes and folders in the trash. Action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        SnackBarManager.show(msg: 'Emptying trash...', type: SnackBarMessageType.info);

        await ref.read(noteActionsControllerProvider).emptyLocalAndCloudTrash();

        if (context.mounted) {
          SnackBarManager.show(msg: 'Trash emptied successfully.', type: SnackBarMessageType.acknowledgment);
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarManager.show(msg: 'Error emptying trash', description: '$e', type: SnackBarMessageType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final trashNotesState = ref.watch(trashNotesProvider);
    final archivedNotesState = ref.watch(archivedNotesStreamProvider);

    final trashCount = trashNotesState.value?.length;
    final archiveCount = archivedNotesState.value?.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- App Branding Header ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/icons/note_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 20,
                  ),
                  children: [
                    TextSpan(
                      text: 'Note',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: 'It',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- 2. Scrollable Navigation ---
        Flexible(
          fit: FlexFit.loose,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'WORKSPACE'),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.trash,
                    isSelected: widget.selectedOption == RightPanelPageOptions.trash,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.trash),
                    onSecondaryTapUp: (details) => _showTrashContextMenu(context, details),
                    count: trashCount,
                  ),
                  const SizedBox(height: 16),

                  const _SectionHeader(title: 'SYSTEM'),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.localSync,
                    isSelected: widget.selectedOption == RightPanelPageOptions.localSync,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.localSync),
                  ),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.themes,
                    isSelected: widget.selectedOption == RightPanelPageOptions.themes,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.themes),
                  ),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.settings,
                    isSelected: widget.selectedOption == RightPanelPageOptions.settings,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.settings),
                  ),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.devTools,
                    isSelected: widget.selectedOption == RightPanelPageOptions.devTools,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.devTools),
                  ),
                  _CompactDrawerTile(
                    option: RightPanelPageOptions.archivePage,
                    isSelected: widget.selectedOption == RightPanelPageOptions.archivePage,
                    onTap: () => widget.onOptionSelected(RightPanelPageOptions.archivePage),
                    count: archiveCount,
                  ),

                  const SizedBox(height: 24),

                  // Version Info
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          "Version: ${AppEnv.version}",
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          "Build: ${AppEnv.buildNumber}",
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  final RightPanelPageOptions option;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(TapUpDetails details)? onSecondaryTapUp;
  final int? count;

  const _CompactDrawerTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.onSecondaryTapUp,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        onSecondaryTapUp: onSecondaryTapUp,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 20,
                color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
