import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:uuid/uuid.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../../keybinding/shortcut_config.dart';
import '../../../lock/lock_manger/lock_manager.dart';
import '../../core/providers.dart';
import '../../../lock/password_prompt_helper.dart';
import '../../viewmodel/viewmodel.dart';
import 'desktop_left_panel.dart';
import 'desktop_right_panel.dart';

class DesktopHomePage extends ConsumerStatefulWidget {
  const DesktopHomePage({super.key});

  @override
  ConsumerState<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Tracks the current width of the left panel (the note list). Modified by the draggable divider.
  double _leftPanelWidth = 340.0;


  // For helping close the drawer when user click on the invisible barrier on top of the right panel
  final GlobalKey<ScaffoldState> _leftScaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  // ==== ACCESSIBILITY & UX ====
  /// Tracks if the user is currently navigating via keyboard (Tab/Arrows) vs Mouse.
  /// Used to selectively show/hide focus rings so mouse users don't see ugly boxes.
  bool _isKeyboardDriven = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();

    // Prevent the search node from eating the 'Tab' key normally
    _searchFocusNode.skipTraversal = true;

    // Handle specific keyboard actions when the search bar is focused
    _searchFocusNode.onKeyEvent = (FocusNode node, KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus(); // Drop focus down into the note list
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          node.unfocus(); // Drop focus completely to return to normal app state
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    // Listen to Flutter's engine to detect mouse vs keyboard usage
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);

    // Trigger an initial background sync as soon as the desktop app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    // Global raw keyboard listener to track modifier keys (Ctrl/Alt/Shift)
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    FocusManager.instance.removeHighlightModeListener(_handleHighlightModeChange);
    super.dispose();
  }

  // ==== EVENT HANDLERS ====

  /// Handles the hover mechanics for the slide-out drawer.
  /// Uses a 150ms debounce timer to prevent the drawer from violently flickering
  /// open and closed if the mouse accidentally slips off the edge for a split second.

  void _handleHighlightModeChange(FocusHighlightMode mode) {
    if (mounted) {
      setState(() {
        _isKeyboardDriven = mode == FocusHighlightMode.traditional;
      });
    }
  }

  /// Intercepts raw hardware key events before they hit text fields.
  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // If the user uses a navigation key, force the app into keyboard-driven mode
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (!_isKeyboardDriven && mounted) {
          setState(() => _isKeyboardDriven = true);
        }
      }
    }

    final isModifierPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    ref.read(modifierHeldProvider.notifier).updateState(isModifierPressed);

    return false; // MUST return false so we don't block normal typing!
  }

  void _handleNoteTap(Note note) async {

    final isSessionUnlocked = ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(note.uuid);
    if (note.isLocked && !isSessionUnlocked) {
      // The Shell coordinates the security check
      final success = await PasswordPromptHelper.promptAndVerify(context, ref, note);

      // If successful, update the state. No 'mounted' check needed for Riverpod.
      if (success) {
        ref.read(activeNoteProvider.notifier).setNote(note);
      }
    } else {
      // Unlocked notes open instantly
      ref.read(activeNoteProvider.notifier).setNote(note);
    }
  }

  /// Injects an empty, temporary "shell" note into the editor panel.
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
    ref.read(activeNoteProvider.notifier).setNote(emptyNote);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final activeNote = ref.watch(activeNoteProvider);

    ref.watch(syncOrchestratorProvider);
    final shortcutsAsync = ref.watch(keybindingsProvider);

    return shortcutsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading shortcuts: $err'))),
      data: (Map<String, ShortcutConfig> shortcuts) {
        final activeBindings = <ShortcutActivator, VoidCallback>{
          if (shortcuts[AppActions.search] != null)
            shortcuts[AppActions.search]!.activator: () {
              if (!homeState.isSearchMode) viewModel.enterSearchMode();
              _searchFocusNode.requestFocus();
            },
          if (shortcuts[AppActions.newNote] != null) shortcuts[AppActions.newNote]!.activator: _addNote,

        };

        return CallbackShortcuts(
          bindings: activeBindings,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: FocusScope(
              autofocus: true,
              child: PopScope(
                canPop: !homeState.isSelectMode,
                onPopInvokedWithResult: (bool didPop, Object? result) {
                  if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
                },
                child: Scaffold(
                  body: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Stack(
                      children: [
                        // The Split Layout Background
                        Row(
                          children: [
                            SizedBox(
                              width: _leftPanelWidth,
                              child: DesktopLeftPanel(

                                // Pass the key and a callback down to the left panel
                                scaffoldKey: _leftScaffoldKey,
                                onDrawerChanged: (isOpen) {
                                  setState(() => _isDrawerOpen = isOpen);
                                },

                                searchController: _searchController,
                                searchFocusNode: _searchFocusNode,
                                activeNoteId: activeNote?.uuid,
                                isKeyboardDriven: _isKeyboardDriven,
                                onAddNote: _addNote,
                                onNoteTap: _handleNoteTap,
                                onKeyboardModeChanged: (mode) => setState(() => _isKeyboardDriven = mode),
                              ),
                            ),
                            const VerticalDivider(width: 1, thickness: 1), // Only 1px wide visually
                            Expanded(child: DesktopRightPanel(activeNote: activeNote)),
                          ],
                        ),

                        // The Invisible Draggable Resizer
                        Positioned(
                          left: _leftPanelWidth - 6,
                          width: 13,
                          top: 0,
                          bottom: 0,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                setState(() {
                                  _leftPanelWidth += details.delta.dx;
                                  if (_leftPanelWidth < 250) _leftPanelWidth = 250;
                                  if (_leftPanelWidth > 600) _leftPanelWidth = 600;
                                });
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ),


                        // Invisible barrier over the Right Panel to close drawer on click
                        if (_isDrawerOpen)
                          Positioned(
                            left: _leftPanelWidth + 1, // Starts right after the divider
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              // behavior: HitTestBehavior.opaque is critical for transparent containers to catch taps!
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _leftScaffoldKey.currentState?.closeDrawer();
                              },
                              child: MouseRegion(
                                // Resets cursor so it doesn't look like you can click things on the right pane
                                cursor: SystemMouseCursors.basic,
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
