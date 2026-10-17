import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import '../../../../shared/find_replace.dart';
import '../../../../shared/app_scaffold.dart';
import '../../../../shared/note_card/core/note_action_controller.dart';
import '../../../../shared/highlighting_text_field.dart';
import '../../../../shared/snack_bar_manager.dart';
import '../../../folders/view/folder_selector.dart';
import '../../widgets/checklist_editor.dart';
import '../../../home/core/providers.dart';
import '../../../home/view/desktop/content_panel/core/navigator.dart';
import '../../widgets/note_editor_options.dart';
import '../../../lock/lock_manger/lock_manager.dart';
import '../../../lock/view/setup_password_page.dart';
import '../viewmodel/edit_note_view_model.dart';

/// Defines the content structure currently active in the note editor.
enum ContentVersion {
  plainText(1),
  checklist(2);

  final int value;

  const ContentVersion(this.value);

  /// Helper method to easily convert a database integer back into an Enum.
  /// Fallbacks to [ContentVersion.plainText] if the integer is unrecognized.
  static ContentVersion fromValue(int val) {
    return ContentVersion.values.firstWhere(
          (e) => e.value == val,
      orElse: () => ContentVersion.plainText,
    );
  }
}

/// A desktop-optimized page for creating and editing notes.
///
/// Handles automatic saving, syncing, check-lists, and lock management.
class DesktopEditNotePage extends ConsumerStatefulWidget {
  final Note? existingNote;

  const DesktopEditNotePage({super.key, this.existingNote});

  @override
  ConsumerState<DesktopEditNotePage> createState() => _DesktopEditNotePageState();
}

class _DesktopEditNotePageState extends ConsumerState<DesktopEditNotePage> {
  // --- Controllers ---
  late final TextEditingController _titleController;
  late final HighlightingTextField _highlightedContentController;
  final UndoHistoryController _undoController = UndoHistoryController();

  // --- View Models & State Management ---
  late final EditNoteViewModel _viewModel;
  Note? _currentNote;

  String? _selectedFolderIdForNewNote;

  // --- UI State Flags ---
  late bool _isLocked;
  bool _isAutoSyncingTitle = false;
  bool _isDeleted = false;
  bool _isFind = false;
  bool _hasCreatedNewNote = false;

  final ValueNotifier<bool> _isSaved = ValueNotifier(true);

  // --- Timers & Focus ---
  Timer? _autoSaveTimer;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  // --- Checklist Management ---
  ContentVersion _contentVersion = ContentVersion.plainText;
  List<CheckListItemModel> _currentChecklist = [];

  /// Determines if the note is brand new and unsaved to the local database.
  bool get _isNewNote =>
      _currentNote == null ||
          (_currentNote!.title.isEmpty &&
              _currentNote!.content.isEmpty &&
              _currentNote!.cloudSyncStatus == 0 &&
              _currentNote!.localSyncStatus == 0);

  @override
  void initState() {
    super.initState();

    _currentNote = widget.existingNote;
    _viewModel = ref.read(editNoteViewModelProvider.notifier);
    _isLocked = _currentNote?.lockedAt != null;

    _titleController = TextEditingController(text: _currentNote?.title ?? '');
    _highlightedContentController = HighlightingTextField(text: _currentNote?.content ?? '');

    // Initialize checklist logic if applicable
    if (_currentNote != null) {
      final String textContent = _highlightedContentController.text.trim();
      if (_currentNote!.contentVersion == ContentVersion.checklist.value) {
        _contentVersion = ContentVersion.checklist;
        _currentChecklist = _convertTextToChecklist(textContent);
      }
    }

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _isAutoSyncingTitle = _titleController.text.isEmpty && _highlightedContentController.text.isEmpty;

    // Attach listeners
    _highlightedContentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);
    _titleController.addListener(_scheduleAutoSave);
    _highlightedContentController.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();

    // Capture exact final state before destruction
    final finalTitle = _titleController.text;
    final finalContent = _highlightedContentController.text;

    // Push final save to the next event loop, safely escaping widget teardown
    Future(() {
      _executeSave(
        isManualSave: false,
        isDisposing: true,
        overrideTitle: finalTitle,
        overrideContent: finalContent,
      );
    });

    // Cleanup
    _highlightedContentController.removeListener(_syncTitleFromContent);
    _titleController.removeListener(_onTitleChanged);
    _titleController.removeListener(_scheduleAutoSave);
    _highlightedContentController.removeListener(_scheduleAutoSave);

    _titleController.dispose();
    _highlightedContentController.dispose();
    _undoController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _isSaved.dispose();

    super.dispose();
  }

  // ===========================================================================
  // DATA PARSING & SYNC LOGIC
  // ===========================================================================

  /// Converts JSON (or plain text) into a List of Checklist Items.
  List<CheckListItemModel> _convertTextToChecklist(String text) {
    if (text.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(text) as List<dynamic>;
      return decoded.map((e) => CheckListItemModel.fromJson(e)).toList();
    } catch (_) {
      // Fallback: Parsing normal text
      return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
        String cleanLine = line.trimLeft();
        cleanLine = cleanLine.replaceFirst(RegExp(r'^[-*]\s+'), ''); // Strip bullets

        bool isChecked = false;
        if (cleanLine.toLowerCase().startsWith('x ')) {
          isChecked = true;
          cleanLine = cleanLine.substring(2).trimLeft();
        }

        return CheckListItemModel(
          id: UniqueKey().toString(),
          text: cleanLine,
          isChecked: isChecked,
        );
      }).toList();
    }
  }

  /// Converts a Checklist back into plain text, stripping check status.
  String _convertChecklistToText(List<CheckListItemModel> items) {
    return items.map((e) => e.text).join('\n');
  }

  /// Extracts the first line of content and automatically assigns it to the title.
  void _syncTitleFromContent() {
    if (_contentVersion == ContentVersion.checklist) return;
    if (!_isAutoSyncingTitle) return;

    String firstLine = _highlightedContentController.text.isNotEmpty
        ? _highlightedContentController.text.split('\n').first
        : '';

    // Restrict to exactly 30 characters maximum
    if (firstLine.length > 30) {
      firstLine = firstLine.substring(0, 30);
    }

    if (_titleController.text != firstLine) {
      _titleController.value = _titleController.value.copyWith(
        text: firstLine,
        selection: TextSelection.collapsed(offset: firstLine.length),
      );
    }
  }

  /// Detects if the user manually typed in the title field, disabling auto-sync.
  void _onTitleChanged() {
    if (_titleController.text.isEmpty && _highlightedContentController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      String expectedSync = _highlightedContentController.text.isNotEmpty
          ? _highlightedContentController.text.split('\n').first
          : '';
      if (expectedSync.length > 30) expectedSync = expectedSync.substring(0, 30);

      if (_titleController.text != expectedSync) {
        _isAutoSyncingTitle = false;
      }
    }
  }

  // ===========================================================================
  // SAVING & DATABASE LOGIC
  // ===========================================================================

  /// Triggers a delayed auto-save when typing occurs.
  void _scheduleAutoSave() {
    if (_isSaved.value) {
      _isSaved.value = false; // localized update, no setState needed
    }

    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();

    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _executeSave();
    });
  }

  /// Executes database insertion or update based on current state.
  Future<void> _executeSave({
    bool isManualSave = false,
    bool isDisposing = false,
    String? overrideTitle,
    String? overrideContent,
  }) async {
    if (_isDeleted) return;

    final title = (overrideTitle ?? _titleController.text).trim();
    final content = (overrideContent ?? _highlightedContentController.text).trim();

    if (title.isEmpty && content.isEmpty) return;

    if (_isNewNote) {
      if (_hasCreatedNewNote) return;
      if (!isDisposing) _hasCreatedNewNote = true;

      final newlySavedNote = await _viewModel.saveNote(title, content, _contentVersion, folderId: _selectedFolderIdForNewNote,);

      if (!isDisposing && mounted && newlySavedNote != null) {
        setState(() {
          _currentNote = newlySavedNote; // Transitions _isNewNote to false
        });
        _isSaved.value = true;

        if (isManualSave) {
          SnackBarManager.show(msg: 'Saved!', type: SnackBarMessageType.acknowledgment);
        }
      }
    } else {
      if (title != _currentNote!.title ||
          content != _currentNote!.content ||
          _currentNote!.contentVersion != _contentVersion.value) {
        await _viewModel.updateNote(_currentNote!.uuid, title, content, _contentVersion);
      }

      if (!isDisposing && mounted) {
        _isSaved.value = true;
        if (isManualSave) {
          SnackBarManager.show(msg: 'Saved!', type: SnackBarMessageType.acknowledgment);
        }
      }
    }
  }

  /// Handles locking and unlocking of notes via the master password.
  Future<void> _handleLockToggle() async {
    bool isCurrentlyLocked = _isLocked;
    final lockManager = ref.read(lockManagerProvider.notifier);
    bool shouldProceed = false;

    if (!lockManager.hasMasterPassword) {
      final enteredPassword = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black45,
        pageBuilder: (context, anim1, anim2) => const SetupPasswordPage(),
      );

      if (enteredPassword != null && enteredPassword.isNotEmpty) {
        await lockManager.setupMasterPassword(enteredPassword);
        if (context.mounted) SnackBarManager.show(msg: 'Master Password Created!');
        shouldProceed = true;
      }
    } else {
      shouldProceed = true;
    }

    if (shouldProceed && _currentNote != null) {
      final success = await lockManager.togglePersistentLock(
        _currentNote!.uuid,
        '',
        shouldLock: !isCurrentlyLocked,
        ignorePassword: true,
      );

      if (success) {
        if (mounted) {
          setState(() => _isLocked = !_isLocked);
        }

        if (!isCurrentlyLocked) {
          _handleCloseNote(); // Only close the note if it was just locked
        }
      } else {
        if (mounted) SnackBarManager.show(msg: 'Action failed');
      }
    }
  }

  void _handleCloseNote() {
    ref.read(activeNoteProvider.notifier).clear();
    if (context.canPop()) context.pop();
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  String _getFormattedDate() {
    final now = _currentNote?.updatedAt ?? _currentNote?.createdAt ?? DateTime.now();
    return _isNewNote
        ? "${now.month}/${now.day}/${now.year}"
        : "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dynamicMaxWidth = constraints.maxWidth * 0.50;

        return AppScaffold(
          backgroundColor: panelColor,
          title: _buildTopMetaRow(),
          centerTitle: false,
          onClose: _handleCloseNote,
          actions: [
            _buildUndoRedoButtons(),
            const SizedBox(width: 8),

            if (!_isNewNote)
              NoteEditorOptionButton(
                isLocked: _isLocked,
                isPinned: _currentNote?.pinnedAt != null,
                onPressed: (NoteEditorOption option) async {
                  if (_isNewNote && option != NoteEditorOption.info) {
                    SnackBarManager.show(msg: 'Please save the note first', type: SnackBarMessageType.error);
                    return;
                  }

                  final targetUuid = _currentNote!.uuid;
                  final actionsController = ref.read(noteActionsControllerProvider);
                  final deviceInfo = await ref.read(deviceInfoProvider.future);

                  switch (option) {
                    case NoteEditorOption.delete:
                      _isDeleted = true;
                      await actionsController.deleteNotes([targetUuid], deviceInfo.extractPlatform);
                      _handleCloseNote();
                      break;
                    case NoteEditorOption.pin:
                      await actionsController.togglePinNotes([targetUuid]);
                      try {
                        final updatedNote = await ref.read(notesDaoProvider).getNoteById(targetUuid);
                        ref.read(activeNoteProvider.notifier).setNote(updatedNote);
                        _currentNote = updatedNote;
                      } catch (_) {}
                      if (mounted) setState(() {});
                      break;
                    case NoteEditorOption.lock:
                      _handleLockToggle();
                      break;
                    case NoteEditorOption.archive:
                      await actionsController.archiveNotes([targetUuid]);
                      _handleCloseNote();
                      break;
                    case NoteEditorOption.info:
                      if (!context.mounted) return;
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteDetails);
                      break;
                    case NoteEditorOption.checklist:
                      setState(() {
                        if (_contentVersion != ContentVersion.checklist) {
                          _contentVersion = ContentVersion.checklist;
                          _currentChecklist = _convertTextToChecklist(_highlightedContentController.text);
                          _highlightedContentController.text = jsonEncode(
                            _currentChecklist.map((e) => e.toJson()).toList(),
                          );
                        } else {
                          _contentVersion = ContentVersion.plainText;
                          _highlightedContentController.text = _convertChecklistToText(_currentChecklist);
                        }
                      });
                      break;
                    case NoteEditorOption.find:
                      if (_isFind) {
                        _highlightedContentController.searchQuery = '';
                      }
                      setState(() {
                        _isFind = !_isFind;
                      });
                      break;
                    case NoteEditorOption.reminder:
                    // TODO: UI Action - Open DatePicker
                      break;
                  }
                },
              ),
          ],
          body: Column(
            children: [
              if (_isFind) ...{
                FindReplaceWidget(
                  contentController: _highlightedContentController,
                  contentFocusNode: _contentFocusNode,
                  onClose: () {
                    setState(() {
                      _isFind = false;
                    });
                  },
                  padding: 0,
                ),
              } else ...{
                _buildTitleField(maxWidth: dynamicMaxWidth),
              },
              Expanded(child: _buildContentField(padding: 24.0)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMetaRow() {
    final foldersAsync = ref.watch(activeFoldersStreamProvider);

    Folder? currentFolder;
    if (_currentNote?.folderId != null && foldersAsync.hasValue) {
      final match = foldersAsync.value!.where(
              (f) => f.folder.uuid == _currentNote!.folderId
      ).firstOrNull;
      currentFolder = match?.folder;
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          FolderButton(
            selectedFolder: currentFolder,
            emptyLabel: 'No Folder',
            showContextMenus: false,
            onFolderSelected: (folder) async {
              final newFolderId = folder?.uuid; // If they pick "All Notes", this becomes null

              if (_currentNote?.folderId == newFolderId) return;

              if (!_isNewNote && _currentNote != null) {
                await ref.read(notesDaoProvider).updateNoteFolder(_currentNote!.uuid, newFolderId);
              }

              setState(() {
                if (_currentNote != null) {
                  // Update existing note UI
                  _currentNote = _currentNote!.copyWith(folderId: drift.Value(newFolderId));
                } else {
                  // TRACK THE FOLDER FOR THE NEW NOTE
                  _selectedFolderIdForNewNote = newFolderId;
                }
              });
            },
          ),
          const SizedBox(width: 16),
          Text(
            "Edited ${_getFormattedDate()}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          _buildNewLabel()
        ],
      ),
    );
  }

  Widget _buildNewLabel() {
    if (!_isNewNote) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'New',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUndoRedoButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<UndoHistoryValue>(
          valueListenable: _undoController,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.canUndo ? 1.0 : 0.0,
              child: IconButton(
                onPressed: value.canUndo ? () => _undoController.undo() : null,
                icon: const Icon(Icons.undo, size: 20),
              ),
            );
          },
        ),
        ValueListenableBuilder<UndoHistoryValue>(
          valueListenable: _undoController,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.canRedo ? 1.0 : 0.0,
              child: IconButton(
                onPressed: value.canRedo ? () => _undoController.redo() : null,
                icon: const Icon(Icons.redo, size: 20),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTitleField({required double maxWidth}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: Container(
                  height: 40,
                  constraints: BoxConstraints(
                    minWidth: 80,
                    maxWidth: maxWidth,
                  ),
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                          node.unfocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        autofocus: _isNewNote,
                        textAlignVertical: TextAlignVertical.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                          hintText: "Title",
                          // Optimization: Only rebuild suffix icon when focus changes
                          suffixIcon: ListenableBuilder(
                            listenable: _titleFocusNode,
                            builder: (context, child) {
                              if (!_titleFocusNode.hasFocus) return const SizedBox.shrink();

                              return ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _titleController,
                                builder: (context, value, child) {
                                  if (value.text.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      _titleController.clear();
                                      _isAutoSyncingTitle = true;
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            ValueListenableBuilder<bool>(
              valueListenable: _isSaved,
              builder: (context, isSaved, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isSaved
                      ? Padding(
                    key: const ValueKey('saved_state'),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all, size: 16, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          "Saved",
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Material(
                    key: const ValueKey('save_state'),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        _executeSave(isManualSave: true);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Save",
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField({required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(5),
        child: Focus(
          focusNode: _contentFocusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              node.unfocus();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
              node.nextFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: _contentVersion == ContentVersion.checklist
              ? CheckListWidget(
            initialData: _currentChecklist,
            onChange: (List<CheckListItemModel> updatedList) {
              _currentChecklist = updatedList;
              _highlightedContentController.text = jsonEncode(updatedList.map((e) => e.toJson()).toList());
            },
          )
              : TextField(
            controller: _highlightedContentController,
            undoController: _undoController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: InputBorder.none, hint: Text("Type here...")),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}