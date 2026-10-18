import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';

import 'package:window_manager/window_manager.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../../shared/sort_menu_button.dart';
import '../../../../shared/view_menu_button.dart';
import '../../../drawer/desktop_drawer_button.dart';
import '../../../folders/core/providers.dart';
import '../../../folders/view/folder_selector.dart';
import '../../../keybinding/smart_action_widget.dart';
import '../../core/db_sorting_filtering.dart';
import '../../core/providers.dart';
import '../../viewmodel/viewmodel.dart';
import '../shared/select_mode_app_bars.dart';
import '../../../../shared/note_card/dynamic_notes_layout.dart';
import '../shared/home_search_bar.dart';

class DesktopListPanel extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? activeNoteId;
  final bool isKeyboardDriven;
  final VoidCallback onAddNote;
  final Function(Note) onNoteTap;
  final Function(bool) onKeyboardModeChanged;

  // for closing the drawer on right panel click
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueChanged<bool> onDrawerChanged;

  const DesktopListPanel({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.activeNoteId,
    required this.isKeyboardDriven,
    required this.onAddNote,
    required this.onNoteTap,
    required this.onKeyboardModeChanged,

    // for closing the drawer on right panel click
    required this.scaffoldKey,
    required this.onDrawerChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final currentSort = ref.watch(noteSortPreferenceProvider);
    final currentView = ref.watch(noteViewTypeProvider);

    // final versionString = "v${AppEnv.version}-${AppEnv.buildNumber}";

    return Scaffold(
      // for closing the drawer on right panel click
      key: scaffoldKey,
      onDrawerChanged: onDrawerChanged,

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
                duration: const Duration(milliseconds: 50),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isFocused && isKeyboardDriven) ? colorScheme.primary : Colors.transparent,
                    width: (isFocused && isKeyboardDriven) ? 0 : 2,
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
        child: homeState.isSelectMode
            ? DragToMoveArea(child: SelectModeAppBar(noteIds: homeState.selectedNoteIds))
            : AppBar(
                flexibleSpace: DragToMoveArea(child: Container(color: Colors.transparent)),
                backgroundColor: Colors.transparent,
                // Ensures clicks pass through to the drag area

                // title:
                leading: const DrawerMenuButton(),
                // title: Text(
                //   'Note-It',
                //   style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                // ),
                elevation: 0,
                scrolledUnderElevation: PlatformHelper.isDesktopScreen ? 0.0 : null,
                // actions: [
                //   SelectableText(
                //     versionString,
                //     style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                //   ),
                //   const SizedBox(width: 16),
                // ],
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
              ),
      ),

      // Body holding the search bar and the actual note list
      body: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 16),// 8px from left+right side of the grid,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Row(
              children: [
                Expanded(
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Focus(
                      canRequestFocus: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            node.nextFocus(); // Still lets you press down arrow to go to notes
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        // This is to compensate for the card 4px padding
                        child: HomeSearchBar(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          hintText: 'Search...',
                          borderRadius: BorderRadius.circular(8),
                          isKeyboardDriven: isKeyboardDriven,
                          onKeyboardModeChanged: onKeyboardModeChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),


            // Folder Selector & Filter Row
            SizedBox(height: 8,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4), // This is to compensate for the card 4px padding
              child: Row(
                children: [
                  FolderButton(
                    selectedFolder: ref.watch(activeFolderProvider),
                    emptyLabel: 'All Notes',
                    showContextMenus: true,
                    onFolderSelected: (folder) {
                      if (folder == null) {
                        ref.read(activeFolderProvider.notifier).clear();
                      } else {
                        ref.read(activeFolderProvider.notifier).setFolder(folder);
                      }
                    },
                  ),
                  Spacer(),

                  // IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.sort_down)),
                  // IconButton(onPressed: (){}, icon: Icon(Icons.grid_view)),
                  SortMenuButton(

                    icon: Icon(CupertinoIcons.sort_down,color: Theme.of(context).colorScheme.primary),
                    currentSelection: _getCurrentSortAction(currentSort),
                    onSelected: (HomeMenuAction action) {
                      // Route the UI action to the correct Riverpod provider
                      switch (action) {
                        case HomeMenuAction.sortCreated:
                          ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
                          break;
                        case HomeMenuAction.sortName:
                          ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
                          break;
                        case HomeMenuAction.sortUpdated:
                          ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
                          break;
                        case HomeMenuAction.filterPhone:
                          ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
                          break;
                        case HomeMenuAction.filterWindows:
                          ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
                          break;
                      }
                    },
                  ),

                  ViewMenuButton(
                    icon: Icon(Icons.grid_view,color: Theme.of(context).colorScheme.primary),
                    currentView: currentView,
                    onViewSelected: (NoteViewType selectedView) {
                      ref.read(noteViewTypeProvider.notifier).updateView(selectedView);
                    },
                  ),

                  // IconButton(onPressed: (){}, icon: HugeIcon(
                  //   icon: HugeIcons.strokeRoundedHome01,
                  // ))
                ],
              ),
            ),

            // Notes Layout
            SizedBox(height: 4,), // Notes have 4x already on top
            Expanded(
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: DynamicNotesLayout(
                  isSelectMode: homeState.isSelectMode,
                  noteIds: homeState.selectedNoteIds,
                  activeNoteId: activeNoteId,
                  onToggleSelection: ref.read(homeViewModelProvider.notifier).toggleSelection,
                  onEnableSelectMode: ref.read(homeViewModelProvider.notifier).enableSelectMode,
                  onNoteTap: onNoteTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to map your internal NoteSortPreference back to the UI Enum (HomeMenuAction)
  HomeMenuAction _getCurrentSortAction(NoteSortPreference currentSort) {
    switch (currentSort) {
      case NoteSortPreference.createdAt:
        return HomeMenuAction.sortCreated;
      case NoteSortPreference.name:
        return HomeMenuAction.sortName;
      case NoteSortPreference.updatedAt:
        return HomeMenuAction.sortUpdated;
    }
  }
}
