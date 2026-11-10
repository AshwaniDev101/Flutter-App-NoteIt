import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_orchestrator.dart';
import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../database/drift/notes/notes_dao.dart';
import '../../../shared/note_card/core/note_action_controller.dart';
import '../../home/core/providers.dart';

class TrashState {
  final bool isSelectMode;
  final bool isLoading;
  final String? error;
  final Set<String> selectedNoteIds;
  final Set<String> selectedFolderIds;

  const TrashState({
    this.isSelectMode = false,
    this.isLoading = false,
    this.error,
    this.selectedNoteIds = const {},
    this.selectedFolderIds = const {},
  });

  TrashState copyWith({
    bool? isSelectMode,
    bool? isLoading,
    String? error,
    Set<String>? selectedNoteIds,
    Set<String>? selectedFolderIds,
  }) {
    return TrashState(
      isSelectMode: isSelectMode ?? this.isSelectMode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      selectedFolderIds: selectedFolderIds ?? this.selectedFolderIds,
    );
  }
}

class TrashViewModel extends Notifier<TrashState> {
  @override
  TrashState build() => const TrashState();

  void toggleNoteSelection(String uuid) {
    final noteIds = Set<String>.from(state.selectedNoteIds);
    if (noteIds.contains(uuid)) {
      noteIds.remove(uuid);
    } else {
      if (!state.isSelectMode || !ref.read(rightPanelSelectionProvider).isSelecting) {
        ref.read(rightPanelSelectionProvider.notifier).enterSelection(onClear: clearSelection);
      }
      noteIds.add(uuid);
    }

    final shouldBeSelectMode = noteIds.isNotEmpty || state.selectedFolderIds.isNotEmpty;
    if (!shouldBeSelectMode && state.isSelectMode) {
      ref.read(rightPanelSelectionProvider.notifier).exitSelection();
    }

    state = state.copyWith(
      selectedNoteIds: noteIds,
      isSelectMode: shouldBeSelectMode,
    );
  }

  void toggleFolderSelection(String uuid) {
    final folderIds = Set<String>.from(state.selectedFolderIds);
    if (folderIds.contains(uuid)) {
      folderIds.remove(uuid);
    } else {
      if (!state.isSelectMode || !ref.read(rightPanelSelectionProvider).isSelecting) {
        ref.read(rightPanelSelectionProvider.notifier).enterSelection(onClear: clearSelection);
      }
      folderIds.add(uuid);
    }

    final shouldBeSelectMode = state.selectedNoteIds.isNotEmpty || folderIds.isNotEmpty;
    if (!shouldBeSelectMode && state.isSelectMode) {
      ref.read(rightPanelSelectionProvider.notifier).exitSelection();
    }

    state = state.copyWith(
      selectedFolderIds: folderIds,
      isSelectMode: shouldBeSelectMode,
    );
  }

  void enableSelectMode() {
    state = state.copyWith(isSelectMode: true);
  }

  void clearSelection() {
    ref.read(rightPanelSelectionProvider.notifier).exitSelection();
    state = state.copyWith(
      isSelectMode: false,
      selectedNoteIds: const {},
      selectedFolderIds: const {},
    );
  }

  void toggleSelectAll(List<NoteWithFolder> notes, List<Folder> folders) {
    final isAllSelected = notes.isNotEmpty &&
        state.selectedNoteIds.length == notes.length &&
        state.selectedFolderIds.length == folders.length;

    if (isAllSelected) {
      clearSelection();
    } else {
      if (!state.isSelectMode || !ref.read(rightPanelSelectionProvider).isSelecting) {
        ref.read(rightPanelSelectionProvider.notifier).enterSelection(onClear: clearSelection);
      }
      state = state.copyWith(
        isSelectMode: true,
        selectedNoteIds: Set<String>.from(notes.map((n) => n.note.uuid)),
        selectedFolderIds: Set<String>.from(folders.map((f) => f.uuid)),
      );
    }
  }

  Future<void> emptyTrash() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(noteActionsControllerProvider).emptyLocalAndCloudTrash();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<int> restoreItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    state = state.copyWith(isLoading: true, error: null);
    final notesDao = ref.read(notesDaoProvider);
    final foldersDao = ref.read(foldersDaoProvider);

    try {
      if (noteUuids != null) {
        for (final uuid in noteUuids) {
          await notesDao.restoreNote(uuid);
        }
      }

      if (folderUuids != null) {
        for (final uuid in folderUuids) {
          await foldersDao.restoreFolder(uuid);
        }
      }

      ref.read(syncOrchestratorProvider).triggerSync();

      final updatedNotes = Set<String>.from(state.selectedNoteIds);
      final updatedFolders = Set<String>.from(state.selectedFolderIds);
      if (noteUuids != null) updatedNotes.removeAll(noteUuids);
      if (folderUuids != null) updatedFolders.removeAll(folderUuids);

      final shouldBeSelectMode = updatedNotes.isNotEmpty || updatedFolders.isNotEmpty;
      if (!shouldBeSelectMode && state.isSelectMode) {
        ref.read(rightPanelSelectionProvider.notifier).exitSelection();
      }

      state = state.copyWith(
        isLoading: false,
        selectedNoteIds: updatedNotes,
        selectedFolderIds: updatedFolders,
        isSelectMode: shouldBeSelectMode,
      );

      return (noteUuids?.length ?? 0) + (folderUuids?.length ?? 0);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref
          .read(noteActionsControllerProvider)
          .hardDeleteSelection(noteUuids: noteUuids, folderUuids: folderUuids);

      final updatedNotes = Set<String>.from(state.selectedNoteIds);
      final updatedFolders = Set<String>.from(state.selectedFolderIds);
      if (noteUuids != null) updatedNotes.removeAll(noteUuids);
      if (folderUuids != null) updatedFolders.removeAll(folderUuids);

      final shouldBeSelectMode = updatedNotes.isNotEmpty || updatedFolders.isNotEmpty;
      if (!shouldBeSelectMode && state.isSelectMode) {
        ref.read(rightPanelSelectionProvider.notifier).exitSelection();
      }

      state = state.copyWith(
        isLoading: false,
        selectedNoteIds: updatedNotes,
        selectedFolderIds: updatedFolders,
        isSelectMode: shouldBeSelectMode,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final trashViewModelProvider = NotifierProvider<TrashViewModel, TrashState>(
  TrashViewModel.new,
);
