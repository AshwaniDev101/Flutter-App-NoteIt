import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/util/platform_helper.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../shared/app_bars/desktop_window_controls.dart';
import '../../../../shared/note_card/core/note_action.dart';
import '../../../../shared/note_card/core/note_action_controller.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../../../shared/text/find_replace.dart';
import '../../../../shared/text/highlighting_text_field.dart';
import '../../../folders/view/folder_option_menu.dart';
import '../../../home/core/providers.dart';
import '../../../home/view/desktop/content_panel/core/navigator.dart';
import '../../../lock/lock_manger/lock_manager.dart';
import '../../../lock/view/setup_password_page.dart';
import '../../../reminder/reminder_manager.dart';
import '../../../reminder/reminder_page.dart';
import '../../widgets/checklist_editor.dart';
import '../../widgets/note_editor_options.dart';
import '../viewmodel/edit_note_view_model.dart';
import 'desktop_edit_page.dart';

class MobileEditNotePage extends ConsumerStatefulWidget {
  final NoteWithFolder? existingNoteWithFolder;

  const MobileEditNotePage({super.key, this.existingNoteWithFolder});

  @override
  ConsumerState<MobileEditNotePage> createState() => _MobileEditNotePageState();
}

class _MobileEditNotePageState extends ConsumerState<MobileEditNotePage> {
  static final RegExp _bulletPrefixRegex = RegExp(r'^[-*]\s+');

  late final TextEditingController _titleController;
  late final HighlightingTextField _contentController;
  final UndoHistoryController _undoController = UndoHistoryController();

  late final EditNoteViewModel _viewModel;
  late final ActiveNoteNotifier _activeNoteNotifier;
  late final NotesDao _notesDao;
  NoteWithFolder? _currentNoteWithFolder;
  Folder? _selectedFolderForNewNote;

  bool _isAutoSyncingTitle = false;
  late bool _isLocked;
  late bool _isPinned;
  bool _hasTriggeredFinalSave = false;
  bool _hasCreatedNewNote = false;
  bool _isFind = false;

  ContentVersion _contentVersion = ContentVersion.plainText;
  List<CheckListItemModel> _currentChecklist = [];

  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  bool get _isNewNote =>
      _currentNoteWithFolder == null ||
          (_currentNoteWithFolder!.note.title.isEmpty &&
              _currentNoteWithFolder!.note.content.isEmpty &&
              _currentNoteWithFolder!.note.cloudSyncStatus == 0 &&
              _currentNoteWithFolder!.note.localSyncStatus == 0);

  // =============================================================================
  // LIFECYCLE METHODS
  // =============================================================================

  @override
  void initState() {
    super.initState();
    _currentNoteWithFolder = widget.existingNoteWithFolder;
    _viewModel = ref.read(editNoteViewModelProvider.notifier);
    _activeNoteNotifier = ref.read(activeNoteProvider.notifier);
    _notesDao = ref.read(notesDaoProvider);
    _isLocked = _currentNoteWithFolder?.note.lockedAt != null;
    _isPinned = _currentNoteWithFolder?.note.pinnedAt != null;

    _titleController = TextEditingController(text: _currentNoteWithFolder?.note.title ?? '');
    _contentController = HighlightingTextField(text: _currentNoteWithFolder?.note.content ?? '');

    if (_currentNoteWithFolder != null) {
      final String textContent = _contentController.text.trim();
      if (_currentNoteWithFolder!.note.contentVersion == ContentVersion.checklist.value ||
          (textContent.startsWith('[') && textContent.endsWith(']'))) {
        _contentVersion = ContentVersion.checklist;
        _currentChecklist = _convertTextToChecklist(textContent);
      }
    }

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    if (_titleController.text.isEmpty) _isAutoSyncingTitle = true;

    _contentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);

    if (_currentNoteWithFolder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _activeNoteNotifier.setNote(_currentNoteWithFolder!);
        }
      });
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

    Future.microtask(() {
      _activeNoteNotifier.clear();
    });

    super.dispose();
  }

  // =============================================================================
  // TITLE SYNC & CHECKLIST CONVERSION LOGIC
  // =============================================================================

  List<CheckListItemModel> _convertTextToChecklist(String text) {
    if (text.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(text) as List<dynamic>;
      return decoded.map((e) => CheckListItemModel.fromJson(e)).toList();
    } catch (_) {
      return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
        String cleanLine = line.trimLeft().replaceFirst(_bulletPrefixRegex, '');
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
    final text = _contentController.text;
    if (text.isEmpty) return '';
    final newlineIndex = text.indexOf('\n');
    return newlineIndex != -1 ? text.substring(0, newlineIndex) : text;
  }

  void _syncTitleFromContent() {
    if (_contentVersion == ContentVersion.checklist || !_isAutoSyncingTitle) return;

    final firstLine = _extractFirstLineForTitle();
    if (_titleController.text != firstLine) {
      _titleController.value = _titleController.value.copyWith(
        text: firstLine,
        selection: TextSelection.collapsed(offset: firstLine.length),
      );
    }
  }

  void _onTitleChanged() {
    if (_contentVersion == ContentVersion.checklist) return;

    if (_titleController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else if (_titleController.text != _extractFirstLineForTitle()) {
      _isAutoSyncingTitle = false;
    }
  }

  // =============================================================================
  // PERSISTENCE & ACTIONS
  // =============================================================================

  Future<void> _executeSave({bool isManualSave = false}) async {
    if (_hasTriggeredFinalSave && !isManualSave) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    if (_isNewNote) {
      if (_hasCreatedNewNote) return;

      final newlySavedNote = await _viewModel.saveNote(
        title,
        content,
        _contentVersion,
        folderId: _selectedFolderForNewNote?.uuid,
      );

      if (newlySavedNote != null) {
        if (mounted) {
          setState(() {
            _currentNoteWithFolder = newlySavedNote;
          });
        }
        _activeNoteNotifier.setNote(newlySavedNote);
      }
      _hasCreatedNewNote = true;
    } else {
      if (title != _currentNoteWithFolder!.note.title ||
          content != _currentNoteWithFolder!.note.content ||
          _currentNoteWithFolder!.note.contentVersion != _contentVersion.value) {
        await _viewModel.updateNote(_currentNoteWithFolder!.note.uuid, title, content, _contentVersion);
        try {
          final updatedNote = await _notesDao.getNoteById(_currentNoteWithFolder!.note.uuid);
          _activeNoteNotifier.setNote(updatedNote);
        } catch (_) {}
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
    if (!_isNewNote && _currentNoteWithFolder != null) {
      _hasTriggeredFinalSave = true;
      ref.read(editNoteViewModelProvider.notifier).deleteNote(_currentNoteWithFolder!.note.uuid);
      if (mounted) context.pop();
    }
  }

  void _handleMobileBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    _executeSave(isManualSave: false);
    if (mounted) context.pop();
  }

  Future<void> _handleLockToggle() async {
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

    if (shouldProceed && _currentNoteWithFolder != null) {
      final success = await lockManager.togglePersistentLock(
        _currentNoteWithFolder!.note.uuid,
        '',
        shouldLock: !_isLocked,
        ignorePassword: true,
      );

      if (success && mounted) {
        setState(() => _isLocked = !_isLocked);
        if (!_isLocked) {
          context.pop();
        }
      } else if (mounted) {
        SnackBarManager.show(msg: 'Action failed');
      }
    }
  }

  Future<void> _openReminderDialog() async {
    if (_currentNoteWithFolder == null) return;
    final mTargetUuid = _currentNoteWithFolder!.note.uuid;
    final mTargetTitle = _currentNoteWithFolder!.note.title;
    final mExistingReminder = _currentNoteWithFolder!.note.reminderAt;
    final mExistingRepeatMode = _currentNoteWithFolder!.note.reminderRepeatMode;
    final mExistingCustomDays = _currentNoteWithFolder!.note.reminderCustomDays;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ReminderPage(
        noteUuid: mTargetUuid,
        noteTitle: mTargetTitle,
        existingReminderAt: mExistingReminder,
        existingRepeatMode: mExistingRepeatMode,
        existingCustomDays: mExistingCustomDays,
      ),
    );
    if (!mounted) return;
    try {
      final updatedNote = await ref.read(notesDaoProvider).getNoteById(mTargetUuid);
      ref.read(activeNoteProvider.notifier).setNote(updatedNote);
      setState(() {
        _currentNoteWithFolder = updatedNote;
      });
    } catch (_) {}
  }

  String _getFormattedDate() {
    final now = _currentNoteWithFolder?.note.updatedAt ?? _currentNoteWithFolder?.note.createdAt ?? DateTime.now();
    if (_isNewNote) {
      return '${now.month}/${now.day}/${now.year}';
    }
    final minuteStr = now.minute.toString().padLeft(2, '0');
    return '${now.month}/${now.day}/${now.year} ${now.hour}:$minuteStr';
  }

  // =============================================================================
  // UI BUILDERS
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    final panelColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) _handleMobileBack();
      },
      child: Scaffold(
        backgroundColor: panelColor,
        appBar: PlatformHelper.isWindows
            ? null
            : AppBar(
                backgroundColor: panelColor,
                surfaceTintColor: Colors.transparent,
                title: _getTextField(),
                actions: [_optionMenu()],
              ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (PlatformHelper.isWindows) _buildTopRow(),
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
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildUndoRedoButtons(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final isDesktop = PlatformHelper.isNativeDesktop;
    final isWide = PlatformHelper.isWideLayout(context);

    final titleTextField = _getTextField();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Window Controls and Drag Area (Desktop Only)
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(height: 32), // Standard drag area height
                  ),
                ),
              ),
              const DesktopWindowControls(),
            ],
          ),

        // Row 2: Title Bar, Back Button, Options
        Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 16.0, top: 8.0, bottom: 8.0),
          child: SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isWide) ...[
                  IconButton(
                    onPressed: _handleMobileBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: titleTextField,
                ),
                if (!isWide) _optionMenu(),
              ],
            ),
          ),
        ),
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
    final currentFolder = _currentNoteWithFolder?.folder ?? _selectedFolderForNewNote;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Folder, Lock, and Date Stamp (on the right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FolderOptionMenu(
                        selectedFolder: currentFolder,
                        emptyLabel: 'none',
                        onFolderSelected: (folder) async {
                          final newFolderId = folder?.uuid;
                          if (_currentNoteWithFolder?.note.folderId == newFolderId) return;

                          if (!_isNewNote && _currentNoteWithFolder != null) {
                            await ref.read(notesDaoProvider).updateNoteFolder(_currentNoteWithFolder!.note.uuid, newFolderId);
                          }

                          setState(() {
                            if (_currentNoteWithFolder != null) {
                              final updatedDriftNote = _currentNoteWithFolder!.note.copyWith(folderId: drift.Value(newFolderId));
                              _currentNoteWithFolder = NoteWithFolder(note: updatedDriftNote, folder: folder);
                            } else {
                              _selectedFolderForNewNote = folder;
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_isLocked) ...[
                        const Icon(Icons.lock_outline, size: 16),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _getFormattedDate(),
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (_isNewNote) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'New',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Row 2: Reminder on the right
          if (_currentNoteWithFolder?.note.reminderAt != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildReminderChip(context, _currentNoteWithFolder!.note.reminderAt!),
              ],
            ),
          ],
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

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.canUndo)
              IconButton(
                onPressed: () => _undoController.undo(),
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo',
              ),
            if (value.canRedo)
              IconButton(
                onPressed: () => _undoController.redo(),
                icon: const Icon(Icons.redo, size: 20),
                tooltip: 'Redo',
              ),
          ],
        );
      },
    );
  }

  Widget _optionMenu() {
    return NoteEditorOptionButton(
      isLocked: _isLocked,
      isPinned: _isPinned,
      isChecklist: _contentVersion == ContentVersion.checklist,
      hasReminder: _currentNoteWithFolder?.note.reminderAt != null,
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
            final targetUuid = _currentNoteWithFolder!.note.uuid;
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
            final targetUuid = _currentNoteWithFolder!.note.uuid;
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
            await _openReminderDialog();
            break;
          case NoteAction.info:
            _executeSave(isManualSave: false);
            if (_currentNoteWithFolder != null) {
              try {
                final currentNote = await ref.read(notesDaoProvider).getNoteById(_currentNoteWithFolder!.note.uuid);
                ref.read(activeNoteProvider.notifier).setNote(currentNote);
              } catch (_) {
                ref.read(activeNoteProvider.notifier).setNote(_currentNoteWithFolder!);
              }
            }
            if (!mounted) return;
            ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteDetails);
            break;
          default:
            break;
        }
      },
    );
  }

  Widget _buildReminderChip(BuildContext context, DateTime reminderAt) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPast = reminderAt.isBefore(DateTime.now());
    final formattedDate = ReminderManager.formatReminderLabel(
      reminderAt,
      _currentNoteWithFolder?.note.reminderRepeatMode,
      _currentNoteWithFolder?.note.reminderCustomDays,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openReminderDialog,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPast
                ? colorScheme.errorContainer.withValues(alpha: 0.8)
                : colorScheme.secondaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPast
                  ? colorScheme.error.withValues(alpha: 0.4)
                  : colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPast ? Icons.notification_important_rounded : Icons.notifications_active_rounded,
                size: 14,
                color: isPast ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  formattedDate,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPast ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTextField() {
    return Focus(
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
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: 'Title',
          suffixIcon: ListenableBuilder(
            listenable: _titleFocusNode,
            builder: (context, _) {
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
        ),
      ),
    );
  }
}