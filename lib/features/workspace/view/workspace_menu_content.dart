import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../models/workspace_model.dart';
import '../providers/active_workspace_provider.dart';
import '../providers/workspace_providers.dart';
import 'helpers/workspace_badge_helper.dart';
import 'widgets/create_workspace_dialog.dart';
import 'widgets/workspace_tile.dart';

enum _WorkspaceSubView { main, workspaces }

class WorkspaceMenuContent extends ConsumerStatefulWidget {
  final VoidCallback onCloseMenu;

  const WorkspaceMenuContent({
    super.key,
    required this.onCloseMenu,
  });

  @override
  ConsumerState<WorkspaceMenuContent> createState() => _WorkspaceMenuContentState();
}

class _WorkspaceMenuContentState extends ConsumerState<WorkspaceMenuContent> {
  _WorkspaceSubView _activeSubView = _WorkspaceSubView.main;

  @override
  Widget build(BuildContext context) {
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspaces = ref.watch(workspacesListProvider);
    final authUser = ref.watch(authStateProvider).value;
    final syncMode = ref.watch(syncModeProvider);

    if (_activeSubView == _WorkspaceSubView.workspaces) {
      return _buildWorkspacesPanel(
        context: context,
        workspaces: workspaces,
        activeWorkspace: activeWorkspace,
        authUser: authUser,
      );
    }

    return _buildMainPanel(
      context: context,
      activeWorkspace: activeWorkspace,
      authUser: authUser,
      syncMode: syncMode,
    );
  }

  Widget _buildMainPanel({
    required BuildContext context,
    required Workspace activeWorkspace,
    required User? authUser,
    required SyncMode syncMode,
  }) {
    final recentWorkspaces = ref
        .watch(workspacesListProvider)
        .where((w) => w.id != activeWorkspace.id)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    final top3Recent = recentWorkspaces.take(3).toList();

    final colorSchema = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, activeWorkspace, authUser, syncMode),
        if (top3Recent.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'Recent',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorSchema.onSurfaceVariant),
            ),
          ),
          ...top3Recent.map((workspace) {
            return WorkspaceTile(
              workspace: workspace,
              activeWorkspace: activeWorkspace,
              authUser: authUser,
              onMenuDismiss: widget.onCloseMenu,
              onSelect: (selectedWorkspace) async {
                widget.onCloseMenu();
                if (selectedWorkspace.id != activeWorkspace.id) {
                  await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(selectedWorkspace);
                  SnackBarManager.show(
                    msg: 'Switched to workspace "${selectedWorkspace.name}".',
                    type: SnackBarMessageType.acknowledgment,
                  );
                }
              },
            );
          }),
        ],
        const Divider(height: 1),
        _buildExpandableTile(
          context: context,
          icon: Icons.switch_account_outlined,
          title: 'Switch workspace',
          onTap: () {
            setState(() {
              _activeSubView = _WorkspaceSubView.workspaces;
            });
          },
        ),
        const Divider(height: 1),
        _buildActionItem(
          context: context,
          icon: Icons.add_circle_outline_rounded,
          title: 'Create new workspace',
          onTap: () {
            widget.onCloseMenu();
            showDialog(
              context: context,
              builder: (ctx) => const CreateWorkspaceDialog(),
            );
          },
        ),
        // if (syncMode.isCloud) ...[
        //   const Divider(height: 1),
        //   if (authUser != null)
        //     _buildActionItem(
        //       context: context,
        //       icon: Icons.logout_rounded,
        //       title: 'Sign out',
        //       onTap: () => _handleSignOut(context),
        //     )
        //   else
        //     _buildActionItem(
        //       context: context,
        //       icon: Icons.login_rounded,
        //       title: 'Sign in with Google',
        //       onTap: () => _handleSignIn(context),
        //     ),
        // ],
        // const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWorkspacesPanel({
    required BuildContext context,
    required List<Workspace> workspaces,
    required Workspace activeWorkspace,
    required User? authUser,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () {
                  setState(() {
                    _activeSubView = _WorkspaceSubView.main;
                  });
                },
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Text(
                'Switch workspace',
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...workspaces.map((workspace) {
          return WorkspaceTile(
            workspace: workspace,
            activeWorkspace: activeWorkspace,
            authUser: authUser,
            onMenuDismiss: widget.onCloseMenu,
            onSelect: (selectedWorkspace) async {
              widget.onCloseMenu();
              if (selectedWorkspace.id != activeWorkspace.id) {
                await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(selectedWorkspace);
                SnackBarManager.show(
                  msg: 'Switched to workspace "${selectedWorkspace.name}".',
                  type: SnackBarMessageType.acknowledgment,
                );
              }
            },
          );
        }),
        const Divider(height: 1),
        _buildActionItem(
          context: context,
          icon: Icons.add_circle_outline_rounded,
          title: 'Create new workspace',
          onTap: () {
            widget.onCloseMenu();
            showDialog(
              context: context,
              builder: (ctx) => const CreateWorkspaceDialog(),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpandableTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? statusText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (statusText != null) ...[
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Workspace activeWorkspace, User? authUser, SyncMode syncMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: WorkspaceBadgeHelper.getColor(activeWorkspace.name),
            child: Text(
              WorkspaceBadgeHelper.getInitial(activeWorkspace.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activeWorkspace.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        widget.onCloseMenu();
                        showDialog(
                          context: context,
                          builder: (ctx) => CreateWorkspaceDialog(workspaceToEdit: activeWorkspace),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Manage',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (syncMode.isCloud) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          (authUser != null && authUser.email != null && authUser.email!.isNotEmpty)
                              ? authUser.email!
                              : 'not signed in',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) ...[trailing],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    widget.onCloseMenu();

    final authRepo = ref.read(authRepositoryProvider);
    final signedInUser = await authRepo.signInWithGoogle();

    if (signedInUser != null) {
      ref.read(syncOrchestratorProvider).triggerSync();
      SnackBarManager.show(
        msg: 'Signed in as ${signedInUser.email ?? "Google User"}.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    widget.onCloseMenu();

    await ref.read(authRepositoryProvider).signOut();

    SnackBarManager.show(
      msg: 'Signed out successfully.',
      type: SnackBarMessageType.acknowledgment,
    );
  }
}
