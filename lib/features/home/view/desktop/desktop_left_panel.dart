import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../keybinding/smart_action_widget.dart';
import '../../viewmodel/viewmodel.dart';
import '../shared/sort_filter_option_menu.dart';
import '../../core/providers.dart';
import '../shared/tag_sort_view_menu.dart';
import '../shared/view_switch_option_menu.dart';
import '../shared/dynamic_notes_layout.dart';
import '../shared/select_mode_app_bars.dart';

class DesktopLeftPanel extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? activeNoteId;
  final bool isKeyboardDriven;
  final VoidCallback onMenuToggle;
  final Function(bool) onMenuHover;
  final VoidCallback onAddNote;
  final Function(Note) onNoteTap;
  final Function(bool) onKeyboardModeChanged;

  const DesktopLeftPanel({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.activeNoteId,
    required this.isKeyboardDriven,
    required this.onMenuToggle,
    required this.onMenuHover,
    required this.onAddNote,
    required this.onNoteTap,
    required this.onKeyboardModeChanged,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // The Floating Action Button (New Note)
      floatingActionButton: FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: Focus(
          canRequestFocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
              onAddNote();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50), // Snappy mechanical feel
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Draw focus ring only if focused AND driven by keyboard
                  border: Border.all(
                    color: (isFocused && isKeyboardDriven) ? colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SmartActionWidget(
                  action: AppActions.newNote,
                  baseTooltip: 'New Note',
                  child: ExcludeFocus(
                    child: FloatingActionButton(onPressed: onAddNote, elevation: 3, child: const Icon(Icons.edit)),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // Top App Bar for the left panel
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          // Allows user to drag the window around by clicking the AppBar
          child: homeState.isSelectMode
              ? SelectModeAppBar(
                  noteIds: homeState.selectedNoteIds,
                  onClearSelection: viewModel.clearSelection,
                  onSelectAll: () {
                    final allNoteUuids = (ref.read(filteredNotesProvider).value ?? []).map((n) => n.uuid).toList();
                    viewModel.toggleSelectAll(allNoteUuids);
                  },
                )
              : AppBar(
                  leading: MouseRegion(
                    onEnter: (_) => onMenuHover(true),
                    onExit: (_) => onMenuHover(false),
                    child: IconButton(icon: const Icon(Icons.menu), onPressed: onMenuToggle),
                  ),
                  title: const Text('Note-It', style: TextStyle(fontWeight: FontWeight.bold)),
                  elevation: 0,
                  actions: const [],
                ),
        ),
      ),

      // Body holding the search bar and the actual note list
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Focus(
                      canRequestFocus: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter) {
                            searchFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            node.nextFocus();
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.escape) {
                            node.requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (context) {
                          final isFocused = Focus.of(context).hasFocus;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (isFocused && isKeyboardDriven) ? colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: searchController,
                              focusNode: searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                // fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: searchController,
                                  builder: (context, value, child) {
                                    return value.text.isNotEmpty
                                        ? ExcludeFocus(
                                            child: IconButton(
                                              icon: const Icon(Icons.clear, size: 20),
                                              onPressed: () => _clearSearch(ref),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
                                filled: true,
                                // Uses default M3 variant fill color
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              onTap: () {
                                // Clicking tells the app a mouse was used, dropping keyboard styling! (for keyboard navigation)
                                onKeyboardModeChanged(false);
                                if (!homeState.isSearchMode) viewModel.enterSearchMode();
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
                                if (value.isEmpty) {
                                  _clearSearch(ref);
                                } else {
                                  ref.read(searchQueryProvider.notifier).updateQuery(value);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // const SizedBox(width: 4),
                // const ViewSwitcherOptionMenu(),
                // const SizedBox(width: 4),
                // const SortFilterOptionMenu(),
                const SizedBox(width: 4),
                const FolderSortViewButton(),
              ],
            ),
          ),

          // The Note List Layout
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: DynamicNotesLayout(
                isSelectMode: homeState.isSelectMode,
                noteIds: homeState.selectedNoteIds,
                activeNoteId: activeNoteId,
                onToggleSelection: viewModel.toggleSelection,
                onEnableSelectMode: viewModel.enableSelectMode,
                onNoteTap: onNoteTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch(WidgetRef ref) {
    searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(homeViewModelProvider.notifier).exitSearchMode();
  }
}
