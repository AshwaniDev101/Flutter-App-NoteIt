import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_engine.dart';
import '../../models/workspace_model.dart';
import '../../providers/active_workspace_provider.dart';
import '../helpers/workspace_badge_helper.dart';

/// A sleek, non-disruptive loading overlay displayed over notes/content panels
/// during workspace switching.
class WorkspaceSwitchOverlay extends ConsumerWidget {
  final Widget child;

  const WorkspaceSwitchOverlay({
    super.key,
    required this.child,
  });

  SyncEngine _getSyncEngine(Workspace? workspace) {
    if (workspace == null) return SyncEngine.offline;
    if (workspace.syncMode == 'cloud') return SyncEngine.cloud;
    if (workspace.syncMode == 'localHost' ||
        workspace.syncMode == 'localClient' ||
        workspace.syncMode == 'localUndefined') {
      return SyncEngine.local;
    }
    return SyncEngine.offline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switchingState = ref.watch(workspaceSwitchingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSwitching = switchingState.isSwitching;
    final targetWorkspace = switchingState.targetWorkspace;
    final workspaceName = targetWorkspace?.name ?? 'Workspace';

    final syncEngine = _getSyncEngine(targetWorkspace);

    return Stack(
      children: [
        child,

        // Centered animated overlay layer
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            reverseDuration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isSwitching
                ? SizedBox.expand(
                    key: ValueKey('workspace_switch_overlay_active_${targetWorkspace?.id}'),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.70),
                          child: Center(
                            child: Card(
                              elevation: 8,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              child: SizedBox(
                                width: 320,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: WorkspaceBadgeHelper.getColor(workspaceName),
                                            child: Text(
                                              WorkspaceBadgeHelper.getInitial(workspaceName),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Switching workspace...',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  workspaceName,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      syncEngine.icon,
                                                      size: 12,
                                                      color: colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      syncEngine.label,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontSize: 11,
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const LinearProgressIndicator(minHeight: 3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('workspace_switch_overlay_inactive')),
          ),
        ),
      ],
    );
  }
}
