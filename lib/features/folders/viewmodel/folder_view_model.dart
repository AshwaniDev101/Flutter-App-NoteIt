import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_orchestrator.dart';
import '../../../core/util/logger.dart';
import '../../../database/drift/folders/folders_dao.dart';

class FolderState {
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const FolderState({
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  FolderState copyWith({
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return FolderState(
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final folderViewModelProvider = NotifierProvider<FolderViewModel, FolderState>(FolderViewModel.new);

class FolderViewModel extends Notifier<FolderState> {
  @override
  FolderState build() => const FolderState();

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  Future<String> createFolder({required String name, required int colorIndex}) async {
    state = state.copyWith(isLoading: true);
    try {
      final dao = ref.read(foldersDaoProvider);
      final uuid = await dao.addFolder(name: name, colorIndex: colorIndex);
      AppLogger.d("FolderViewModel: Created folder '$name' ($uuid)");
      ref.read(syncOrchestratorProvider).triggerSync();
      state = state.copyWith(isLoading: false);
      return uuid;
    } catch (e, stack) {
      AppLogger.e("FolderViewModel: Error creating folder", error: e, stack: stack);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> togglePinStatus(String uuid) async {
    try {
      final dao = ref.read(foldersDaoProvider);
      await dao.toggleFolderPinStatus(uuid);
      ref.read(syncOrchestratorProvider).triggerSync();
    } catch (e, stack) {
      AppLogger.e("FolderViewModel: Error toggling folder pin status", error: e, stack: stack);
    }
  }

  Future<void> updateFolder({required String uuid, required String name, required int colorIndex}) async {
    try {
      final dao = ref.read(foldersDaoProvider);
      await dao.updateFolder(uuid: uuid, name: name, colorIndex: colorIndex);
      AppLogger.d("FolderViewModel: Updated folder '$name' ($uuid)");
      ref.read(syncOrchestratorProvider).triggerSync();
    } catch (e, stack) {
      AppLogger.e("FolderViewModel: Error updating folder", error: e, stack: stack);
    }
  }

  Future<void> softDeleteFolder(String uuid, {String platform = 'desktop'}) async {
    try {
      final dao = ref.read(foldersDaoProvider);
      await dao.softDeleteFolder(uuid, platform: platform);
      AppLogger.d("FolderViewModel: Soft-deleted folder '$uuid'");
      ref.read(syncOrchestratorProvider).triggerSync();
    } catch (e, stack) {
      AppLogger.e("FolderViewModel: Error soft-deleting folder", error: e, stack: stack);
    }
  }
}
