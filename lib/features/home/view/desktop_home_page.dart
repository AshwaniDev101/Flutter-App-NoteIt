import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:noteit/features/home/view/dynamic_notes_layout.dart';
import 'package:noteit/features/home/view/widgets/home_app_bars.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../shared/widgets/smart_action_widget.dart';
import '../../../shared/widgets/spinning_sync_icon.dart';
import '../../../shared/widgets/websocket_connection_indicator.dart';
import '../../drawer/homepage_drawer.dart';
import '../../keybinding/shortcut_config.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  double _leftPanelWidth = 340.0;
  Note? _activeNote; // Tracks the currently selected note displayed in the right panel.
  // Drawer state & Debouncer for Drawer
  bool _isDrawerHovered = false;
  bool _isDrawerPinned = false;
  Timer? _hoverTimer;

  bool get _isDrawerOpen => _isDrawerHovered || _isDrawerPinned;

  void _handleMenuHover(bool isHovering) {
    _hoverTimer?.cancel(); // Cancel any pending close actions
    if (isHovering) {
      setState(() => _isDrawerHovered = true);
    } else {
      // A 150ms grace period prevents flickering if the mouse slips between widgets
      _hoverTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isDrawerHovered = false);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _searchController.dispose();

    _searchFocusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final isModifierPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    // Safely update the Notifier you just built
    ref.read(modifierHeldProvider.notifier).updateState(isModifierPressed);

    return false; // Return false so normal typing isn't blocked
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    // final viewType = ref.watch(noteViewTypeProvider);

    final shortcutsAsync = ref.watch(keybindingsProvider);

    return shortcutsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading shortcuts: $err'))),
      data: (shortcuts) {
        // Map database configs to actual app functions
        final Map<ShortcutActivator, VoidCallback> activeBindings = {};

        if (shortcuts.containsKey('search')) {
          activeBindings[shortcuts['search']!.activator] = () {
            if (!homeState.isSearchMode) viewModel.enterSearchMode();
            _searchFocusNode.requestFocus();
          };
        }
        if (shortcuts.containsKey('new_note')) {
          activeBindings[shortcuts['new_note']!.activator] = _addNote;
        }
        if (shortcuts.containsKey('toggle_menu')) {
          activeBindings[shortcuts['toggle_menu']!.activator] = () {
            setState(() => _isDrawerPinned = !_isDrawerPinned);
          };
        }



        return CallbackShortcuts(
          bindings: {
            // Windows & Linux: Ctrl + N
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): _addNote,
            // macOS: Command + N
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _addNote,
          },
          child: FocusScope(
            // As soon as this screen loads, put the invisible keyboard focus right here so I can hear shortcut keys.
            autofocus: true,
            child: PopScope(
              canPop: !homeState.isSelectMode,
              onPopInvokedWithResult: (bool didPop, Object? result) {
                if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
              },
              child: Scaffold(
                // appBar: _buildAppBar(homeState, viewModel),
                body: Stack(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: _leftPanelWidth, child: _buildLeftPanel(homeState, viewModel)),
                        const VerticalDivider(width: 1, thickness: 1), // Only 1px wide visually
                        Expanded(child: _buildRightPanel()),
                      ],
                    ),

                    Positioned(
                      left: _leftPanelWidth - 6,
                      // Centers a 13px box right over the 1px line
                      width: 13,
                      top: 0,
                      bottom: 0,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          // MUST be opaque so it completely blocks the panels underneath from stealing the mouse click
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            setState(() {
                              _leftPanelWidth += details.delta.dx;

                              // Prevent the panel from getting too small or too large
                              if (_leftPanelWidth < 250) _leftPanelWidth = 250;
                              if (_leftPanelWidth > 600) _leftPanelWidth = 600;
                            });
                          },
                          child: Container(
                            // Completely empty and transparent!
                            // No width (it inherits 13 from Positioned) and no VerticalDivider.
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),

                    // Top Layer: The Instant Windows-Style Hover Drawer
                    if (_isDrawerOpen)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: MouseRegion(
                          onEnter: (_) => _handleMenuHover(true),
                          onExit: (_) => _handleMenuHover(false),
                          child: Material(
                            elevation: 16, // Gives a beautiful desktop shadow over the content
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: SizedBox(
                              width: 250, // Your drawer width
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header area matches AppBar height precisely
                                  SizedBox(
                                    height: kToolbarHeight,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: //The Instant Windows-Style Hover Drawer
                                      SizedBox(
                                        height: kToolbarHeight,
                                        width: 56.0, // Matches default AppBar leading width
                                        child: Center(
                                          // Centers perfectly like the AppBar does
                                          child: IconButton(
                                            icon: Icon(
                                              _isDrawerPinned ? Icons.menu_open : Icons.menu,
                                              color: colorScheme.primary,
                                            ),
                                            onPressed: () => setState(() => _isDrawerPinned = !_isDrawerPinned),
                                          ),
                                        ),
                                      ),
                                      // child: Padding(
                                      //   padding: const EdgeInsets.only(left: 8.0),
                                      //   child: IconButton(
                                      //     icon: Icon(
                                      //       _isDrawerPinned ? Icons.menu_open : Icons.menu,
                                      //       color: colorScheme.primary,
                                      //     ),
                                      //     onPressed: () => setState(() => _isDrawerPinned = !_isDrawerPinned),
                                      //   ),
                                      // ),
                                    ),
                                  ),
                                  // Your actual drawer content
                                  Expanded(
                                    child: HomepageDrawer(
                                      onDestinationSelected: () {
                                        // If you want unpinned overlay to close when an item is selected:
                                        if (!_isDrawerPinned) {
                                          setState(() => _isDrawerHovered = false);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

      },

    );

  }

  Widget _buildLeftPanel(HomePageState homeState, HomeViewModel viewModel) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: SmartActionWidget(
        action: AppActions.newNote, // Pulls the exact config from the DB
        baseTooltip: 'New Note',    // The smart widget will append "(Ctrl+N)" automatically
        child: FloatingActionButton(
          onPressed: _addNote,
          // 'tooltip' are added automatically
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
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
                  // Drawer
                  leading: MouseRegion(
                    onEnter: (_) => _handleMenuHover(true),
                    onExit: (_) => _handleMenuHover(false),
                    child: IconButton(
                      icon: Icon(Icons.menu, color: colorScheme.primary),
                      onPressed: () => setState(() => _isDrawerPinned = !_isDrawerPinned),
                    ),
                  ),
                  title: const Text('Note-It', style: TextStyle(fontWeight: FontWeight.bold)),
                  elevation: 0,
                  actions: [
                    // IconButton(
                    //   tooltip: "New Note",
                    //   icon: Icon(Icons.edit_square, color: colorScheme.primary),
                    //   onPressed: () {
                    //     final emptyNote = Note(
                    //       uuid: const Uuid().v4(),
                    //       title: '',
                    //       content: '',
                    //       createdAt: DateTime.now().toUtc(),
                    //       updatedAt: DateTime.now().toUtc(),
                    //       isLocked: false,
                    //       isPinned: false,
                    //       color: 0,
                    //       isArchived: false,
                    //       position: 0,
                    //       hasAttachments: false,
                    //       contentType: 'text',
                    //       isShared: false,
                    //       cloudSyncStatus: 0,
                    //       localSyncStatus: 0,
                    //       versionCounter: 1,
                    //     );
                    //     setState(() => _activeNote = emptyNote);
                    //   },
                    // ),
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
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearSearch)
                              : const SizedBox.shrink();
                        },
                      ),
                      // suffixIcon: _searchController.text.isNotEmpty
                      //     ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearSearch)
                      //     : null,
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
              // const Spacer(),
              WebSocketConnectionIndicator(isConnected: isConnected),

              IconButton(
                tooltip: "Sync Notes",
                icon: SpinningSyncIcon(isSyncing: isSyncing, color: colorScheme.primary),
                onPressed: () {
                  ref.read(syncOrchestratorProvider).triggerSync();
                },
              ),
              // Re-add standard window controls manually
              // const VerticalDivider(indent: 12, endIndent: 12, width: 1),
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

  void _addNote() {
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
  }
}
