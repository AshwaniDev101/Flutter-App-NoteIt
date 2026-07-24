import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePageState {
  final bool isSelectMode;
  final bool isSearchMode;
  final Set<int> selectedNoteIds;

  const HomePageState({this.isSelectMode = false, this.isSearchMode = false, this.selectedNoteIds = const {}});

  HomePageState copyWith({bool? isSelectMode, bool? isSearchMode, Set<int>? selectedNoteIds}) {
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

  void toggleSelection(int id) {
    final currentSet = Set<int>.from(state.selectedNoteIds);
    if (currentSet.contains(id)) {
      currentSet.remove(id);
      final keepsSelectionMode = currentSet.isNotEmpty;
      state = state.copyWith(selectedNoteIds: currentSet, isSelectMode: keepsSelectionMode);
    } else {
      currentSet.add(id);
      state = state.copyWith(selectedNoteIds: currentSet, isSelectMode: true);
    }
  }

  void toggleSelectAll(List<int> allNoteIds) {
    if (allNoteIds.isEmpty) return;

    final isAllSelected = state.selectedNoteIds.length == allNoteIds.length;
    if (isAllSelected) {
      clearSelection();
    } else {
      state = state.copyWith(isSelectMode: true, selectedNoteIds: Set<int>.from(allNoteIds));
    }
  }

  void enableSelectMode() {
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

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomePageState>(HomeViewModel.new);
