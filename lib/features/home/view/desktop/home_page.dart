import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/core/note_tap_handler.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:uuid/uuid.dart';

import '../../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../../folders/core/providers.dart';
import '../../../keybinding/shortcut_config.dart';
import 'package:noteit/features/home/core/providers.dart';
import '../../viewmodel/viewmodel.dart';
import 'list_panel.dart';
import 'package:noteit/features/home/view/desktop/content_panel/content_panel.dart';

class DesktopHomePanel extends ConsumerStatefulWidget {
  const DesktopHomePanel({super.key});

  @override
  ConsumerState<DesktopHomePanel> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // For helping close the drawer when user click on the invisible barrier on top of the right panel
  final GlobalKey<ScaffoldState> _leftScaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  // ==== ACCESSIBILITY & UX ====
  bool _isKeyboardDriven = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.skipTraversal = true;
    _searchFocusNode.onKeyEvent = (FocusNode node, KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          node.unfocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });
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

  void _handleHighlightModeChange(FocusHighlightMode mode) {
    if (mounted) {
      setState(() => _isKeyboardDriven = mode == FocusHighlightMode.traditional);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
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
    return false;
  }

  void _handleNoteTap(NoteWithFolder noteWithFolder) {
    NoteTapHandler.openNote(context, ref, noteWithFolder);
  }

  void _addNote() {
    final activeFolder = ref.read(activeFolderProvider);
    final emptyNote = Note(
      uuid: const Uuid().v4(),
      title: '',
      content: '',
      color: 0xFFFFFFFF,
      schemaVersion: 1,
      contentVersion: 1,
      pinnedAt: null,
      archivedAt: null,
      lockedAt: null,
      localAttachmentPath: null,
      cloudAttachmentUrl: null,
      folderId: activeFolder?.uuid,
      tags: null,
      reminderAt: null,
      ownerUid: null,
      creationPlatform: null,
      creationDevice: null,
      lastEditedPlatform: null,
      lastEditedDevice: null,
      deletedPlatform: null,
      deletedDevice: null,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      deletedAt: null,
      updateCounter: 1,
      cloudSyncStatus: 0,
      localSyncStatus: 0,
    );

    // Wrap the raw Note inside your new class
    final emptyNoteWithFolder = NoteWithFolder(
      note: emptyNote,
      folder: activeFolder,
    );

    ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.allNotes);

    // Pass the wrapper to the provider
    ref.read(activeNoteProvider.notifier).setNote(emptyNoteWithFolder);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final NoteWithFolder? activeNoteWithFolder = ref.watch(activeNoteProvider);
    final listPanelWidth = ref.watch(listPanelWidthProvider);

    ref.watch(syncOrchestratorProvider);
    final shortcutsAsync = ref.watch(keybindingsProvider);

    return shortcutsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
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
                        Row(
                          children: [

                            // Middle Panel
                            SizedBox(
                              width: listPanelWidth,
                              child: DesktopListPanel(
                                scaffoldKey: _leftScaffoldKey,
                                onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),
                                searchController: _searchController,
                                searchFocusNode: _searchFocusNode,
                                activeNoteId: activeNoteWithFolder?.note.uuid,
                                isKeyboardDriven: _isKeyboardDriven,
                                onAddNote: _addNote,
                                onNoteTap: _handleNoteTap,
                                onKeyboardModeChanged: (mode) => setState(() => _isKeyboardDriven = mode),
                              ),
                            ),
                            VerticalDivider(width: 1, thickness: 1,color: Colors.transparent),

                            // Right Panel
                            Expanded(child: DesktopContentPanel(activeNoteWithFolder: activeNoteWithFolder)),
                          ],
                        ),


                        // Middle Panel Divider
                        Positioned(
                          left: listPanelWidth - 6, // Removed _currentLeftWidth
                          width: 13,
                          top: 0,
                          bottom: 0,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                double newWidth = listPanelWidth + details.delta.dx;
                                if (newWidth < 250) newWidth = 250;
                                if (newWidth < 250) newWidth = 250;
                                if (newWidth > 600) newWidth = 600;
                                ref.read(listPanelWidthProvider.notifier).updateWidth(newWidth);
                              },
                              onPanEnd: (_) {
                                ref.read(listPanelWidthProvider.notifier).saveWidth();
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ),
                        // Middle Panel Divider
                        // Positioned(
                        //   left: _currentLeftWidth + _listPanelWidth - 6,
                        //   width: 13,
                        //   top: 0,
                        //   bottom: 0,
                        //   child: MouseRegion(
                        //     cursor: SystemMouseCursors.resizeColumn,
                        //     child: GestureDetector(
                        //       behavior: HitTestBehavior.opaque,
                        //       onPanUpdate: (details) {
                        //         setState(() {
                        //           _listPanelWidth += details.delta.dx;
                        //           if (_listPanelWidth < 250) _listPanelWidth = 250;
                        //           if (_listPanelWidth > 600) _listPanelWidth = 600;
                        //         });
                        //       },
                        //       child: Container(color: Colors.transparent),
                        //     ),
                        //   ),
                        // ),

                        // Invisible barrier over Right Panel
                        if (_isDrawerOpen)
                          Positioned(
                            left: listPanelWidth + 1,
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _leftScaffoldKey.currentState?.closeDrawer(),
                              child: MouseRegion(
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