import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../data/workspace_repository.dart';
import '../models/workspace_model.dart';

/// Riverpod provider exposing access to [WorkspaceRepository].
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository.instance;
});

/// Riverpod provider exposing an unmodifiable list of all available user workspaces.
final workspacesListProvider = NotifierProvider<WorkspacesListNotifier, List<Workspace>>(() {
  return WorkspacesListNotifier();
});

class WorkspacesListNotifier extends Notifier<List<Workspace>> {
  @override
  List<Workspace> build() {
    return ref.watch(workspaceRepositoryProvider).getWorkspaces();
  }

  /// Refreshes the active workspaces list from the repository.
  void refresh() {
    state = ref.read(workspaceRepositoryProvider).getWorkspaces();
  }

  /// Creates a new workspace and refreshes the workspaces list state & triggers sync.
  Future<Workspace> createWorkspace({
    required String name,
  }) async {
    final repo = ref.read(workspaceRepositoryProvider);
    final newWorkspace = await repo.createWorkspace(
      name: name,
    );
    refresh();
    ref.read(syncOrchestratorProvider).triggerSync();
    return newWorkspace;
  }

  /// Updates an existing workspace and refreshes the workspaces list state & triggers sync.
  Future<bool> updateWorkspace(Workspace workspace) async {
    final repo = ref.read(workspaceRepositoryProvider);
    final success = await repo.updateWorkspace(workspace);
    if (success) {
      refresh();
      ref.read(syncOrchestratorProvider).triggerSync();
    }
    return success;
  }

  /// Deletes a workspace and refreshes the workspaces list state & triggers sync.
  Future<bool> deleteWorkspace(String workspaceId) async {
    final repo = ref.read(workspaceRepositoryProvider);
    final success = await repo.deleteWorkspace(workspaceId);
    if (success) {
      refresh();
      ref.read(syncOrchestratorProvider).triggerSync();
    }
    return success;
  }
}
