import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/shared/app_bars/bottom_select_mode_appbar.dart';

import 'package:window_manager/window_manager.dart';

import '../../../../shared/app_bars/desktop_window_controls.dart';

import '../../../../core/router/router.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../../../shared/app_bars/mobile_bottom_control_bar.dart';
import '../../../../shared/app_bars/top_select_mode_appbar.dart';
import '../../../../shared/note_card/dynamic_notes_layout.dart';
import '../../../drawer/mobile_app_drawer.dart';
import '../../core/note_tap_handler.dart';
import '../../core/providers.dart';
import '../../viewmodel/viewmodel.dart';

// ==========================================
// MOBILE HOME PAGE
// ==========================================

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    if (_wasKeyboardOpen && !isKeyboardOpen) {
      final homeState = ref.read(homeViewModelProvider);
      if (homeState.isSearchMode && mounted) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).clear();
        ref.read(homeViewModelProvider.notifier).exitSearchMode();
      }
    }
    _wasKeyboardOpen = isKeyboardOpen;
  }

  void _handleNoteTap(NoteWithFolder noteWithFolder) {
    NoteTapHandler.openNote(context, ref, noteWithFolder);
  }

  // ------------------------------------------
  // APP BAR BUILDERS
  // ------------------------------------------

  PreferredSizeWidget _buildAppBar(HomePageState state) {
    if (state.isSelectMode) {
      return PlatformHelper.isNativeDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: const DragToMoveArea(child: TopSelectModeAppBar()),
            )
          : const TopSelectModeAppBar();
    }

    return AppBar(
      flexibleSpace: PlatformHelper.isNativeDesktop
          ? DragToMoveArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            )
          : null,
      elevation: 0,
      scrolledUnderElevation: PlatformHelper.isNativeDesktop ? 0.0 : null,
      actions: const [
        IconTray(),
        DesktopWindowControls(),
      ],
    );
  }


  Widget _buildBottomAppBar(HomePageState homeState, HomeViewModel homeViewModel) {
    if (homeState.isSelectMode) {
      return BottomSelectModeAppBar();
    }

    return MobileBottomControlBar(
      homeState: homeState,
      viewModel: homeViewModel,
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
    );
  }





  // ------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------

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
        // Remove the floating action button in select mode
        floatingActionButton: homeState.isSelectMode==false?_MobileFAB(
          onPressed: () => context.push(AppRoutes.edit),
        ):null,
        bottomNavigationBar: _buildBottomAppBar(homeState, viewModel),
        // bottomNavigationBar: _MobileBottomControlBar(
        //   homeState: homeState,
        //   viewModel: viewModel,
        //   searchController: _searchController,
        //   searchFocusNode: _searchFocusNode,
        // ),
        body: DynamicNotesLayout(
          isSelectMode: homeState.isSelectMode,
          noteIds: homeState.selectedNoteIds,
          activeNoteId: null,
          onToggleSelection: viewModel.toggleSelection,
          onEnableSelectMode: viewModel.enableSelectMode,
          onNoteTap: _handleNoteTap,
        ),
      ),
    );
  }
}

// ==========================================
// ISOLATED SUB-WIDGETS (HIGH PERFORMANCE)
// ==========================================

class _MobileFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _MobileFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 3,
      child: const Icon(Icons.edit),
    );
  }
}
