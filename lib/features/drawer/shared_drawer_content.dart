import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

import '../../core/config/app_env.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import '../archive/providers/archive_providers.dart';
import '../trash/providers/trash_providers.dart';
import '../workspace/view/helpers/workspace_badge_helper.dart';

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- App Branding Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/note_icon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${AppEnv.version}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),

          // --- Account Header & Auth Actions ---
          const _DrawerAuthHeaderWidget(),

          const SizedBox(height: 12),
          Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),

          // --- Scrollable Navigation ---
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
                    _DrawerTile(
                      label: RightPanelPageOptions.trash.label,
                      icon: Icon(RightPanelPageOptions.trash.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.trash,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.trash),
                      onSecondaryTapUp: (details) => _showTrashContextMenu(context, details),
                      count: trashCount,
                    ),
                    const SizedBox(height: 8),

                    Divider(height: 24, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),

                    const _SectionHeader(title: 'SYSTEM'),
                    _DrawerTile(
                      label: RightPanelPageOptions.localSync.label,
                      icon: Icon(RightPanelPageOptions.localSync.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.localSync,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.localSync),
                    ),
                    _DrawerTile(
                      label: RightPanelPageOptions.themes.label,
                      icon: Icon(RightPanelPageOptions.themes.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.themes,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.themes),
                    ),
                    _DrawerTile(
                      label: RightPanelPageOptions.settings.label,
                      icon: Icon(RightPanelPageOptions.settings.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.settings,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.settings),
                    ),
                    _DrawerTile(
                      label: RightPanelPageOptions.devTools.label,
                      icon: Icon(RightPanelPageOptions.devTools.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.devTools,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.devTools),
                    ),
                    _DrawerTile(
                      label: RightPanelPageOptions.archivePage.label,
                      icon: Icon(RightPanelPageOptions.archivePage.icon),
                      isSelected: widget.selectedOption == RightPanelPageOptions.archivePage,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.archivePage),
                      count: archiveCount,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(TapUpDetails details)? onSecondaryTapUp;
  final int? count;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onSecondaryTapUp,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final contentColor = isSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        onSecondaryTapUp: onSecondaryTapUp,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: colorScheme.secondaryContainer, width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              IconTheme(
                data: IconThemeData(
                  color: contentColor,
                  size: 20,
                ),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: contentColor,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
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

class _DrawerAuthHeaderWidget extends ConsumerStatefulWidget {
  const _DrawerAuthHeaderWidget();

  @override
  ConsumerState<_DrawerAuthHeaderWidget> createState() => _DrawerAuthHeaderWidgetState();
}

class _DrawerAuthHeaderWidgetState extends ConsumerState<_DrawerAuthHeaderWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final authRepo = ref.read(authRepositoryProvider);
                  final signedInUser = await authRepo.signInWithGoogle();
                  if (signedInUser != null) {
                    SnackBarManager.show(
                      msg: 'Signed in as ${signedInUser.email}',
                      type: SnackBarMessageType.acknowledgment,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const GoogleLogoBadge(size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sign in to sync',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isExpanded
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tappable Auth Card
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                            child: user.photoURL == null
                                ? Text(
                                    (user.displayName?.isNotEmpty == true
                                            ? user.displayName![0]
                                            : (user.email?[0] ?? 'U'))
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.displayName ?? 'Google User',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  user.email ?? '',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Collapsible Sign Out Button
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Divider(
                              height: 1,
                              indent: 12,
                              endIndent: 12,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final authRepo = ref.read(authRepositoryProvider);
                                    await authRepo.signOut();
                                    if (mounted) {
                                      setState(() {
                                        _isExpanded = false;
                                      });
                                    }
                                    SnackBarManager.show(
                                      msg: 'Signed out successfully.',
                                      type: SnackBarMessageType.info,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.logout_rounded,
                                          size: 18,
                                          color: colorScheme.error,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Sign out',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
