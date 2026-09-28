import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:noteit/features/home/view/dynamic_notes_layout.dart';
import 'package:noteit/features/home/view/widgets/home_app_bars.dart';
import 'package:noteit/features/home/view/widgets/notes_grid_view.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../../../shared/widgets/spinning_sync_icon.dart';
import '../../../shared/widgets/websocket_connection_indicator.dart';
import '../../drawer/homepage_drawer.dart';
import '../../note_editor/screens/view/edit_note_page.dart';
import '../core/providers.dart';
import '../core/sort.dart';
import '../core/options.dart';
import '../note_view.dart';
import '../viewmodel/home_view_model.dart';
import 'password_prompt_helper.dart';

/// The main entry point for the desktop layout of the application.
class DesktopHomePage extends ConsumerStatefulWidget {
  const DesktopHomePage({super.key});

  @override
  ConsumerState<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePage> {
  final TextEditingController _searchController = TextEditingController();

  // Add this variable to control the width
  double _leftPanelWidth = 340.0;

  // Tracks the currently selected note displayed in the right panel.
  Note? _activeNote;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    final viewType = ref.watch(noteViewTypeProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        // appBar: _buildAppBar(homeState, viewModel),
        body: Row(
          children: [
            SizedBox(width: _leftPanelWidth, child: _buildLeftPanel(homeState, viewModel)),

            // const VerticalDivider(width: 1, thickness: 1),
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  setState(() {
                    _leftPanelWidth += details.delta.dx;

                    // Prevent the panel from getting too small or too large
                    if (_leftPanelWidth < 250) _leftPanelWidth = 250;
                    if (_leftPanelWidth > 600) _leftPanelWidth = 600;
                  });
                },
                child: const SizedBox(
                  width: 8, // Makes the grab area slightly wider than the visual line
                  child: VerticalDivider(width: 1, thickness: 1),
                ),
              ),
            ),

            Expanded(child: _buildRightPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(HomePageState homeState, HomeViewModel viewModel) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const HomepageDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
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
                  title: const Text('Note-It', style: TextStyle(fontWeight: FontWeight.bold)),
                  elevation: 0,
                  actions: [
                    IconButton(
                      tooltip: "New Note",
                      icon: Icon(Icons.edit_square, color: colorScheme.primary),
                      onPressed: () {
                        final emptyNote = Note(
                          uuid: const Uuid().v4(),
                          title: '',
                          content: '',
                          createdAt: DateTime.now().toUtc(),
                          updatedAt: DateTime.now().toUtc(),
                          isLocked: false,
                          isPinned: false,
                          color: 0,
                          isArchived: false,
                          position: 0,
                          hasAttachments: false,
                          contentType: 'text',
                          isShared: false,
                          cloudSyncStatus: 0,
                          localSyncStatus: 0,
                          versionCounter: 1,
                        );
                        setState(() => _activeNote = emptyNote);
                      },
                    ),
                    // IconButton(
                    //   tooltip: "Settings",
                    //   icon: Icon(Icons.settings, color: colorScheme.primary),
                    //   onPressed: () {
                    //     ref.read(syncOrchestratorProvider).triggerSync();
                    //   },
                    // ),
                    // WebSocketConnectionIndicator(isConnected: isConnected),
                    const SizedBox(width: 8),
                  ],
                ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearSearch)
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onTap: () {
                      if (!homeState.isSearchMode) viewModel.enterSearchMode();
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
                      if (value.isEmpty) {
                        _clearSearch();
                      } else {
                        ref.read(searchQueryProvider.notifier).updateQuery(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                const ViewSwitcherButton(),
                _buildFilterMenu(currentSortOption, currentPlatformFilter, colorScheme),
              ],
            ),
          ),
          Expanded(
            child: DynamicNotesLayout(
              isSelectMode: homeState.isSelectMode,
              noteIds: homeState.selectedNoteIds,
              activeNoteId: _activeNote?.uuid,
              onToggleSelection: viewModel.toggleSelection,
              onEnableSelectMode: viewModel.enableSelectMode,
              onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
              onNoteTap: _handleNoteTap,
            ),

            // child: NotesGridView(
            //   isSelectMode: homeState.isSelectMode,
            //   noteIds: homeState.selectedNoteIds,
            //   activeNoteId: _activeNote?.uuid,
            //   onToggleSelection: viewModel.toggleSelection,
            //   onEnableSelectMode: viewModel.enableSelectMode,
            //   onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
            //   onNoteTap: _handleNoteTap,
            // ),
          ),
        ],
      ),
    );
  }

  // ==== Right panel ====
  Widget _buildRightPanel() {
    // ValueKey must use the UUID so the editor rebuilds when switching notes
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(
            // title: const Text('Note-It', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            actions: [
              const Spacer(),

              WebSocketConnectionIndicator(isConnected: isConnected),

              IconButton(
                tooltip: "Sync Notes",
                icon: SpinningSyncIcon(isSyncing: isSyncing, color: colorScheme.primary),
                onPressed: () {
                  ref.read(syncOrchestratorProvider).triggerSync();
                },
              ),
              // Re-add standard window controls manually
              const VerticalDivider(indent: 12, endIndent: 12, width: 1),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.minimize, size: 16), onPressed: () => windowManager.minimize()),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 16),
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => windowManager.close()),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: _activeNote == null
          ? homepagePlaceholder()
          : EditNotePage(key: ValueKey(_activeNote!.uuid), existingNote: _activeNote),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(homeViewModelProvider.notifier).exitSearchMode();
  }

  Widget _buildFilterMenu(
    NoteSortOption currentSortOption,
    PlatformOptions? currentPlatformFilter,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Sort & Filter',
      onSelected: (String value) {
        switch (value) {
          case 'sortCreated':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt);
            break;
          case 'sortName':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name);
            break;
          case 'sortUpdated':
            ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt);
            break;
          case 'filterPhone':
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.android);
            break;
          case 'filterWindows':
            ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.windows);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildSortItem('sortCreated', 'Created', currentSortOption == NoteSortOption.createdAt, colorScheme),
        _buildSortItem('sortName', 'Name', currentSortOption == NoteSortOption.name, colorScheme),
        _buildSortItem('sortUpdated', 'Last Updated', currentSortOption == NoteSortOption.updatedAt, colorScheme),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('FILTER PLATFORM', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        _buildFilterItem(
          'filterPhone',
          Icons.phone_android_outlined,
          'Phone',
          currentPlatformFilter == PlatformOptions.android,
        ),
        _buildFilterItem(
          'filterWindows',
          Icons.desktop_windows_outlined,
          'Windows',
          currentPlatformFilter == PlatformOptions.windows,
        ),
      ],
    );
  }

  void _handleNoteTap(Note note) async {
    if (note.isLocked) {
      final success = await PasswordPromptHelper.promptAndVerify(context, ref, note);
      if (success && mounted) {
        setState(() => _activeNote = note);
      }
    } else {
      setState(() => _activeNote = note);
    }
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, bool isSelected, ColorScheme colorScheme) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? colorScheme.primary : Colors.grey,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(String value, IconData icon, String label, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          IgnorePointer(
            child: Checkbox(value: isSelected, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }

  Widget homepagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No note selected', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Select a note from the list or click + to start editing.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
