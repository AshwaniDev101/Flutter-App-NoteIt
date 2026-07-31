import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

class TabViewState {
  final List<Note> openTabs;
  final int activeTabIndex;

  const TabViewState({
    this.openTabs = const [],
    this.activeTabIndex = 0,
  });

  TabViewState copyWith({
    List<Note>? openTabs,
    int? activeTabIndex,
  }) {
    return TabViewState(
      openTabs: openTabs ?? this.openTabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

class TabViewModel extends Notifier<TabViewState> {
  @override
  TabViewState build() => const TabViewState();

  void openTab(Note note) {
    final existingIndex = state.openTabs.indexWhere((t) => t.id == note.id);

    if (existingIndex != -1) {
      // Note is already open, just switch to it
      state = state.copyWith(activeTabIndex: existingIndex);
    } else {
      // Add new note and set it as active
      final newTabs = [...state.openTabs, note];
      state = state.copyWith(
        openTabs: newTabs,
        activeTabIndex: newTabs.length - 1,
      );
    }
  }

  void closeTab(int index) {
    final newTabs = List<Note>.from(state.openTabs)..removeAt(index);

    int newActiveIndex = state.activeTabIndex;
    if (index < state.activeTabIndex || (index == state.activeTabIndex && index == newTabs.length)) {
      newActiveIndex--;
    }

    state = state.copyWith(
      openTabs: newTabs,
      activeTabIndex: newActiveIndex >= 0 ? newActiveIndex : 0,
    );
  }

  void switchTab(int index) {
    state = state.copyWith(activeTabIndex: index);
  }
}

final tabViewModelProvider = NotifierProvider<TabViewModel, TabViewState>(TabViewModel.new);