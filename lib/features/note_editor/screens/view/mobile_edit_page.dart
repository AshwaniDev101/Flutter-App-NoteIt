import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import 'package:noteit/features/note_editor/screens/view/desktop_edit_page.dart';

import 'package:window_manager/window_manager.dart';

import '../../../../core/util/platform_helper.dart';
import '../../../../shared/text/find_replace.dart';
import '../../../../shared/note_card/core/note_action.dart';
import '../../../../shared/note_card/core/note_action_controller.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../../../shared/text/highlighting_text_field.dart';
import '../../../folders/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../widgets/checklist_editor.dart';
import '../../widgets/folder_option_menu.dart';
import '../../widgets/note_editor_options.dart';

import '../../../lock/lock_manger/lock_manager.dart';
import '../../../lock/view/setup_password_page.dart';
import '../viewmodel/edit_note_view_model.dart';


class MobileEditNotePage extends ConsumerStatefulWidget {
  final NoteWithFolder? existingNoteWithFolder;

  const MobileEditNotePage({super.key, this.existingNoteWithFolder});

  @override
  ConsumerState<MobileEditNotePage> createState() => _MobileEditNotePageState();
}

class _MobileEditNotePageState extends ConsumerState<MobileEditNotePage> {

  late final TextEditingController _titleController;
  late final HighlightingTextField _contentController;
  final UndoHistoryController _undoController = UndoHistoryController();

  late final EditNoteViewModel _viewModel;

  bool _isAutoSyncingTitle = false;
  late bool _isLocked;
  late bool _isPinned;
  bool _hasTriggeredFinalSave = false;
  bool _hasCreatedNewNote = false;
  bool _isFind = false;

  // --- Checklist State ---
  ContentVersion _contentVersion = ContentVersion.plainText;
  List<CheckListItemModel> _currentChecklist = [];

  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  bool get _isNewNote =>
      widget.existingNoteWithFolder == null ||
          (widget.existingNoteWithFolder!.note.title.isEmpty &&
              widget.existingNoteWithFolder!.note.content.isEmpty &&
              widget.existingNoteWithFolder!.note.cloudSyncStatus == 0 &&
              widget.existingNoteWithFolder!.note.localSyncStatus == 0);

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(editNoteViewModelProvider.notifier);
    _isLocked = widget.existingNoteWithFolder?.note.lockedAt != null;
    _isPinned = widget.existingNoteWithFolder?.note.pinnedAt != null;

    _titleController = TextEditingController(text: widget.existingNoteWithFolder?.note.title ?? '');
    _contentController = HighlightingTextField(text: widget.existingNoteWithFolder?.note.content ?? '');

    // --- Checklist Init ---
    if (widget.existingNoteWithFolder != null) {
      final String textContent = _contentController.text.trim();
      if (widget.existingNoteWithFolder!.note.contentVersion == ContentVersion.checklist.value ||
          (textContent.startsWith('[') && textContent.endsWith(']'))) {
        _contentVersion = ContentVersion.checklist;
        _currentChecklist = _convertTextToChecklist(textContent);
      }
    }

    _titleFocusNode = FocusNode()..addListener(() => setState(() {}));
    _contentFocusNode = FocusNode();

    if (_titleController.text.isEmpty) _isAutoSyncingTitle = true;

    _contentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);
  }

  // --- Checklist Conversion Helpers ---
  List<CheckListItemModel> _convertTextToChecklist(String text) {
    if (text.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(text) as List<dynamic>;
      return decoded.map((e) => CheckListItemModel.fromJson(e)).toList();
    } catch (_) {
      return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
        String cleanLine = line.trimLeft().replaceFirst(RegExp(r'^[-*]\s+'), '');
        bool isChecked = false;
        if (cleanLine.toLowerCase().startsWith('x ')) {
          isChecked = true;
          cleanLine = cleanLine.substring(2).trimLeft();
        }
        return CheckListItemModel(id: UniqueKey().toString(), text: cleanLine, isChecked: isChecked);
      }).toList();
    }
  }

  String _convertChecklistToText(List<CheckListItemModel> items) {
    return items.map((e) => e.text).join('\n');
  }

  String _extractFirstLineForTitle() {
    if (_contentVersion == ContentVersion.checklist) {
      return _currentChecklist.isNotEmpty ? _currentChecklist.first.text : '';
    }
    return _contentController.text.isNotEmpty ? _contentController.text.split('\n').first : '';
  }
  // -------------------------------

  void _syncTitleFromContent() {
    if (_contentVersion == ContentVersion.checklist) return; // Prevent JSON syncing
    if (!_isAutoSyncingTitle) return;

    final firstLine = _extractFirstLineForTitle();
    if (_titleController.text != firstLine) {
      _titleController.value = _titleController.value.copyWith(
        text: firstLine,
        selection: TextSelection.collapsed(offset: firstLine.length),
      );
    }
  }

  void _onTitleChanged() {
    if (_contentVersion == ContentVersion.checklist) return; // Prevent JSON syncing

    if (_titleController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      if (_titleController.text != _extractFirstLineForTitle()) _isAutoSyncingTitle = false;
    }
  }

  @override
  void dispose() {
    _executeSave(isManualSave: false);

    _contentController.searchQuery = '';
    _contentController.removeListener(_syncTitleFromContent);
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _executeSave({bool isManualSave = false}) {
    if (_hasTriggeredFinalSave && !isManualSave) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    if (_isNewNote) {
      if (_hasCreatedNewNote) return;

      final activeFolderId = ref.read(activeFolderProvider)?.uuid;
      _viewModel.saveNote(title, content, _contentVersion, folderId: activeFolderId);
      _hasCreatedNewNote = true;
    } else {
      // Check for version changes and pass _contentVersion
      if (title != widget.existingNoteWithFolder!.note.title ||
          content != widget.existingNoteWithFolder!.note.content ||
          widget.existingNoteWithFolder!.note.contentVersion != _contentVersion.value) {

        _viewModel.updateNote(widget.existingNoteWithFolder!.note.uuid, title, content, _contentVersion);
      }
    }

    if (isManualSave && mounted) {
      SnackBarManager.show(
        msg: 'Saved!',
        type: SnackBarMessageType.acknowledgment,
      );
    }

    if (!isManualSave) _hasTriggeredFinalSave = true;
  }

  void _handleDeleteNote() {
    if (!_isNewNote && widget.existingNoteWithFolder != null) {
      _hasTriggeredFinalSave = true;
      ref.read(editNoteViewModelProvider.notifier).deleteNote(widget.existingNoteWithFolder!.note.uuid);
      if (mounted) context.pop();
    }
  }

  void _handleMobileBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    _executeSave(isManualSave: false);
    if (mounted) context.pop();
  }

  String _getFormattedDate() {
    final now = widget.existingNoteWithFolder?.note.updatedAt ?? widget.existingNoteWithFolder?.note.createdAt ?? DateTime.now();
    return _isNewNote
        ? "${now.month}/${now.day}/${now.year}"
        : "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) _handleMobileBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: AppBar(
          flexibleSpace: PlatformHelper.isNativeDesktop
              ? DragToMoveArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          )
              : null,
          automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleMobileBack),
          titleSpacing: 0,

          actions: [

            if (PlatformHelper.isNativeDesktop) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.minimize, size: 16),
                onPressed: () => windowManager.minimize(),
              ),
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
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => windowManager.close(),
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildTitleField(),
              ),
              if (_isFind) ...[
                FindReplaceWidget(
                  contentController: _contentController,
                  contentFocusNode: _contentFocusNode,
                  onClose: () {
                    _contentController.searchQuery = '';
                    setState(() {
                      _isFind = false;
                    });
                  },
                  padding: 16.0,
                ),
              ] else ...[
                _buildMetaDataRow(padding: 16.0),
              ],
              Expanded(child: _buildContentField(padding: 16.0)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildUndoRedoButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Row(
      children: [
        Flexible(
          child: SizedBox(
            height: 40,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Title",
                  suffixIcon: _titleFocusNode.hasFocus
                      ? ValueListenableBuilder<TextEditingValue>(
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
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 8,),
        _optionMenu()
      ],
    );
  }

  Widget _buildContentField({required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
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
        // --- UI Swap Logic ---
        child: _contentVersion == ContentVersion.checklist
            ? CheckListWidget(
          initialData: _currentChecklist,
          onChange: (List<CheckListItemModel> updatedList) {
            _currentChecklist = updatedList;
            _contentController.text = jsonEncode(updatedList.map((e) => e.toJson()).toList());
          },
        )
            : TextField(
          controller: _contentController,
          undoController: _undoController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: InputBorder.none),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildMetaDataRow({required double padding}) {
    final currentFolder = widget.existingNoteWithFolder?.folder;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _isNewNote
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _isNewNote ? 'New' : 'Updating...',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FolderOptionMenu(
            selectedFolder: currentFolder,
            emptyLabel: 'none',
            onFolderSelected: (folder) async {
              final newFolderId = folder?.uuid;
              if (widget.existingNoteWithFolder?.note.folderId == newFolderId) return;
              if (!_isNewNote && widget.existingNoteWithFolder != null) {
                await ref.read(notesDaoProvider).updateNoteFolder(widget.existingNoteWithFolder!.note.uuid, newFolderId);
              }
            },
          ),
          const Spacer(),
          if (_isLocked) ...[
            const Icon(Icons.lock_outline, size: 16),
            const SizedBox(width: 8),
          ],
          SelectableText(
              _getFormattedDate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
          ),
        ],
      ),
    );
  }

  Widget _buildUndoRedoButtons() {
    return ValueListenableBuilder<UndoHistoryValue>(
      valueListenable: _undoController,
      builder: (context, value, child) {
        if (!value.canUndo && !value.canRedo) {
          return const SizedBox.shrink();
        }

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.canUndo)
                IconButton(
                  onPressed: () => _undoController.undo(),
                  icon: const Icon(Icons.undo, size: 24),
                  tooltip: 'Undo',
                ),
              if (value.canUndo && value.canRedo) const SizedBox(width: 24),
              if (value.canRedo)
                IconButton(
                  onPressed: () => _undoController.redo(),
                  icon: const Icon(Icons.redo, size: 24),
                  tooltip: 'Redo',
                ),
            ],
          ),
        );
      },
    );
  }

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

    if (shouldProceed && widget.existingNoteWithFolder != null) {
      final success = await lockManager.togglePersistentLock(
        widget.existingNoteWithFolder!.note.uuid,
        '',
        shouldLock: !isCurrentlyLocked,
        ignorePassword: true,
      );

      if (success) {
        if (mounted) {
          setState(() => _isLocked = !_isLocked);

          // Mobile specific UX: If we lock it, pop back to the list
          if (!isCurrentlyLocked) {
            context.pop();
          }
        }
      } else {
        if (mounted) SnackBarManager.show(msg: 'Action failed');
      }
    }
  }

  Widget _optionMenu() {
    return NoteEditorOptionButton(
      isLocked: _isLocked,
      isPinned: _isPinned,
      onPressed: (NoteAction option) async {
        switch (option) {
          case NoteAction.delete:
            _handleDeleteNote();
            break;
          case NoteAction.pin:
            if (_isNewNote) {
              SnackBarManager.show(msg: 'Please save the note first', type: SnackBarMessageType.error);
              return;
            }
            final targetUuid = widget.existingNoteWithFolder!.note.uuid;
            final actionsController = ref.read(noteActionsControllerProvider);
            await actionsController.togglePinNotes([targetUuid]);
            if (mounted) {
              setState(() {
                _isPinned = !_isPinned;
              });
            }
            break;
          case NoteAction.lock:
            _handleLockToggle();
            break;
          case NoteAction.checklist:
            setState(() {
              if (_contentVersion != ContentVersion.checklist) {
                _contentVersion = ContentVersion.checklist;
                _currentChecklist = _convertTextToChecklist(_contentController.text);
                _contentController.text = jsonEncode(_currentChecklist.map((e) => e.toJson()).toList());
              } else {
                _contentVersion = ContentVersion.plainText;
                _contentController.text = _convertChecklistToText(_currentChecklist);
              }
            });
            break;

          case NoteAction.archive:
            if (_isNewNote) {
              SnackBarManager.show(msg: 'Please save the note first', type: SnackBarMessageType.error);
              return;
            }
            _hasTriggeredFinalSave = true;
            final targetUuid = widget.existingNoteWithFolder!.note.uuid;
            final router = GoRouter.of(context);
            await ref.read(noteActionsControllerProvider).archiveNotes([targetUuid]);
            if (context.mounted) router.pop();
            break;
          case NoteAction.find:
            if (_isFind) {
              _contentController.searchQuery = '';
            }
            setState(() {
              _isFind = !_isFind;
            });
            break;
          case NoteAction.reminder:
            break;
          case NoteAction.info:
            ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteDetails);
            break;
          default:
            break;
        }
      },
    );
  }
}