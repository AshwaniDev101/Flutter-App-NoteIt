import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/app_env.dart';
import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../drawer/desktop_drawer_button.dart';
import '../../../keybinding/smart_action_widget.dart';
import '../../viewmodel/viewmodel.dart';
import '../shared/select_mode_app_bars.dart';
import '../shared/tag_sort_view_menu.dart';
import '../../../../shared/widgets/note_card/dynamic_notes_layout.dart';
import '../shared/home_search_bar.dart';

class DesktopLeftPanel extends ConsumerWidget {
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

  const DesktopLeftPanel({
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

    final versionString = "v${AppEnv.version}-${AppEnv.buildNumber}";

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
          child: homeState.isSelectMode
              ? SelectModeAppBar(
                  noteIds: homeState.selectedNoteIds,
                )
              : AppBar(
                  leading: DrawerMenuButton(),
                  title: Text(
                    'Note-It',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  elevation: 0,
                  scrolledUnderElevation: PlatformHelper.isDesktopScreen ? 0.0 : null,
                  actions: [
                    SelectableText(
                      versionString,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 16),
                  ],
                  iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
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
                onToggleSelection: ref.read(homeViewModelProvider.notifier).toggleSelection,
                onEnableSelectMode: ref.read(homeViewModelProvider.notifier).enableSelectMode,
                onNoteTap: onNoteTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
