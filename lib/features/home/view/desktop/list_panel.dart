import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import 'package:window_manager/window_manager.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../../shared/app_bars/top_select_mode_appbar.dart';
import '../../../../shared/menus/filter_menu_button.dart';
import '../../../../shared/menus/sort_menu_button.dart';
import '../../../../shared/menus/view_menu_button.dart';
import '../../../drawer/desktop_drawer_button.dart';
import '../../../folders/providers/folder_providers.dart';
import '../../../folders/view/folder_button.dart';
import '../../../keybinding/shortcut_config.dart';
import '../../../keybinding/smart_action_widget.dart';
import '../../core/db_sorting_filtering.dart';
import '../../core/providers.dart';
import '../../viewmodel/viewmodel.dart';
import 'content_panel/core/navigator.dart';
import '../../../../shared/app_bars/app_search_bar.dart';
import '../../../../shared/note_card/dynamic_notes_layout.dart';

class DesktopListPanel extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? activeNoteId;
  final bool isKeyboardDriven;
  final VoidCallback onAddNote;
  final Function(NoteWithFolder) onNoteTap;
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
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final currentSort = ref.watch(homeNoteSortPreferenceProvider);
    final currentView = ref.watch(homeNoteViewTypeProvider);
    final platformFilter = ref.watch(homePlatformFilterProvider);

    final rightPanelSelection = ref.watch(rightPanelSelectionProvider);
    final isRightPanelSelecting = rightPanelSelection.isSelecting;

    final isMoveToFolderActive = ref.watch(
      desktopRightPanelViewProvider.select(
        (stack) => stack.isNotEmpty && stack.last == RightPanelPageOptions.moveToFolder,
      ),
    );

    final shouldBlurListPanel = isRightPanelSelecting || isMoveToFolderActive;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: shouldBlurListPanel,
          child: ExcludeFocus(
            excluding: shouldBlurListPanel,
            child: Scaffold(
              // for closing the drawer on right panel click
              key: scaffoldKey,
              onDrawerChanged: onDrawerChanged,

              // removes the floating action button in selection mode
              floatingActionButton: homeState.isSelectMode == false
                  ? FocusTraversalOrder(
                      order: const NumericFocusOrder(3),
                      child: Focus(
                        canRequestFocus: true,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey == LogicalKeyboardKey.space)) {
                            onAddNote();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.maybeOf(context)?.hasFocus ?? false;

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
                    )
                  : null,

              // Top App Bar for the left panel
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: homeState.isSelectMode
                    ? const DragToMoveArea(child: TopSelectModeAppBar())
                    : AppBar(
                        flexibleSpace: DragToMoveArea(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        leading: const DrawerMenuButton(),
                        elevation: 0,
                        scrolledUnderElevation: PlatformHelper.isWideLayout(context) ? 0.0 : null,
                        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
                      ),
              ),

              // Body holding the search bar and the actual note list
              body: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 16),
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
                              onFocusChange: (hasFocus) {
                                if (hasFocus) {
                                  ref.read(activeShortcutScopeProvider.notifier).setScope(ShortcutScope.listPanel);
                                }
                              },
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                    node.nextFocus();
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SmartActionWidget(
                                  action: AppActions.search,
                                  scope: ShortcutScope.listPanel,
                                  baseTooltip: 'Search',
                                  badgeTop: 4,
                                  badgeRight: 8,
                                  child: AppSearchBar(
                                    controller: searchController,
                                    focusNode: searchFocusNode,
                                    hintText: 'Search...',
                                    fillColor: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    isKeyboardDriven: isKeyboardDriven,
                                    onKeyboardModeChanged: onKeyboardModeChanged,
                                    onTap: () {
                                      if (!homeState.isSearchMode) viewModel.enterSearchMode();
                                    },
                                    onClear: () {
                                      searchController.clear();
                                      ref.read(searchQueryProvider.notifier).clear();
                                      viewModel.exitSearchMode();
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
                                      if (value.isEmpty) {
                                        ref.read(searchQueryProvider.notifier).clear();
                                        viewModel.exitSearchMode();
                                      } else {
                                        ref.read(searchQueryProvider.notifier).updateQuery(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Folder Selector & Filter Row
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FolderButton(
                                selectedFolder: ref.watch(activeFolderProvider),
                                showContextMenus: true,
                                isShowTotalNoteCount: true,
                                onFolderSelected: (folder) {
                                  if (folder == null) {
                                    ref.read(activeFolderProvider.notifier).clear();
                                  } else {
                                    ref.read(activeFolderProvider.notifier).setFolder(folder);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          SortMenuButton(
                            icon: CupertinoIcons.sort_down,
                            currentSortSelection: currentSort,
                            onSelected: (NoteSortPreference sort) {
                              ref.read(homeNoteSortPreferenceProvider.notifier).updateSort(sort);
                            },
                          ),

                          if (ref.watch(showDeviceFilterProvider))
                            FilterMenuButton(
                              currentFilterSelection: platformFilter,
                              onSelected: (FilterPlatformOptions filter) {
                                ref.read(homePlatformFilterProvider.notifier).setFilter(filter);
                              },
                            ),

                          ViewMenuButton(
                            icon: Icons.grid_view,
                            currentView: currentView,
                            onViewSelected: (NoteViewType selectedView) {
                              ref.read(homeNoteViewTypeProvider.notifier).updateView(selectedView);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Notes Layout
                    const SizedBox(height: 4),
                    if (ref.watch(hasExcludedLockedNotesFromSearchProvider))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Locked note contents excluded from search',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
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
            ),
          ),
        ),
        if (shouldBlurListPanel)
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (isRightPanelSelecting) {
                    final callback = rightPanelSelection.onClearSelection;
                    ref.read(rightPanelSelectionProvider.notifier).exitSelection();
                    try {
                      callback?.call();
                    } catch (_) {}
                  } else if (isMoveToFolderActive) {
                    ref.read(drawerNavigationProvider).pop(context);
                  }
                },
                child: Tooltip(
                  message: isMoveToFolderActive
                      ? 'Click to close folder selector'
                      : 'Click to exit selection mode',
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: colorScheme.surface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
