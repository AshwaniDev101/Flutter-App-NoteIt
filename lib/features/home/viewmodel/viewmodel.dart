import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class HomePageState {
  final bool isSelectMode;
  final bool isSearchMode;

  final Set<String> selectedNoteIds;

  const HomePageState({
    this.isSelectMode = false,
    this.isSearchMode = false,
    this.selectedNoteIds = const {},
  });

  HomePageState copyWith({
    bool? isSelectMode,
    bool? isSearchMode,
    Set<String>? selectedNoteIds,
  }) {
    return HomePageState(
      isSelectMode: isSelectMode ?? this.isSelectMode,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
    );
  }
}

class HomeViewModel extends Notifier<HomePageState> {
  @override
  HomePageState build() => const HomePageState();

  void toggleSelection(String uuid) {
    final currentSet = Set<String>.from(state.selectedNoteIds);
    if (currentSet.contains(uuid)) {
      currentSet.remove(uuid);
      final keepsSelectionMode = currentSet.isNotEmpty;
      state = state.copyWith(
        selectedNoteIds: currentSet,
        isSelectMode: keepsSelectionMode,
      );
    } else {
      if (!state.isSelectMode) {
        ref.read(activeNoteProvider.notifier).clear();
      }
      currentSet.add(uuid);
      state = state.copyWith(selectedNoteIds: currentSet, isSelectMode: true);
    }
  }

  void toggleSelectAll(List<String> allNoteUuids) {
    if (allNoteUuids.isEmpty) return;

    final isAllSelected = state.selectedNoteIds.length == allNoteUuids.length;
    if (isAllSelected) {
      clearSelection();
    } else {

      // Remove any note that was previously selected
      if (!state.isSelectMode) {
        ref.read(activeNoteProvider.notifier).clear();
      }
      state = state.copyWith(
        isSelectMode: true,
        selectedNoteIds: Set<String>.from(allNoteUuids),
      );
    }
  }

  void enableSelectMode() {
    // Remove any note that was previously selected
    ref.read(activeNoteProvider.notifier).clear();
    state = state.copyWith(isSelectMode: true);
  }

  void clearSelection() {
    state = state.copyWith(isSelectMode: false, selectedNoteIds: const {});
  }

  void enterSearchMode() {
    state = state.copyWith(isSearchMode: true);
  }

  void exitSearchMode() {
    state = state.copyWith(isSearchMode: false);
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomePageState>(
  HomeViewModel.new,
);
