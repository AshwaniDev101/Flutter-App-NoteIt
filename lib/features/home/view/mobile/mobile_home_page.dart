import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/home/view/shared/select_mode_app_bars.dart';
import 'package:noteit/features/home/view/shared/sort_view_menu.dart';
import 'package:noteit/features/home/viewmodel/viewmodel.dart';
import 'package:noteit/shared/note_card/dynamic_notes_layout.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../../../drawer/mobile_app_drawer.dart';
import '../../core/note_tap_handler.dart';
import '../shared/home_search_bar.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    // _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNoteTap(Note note) {
    NoteTapHandler.openNote(context, ref, note);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: _buildAppBar(homeState),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.edit),
          elevation: 3,
          child: const Icon(Icons.edit),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: HomeSearchBar(
                      controller: _searchController,
                      hintText: 'Search notes...',
                    ),
                  ),
                  const SizedBox(width: 8),

                  const SortViewButton(),

                  // SortFilterOptionMenu(),
                  // _buildFilterMenu(
                  //   currentSortOption,
                  //   currentPlatformFilter,
                  //   colorScheme,
                  // ),
                ],
              ),
            ),
            Expanded(
              child: DynamicNotesLayout(
                isSelectMode: homeState.isSelectMode,
                noteIds: homeState.selectedNoteIds,
                activeNoteId: null,
                onToggleSelection: viewModel.toggleSelection,
                onEnableSelectMode: viewModel.enableSelectMode,
                onNoteTap: _handleNoteTap,
              ),
              // child: NotesGridView(
              //   isSelectMode: homeState.isSelectMode,
              //   noteIds: homeState.selectedNoteIds,
              //   // NotesGridView expects a Set<String>
              //   activeNoteId: null,
              //   onToggleSelection: viewModel.toggleSelection,
              //   onEnableSelectMode: viewModel.enableSelectMode,
              //   onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
              //   onNoteTap: _handleNoteTap,
              // ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomePageState state) {
    if (state.isSelectMode) {
      return SelectModeAppBar(
        noteIds: state.selectedNoteIds,
      );
    }
    return AppBar(
      // leading: DrawerMenuButton(),
      // title: const Text('Notes'),
      elevation: 0,
      // centerTitle: true,
      actions: const [
        IconTray(),
        SizedBox(width: 8),
      ],
    );
  }
}
