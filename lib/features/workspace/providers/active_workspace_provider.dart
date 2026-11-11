import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_orchestrator.dart';
import '../../../core/util/logger.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../features/cloud_sync/data/cloud_sync_service.dart';
import '../../../features/folders/core/providers.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
import '../../../features/reminder/reminder_manager.dart';
import '../data/workspace_repository.dart';
import '../models/workspace_model.dart';
import 'workspace_providers.dart';

class WorkspaceSwitchingState {
  final bool isSwitching;
  final Workspace? targetWorkspace;

  const WorkspaceSwitchingState({
    this.isSwitching = false,
    this.targetWorkspace,
  });
}

final workspaceSwitchingProvider = NotifierProvider<WorkspaceSwitchingNotifier, WorkspaceSwitchingState>(() {
  return WorkspaceSwitchingNotifier();
});

class WorkspaceSwitchingNotifier extends Notifier<WorkspaceSwitchingState> {
  @override
  WorkspaceSwitchingState build() => const WorkspaceSwitchingState();

  void startSwitch(Workspace target) {
    state = WorkspaceSwitchingState(isSwitching: true, targetWorkspace: target);
  }

  void endSwitch() {
    state = const WorkspaceSwitchingState(isSwitching: false, targetWorkspace: null);
  }
}

/// Riverpod provider managing the currently active user workspace.
final activeWorkspaceProvider = NotifierProvider<ActiveWorkspaceNotifier, Workspace>(() {
  return ActiveWorkspaceNotifier();
});

class ActiveWorkspaceNotifier extends Notifier<Workspace> {
  bool _isSwitching = false;

  /// Returns true if a workspace switch operation is currently in progress.
  bool get isSwitching => _isSwitching;

  @override
  Workspace build() {
    final prefs = ref.watch(sharedPreferenceProvider);
    final savedWorkspaceId = prefs.activeWorkspaceId;
    final repo = WorkspaceRepository.instance;

    if (savedWorkspaceId != null) {
      final workspace = repo.getWorkspaceById(savedWorkspaceId);
      if (workspace != null) {
        return workspace;
      }
    }

    // Default fallback to primary 'Default' workspace
    return WorkspaceRepository.defaultWorkspace;
  }

  /// Switches the active workspace to [targetWorkspace].
  ///
  /// Executes instant local database handle swap:
  /// 1. Stops active cloud sync listeners.
  /// 2. Clears active UI selection states (selected note, folder, search query).
  /// 3. Flushes session lock tokens.
  /// 4. Cancels pending OS system notifications for previous workspace.
  /// 5. Saves [targetWorkspace.id] in SharedPreferences & updates `lastUsedAt`.
  /// 6. Updates Riverpod state -> triggers SQLite connection swap via `localDatabaseProvider`.
  /// 7. Re-arms pending reminders from the new active workspace's database.
  /// 8. Re-evaluates sync orchestrator state so sync engine re-binds to new workspace.
  Future<void> switchWorkspace(Workspace targetWorkspace) async {
    if (state.id == targetWorkspace.id || _isSwitching) return;

    _isSwitching = true;
    ref.read(workspaceSwitchingProvider.notifier).startSwitch(targetWorkspace);
    try {
      AppLogger.d('ActiveWorkspaceNotifier: Switching workspace from "${state.name}" (${state.id}) to "${targetWorkspace.name}" (${targetWorkspace.id})...');

      // 1. Stop active cloud sync listeners
      ref.read(cloudSyncServiceProvider).stop();

      // 2. Clear active UI selection states
      ref.read(activeNoteProvider.notifier).clear();
      ref.read(activeFolderProvider.notifier).clear();
      ref.read(searchQueryProvider.notifier).clear();

      // 3. Clear unlocked note sessions for security
      ref.read(lockManagerProvider.notifier).clearAllSessions();

      // 4. Cancel scheduled local OS notifications for previous workspace
      await ReminderManager().cancelAllNotifications();

      // 5. Update SharedPreferences & touch lastUsedAt timestamp
      await ref.read(sharedPreferenceProvider).setActiveWorkspaceId(targetWorkspace.id);
      await WorkspaceRepository.instance.touchWorkspaceLastUsed(targetWorkspace.id);
      ref.read(workspacesListProvider.notifier).refresh();

      // 6. Update state -> triggers Riverpod rebuild, syncModeProvider update & SQLite handle swap
      state = targetWorkspace;

      // 7. Re-arm pending reminders from newly active workspace's database
      ReminderManager().rearmPendingReminders();

      AppLogger.d('ActiveWorkspaceNotifier: Successfully switched active workspace to ${targetWorkspace.name}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      _isSwitching = false;
      ref.read(workspaceSwitchingProvider.notifier).endSwitch();
      ref.read(syncOrchestratorProvider).evaluateState();
    }
  }

  /// Updates the current active workspace's metadata without triggering database handle teardown.
  void updateActiveWorkspace(Workspace updatedWorkspace) {
    if (state.id == updatedWorkspace.id) {
      state = updatedWorkspace;
    }
  }
}
