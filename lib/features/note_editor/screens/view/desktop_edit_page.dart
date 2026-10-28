import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/util/device_info.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../shared/note_card/core/note_action.dart';
import '../../../../shared/note_card/core/note_action_controller.dart';
import '../../../../shared/overlays/app_scaffold.dart';
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

/// Defines the content structure currently active in the note editor.
enum ContentVersion {
  plainText(1),
  checklist(2);

  final int value;

  const ContentVersion(this.value);

  /// Helper method to convert a database integer back into a [ContentVersion].
  /// Fallbacks to [ContentVersion.plainText] if unrecognized.
  static ContentVersion fromValue(int val) {
    return ContentVersion.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ContentVersion.plainText,
    );
  }
}

/// A desktop-optimized page for creating and editing notes.
/// Handles automatic saving, syncing, check-lists, and lock management.
class DesktopEditNotePage extends ConsumerStatefulWidget {
  final NoteWithFolder? existingNoteWithFolder;

  const DesktopEditNotePage({super.key, this.existingNoteWithFolder});

  @override
  ConsumerState<DesktopEditNotePage> createState() => _DesktopEditNotePageState();
}

class _DesktopEditNotePageState extends ConsumerState<DesktopEditNotePage> {
  static final RegExp _bulletPrefixRegex = RegExp(r'^[-*]\s+');

  late final TextEditingController _titleController;
  late final HighlightingTextField _highlightedContentController;
  final UndoHistoryController _undoController = UndoHistoryController();

  late final EditNoteViewModel _viewModel;
  NoteWithFolder? _currentNoteWithFolder;
  Folder? _selectedFolderForNewNote;

  late bool _isLocked;
  bool _isAutoSyncingTitle = false;
  bool _isDeleted = false;
  bool _isFind = false;
  bool _hasCreatedNewNote = false;

  final ValueNotifier<bool> _isSaved = ValueNotifier(true);

  Timer? _autoSaveTimer;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  ContentVersion _contentVersion = ContentVersion.plainText;
  List<CheckListItemModel> _currentChecklist = [];

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
    _isLocked = _currentNoteWithFolder?.note.lockedAt != null;

    _titleController = TextEditingController(text: _currentNoteWithFolder?.note.title ?? '');
    _highlightedContentController = HighlightingTextField(text: _currentNoteWithFolder?.note.content ?? '');

    if (_currentNoteWithFolder != null) {
      final String textContent = _highlightedContentController.text.trim();
      if (_currentNoteWithFolder!.note.contentVersion == ContentVersion.checklist.value) {
        _contentVersion = ContentVersion.checklist;
        _currentChecklist = _convertTextToChecklist(textContent);
      }
    }

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _isAutoSyncingTitle = _titleController.text.isEmpty && _highlightedContentController.text.isEmpty;

    _highlightedContentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);
    _titleController.addListener(_scheduleAutoSave);
    _highlightedContentController.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();

    final finalTitle = _titleController.text;
    final finalContent = _highlightedContentController.text;

    Future(() {
      _executeSave(
        isManualSave: false,
        isDisposing: true,
        overrideTitle: finalTitle,
        overrideContent: finalContent,
      );
    });

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
      final text = _currentChecklist.isNotEmpty ? _currentChecklist.first.text : '';
      return text.length > 30 ? text.substring(0, 30) : text;
    }
    final text = _highlightedContentController.text;
    if (text.isEmpty) return '';
    final newlineIndex = text.indexOf('\n');
    final line = newlineIndex != -1 ? text.substring(0, newlineIndex) : text;
    return line.length > 30 ? line.substring(0, 30) : line;
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
    if (_titleController.text.isEmpty && _highlightedContentController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      final expectedSync = _extractFirstLineForTitle();
      if (_titleController.text != expectedSync) {
        _isAutoSyncingTitle = false;
      }
    }
  }

  // =============================================================================
  // PERSISTENCE & ACTIONS
  // =============================================================================

  void _scheduleAutoSave() {
    if (_isSaved.value) {
      _isSaved.value = false;
    }

    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();

    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _executeSave();
    });
  }

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

      final newlySavedNote = await _viewModel.saveNote(
        title,
        content,
        _contentVersion,
        folderId: _selectedFolderForNewNote?.uuid,
      );

      if (!isDisposing && mounted && newlySavedNote != null) {
        setState(() {
          _currentNoteWithFolder = newlySavedNote;
        });
        _isSaved.value = true;

        if (isManualSave) {
          SnackBarManager.show(msg: 'Saved!', type: SnackBarMessageType.acknowledgment);
        }
      }
    } else {
      if (title != _currentNoteWithFolder!.note.title ||
          content != _currentNoteWithFolder!.note.content ||
          _currentNoteWithFolder!.note.contentVersion != _contentVersion.value) {
        await _viewModel.updateNote(_currentNoteWithFolder!.note.uuid, title, content, _contentVersion);
      }

      if (!isDisposing && mounted) {
        _isSaved.value = true;
        if (isManualSave) {
          SnackBarManager.show(msg: 'Saved!', type: SnackBarMessageType.acknowledgment);
        }
      }
    }
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

      if (success) {
        if (mounted) {
          setState(() => _isLocked = !_isLocked);
        }
        if (!_isLocked) {
          _handleCloseNote();
        }
      } else if (mounted) {
        SnackBarManager.show(msg: 'Action failed');
      }
    }
  }

  void _handleCloseNote() {
    ref.read(activeNoteProvider.notifier).clear();
    ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.noteEditor);
    if (mounted && context.canPop()) context.pop();
  }

  Future<void> _openReminderDialog() async {
    if (_currentNoteWithFolder == null) return;
    final targetUuid = _currentNoteWithFolder!.note.uuid;
    final targetTitle = _currentNoteWithFolder!.note.title;
    final existingReminder = _currentNoteWithFolder!.note.reminderAt;
    final existingRepeatMode = _currentNoteWithFolder!.note.reminderRepeatMode;
    final existingCustomDays = _currentNoteWithFolder!.note.reminderCustomDays;

    await showDialog<bool>(
      context: context,
      builder: (_) => ReminderPage(
        noteUuid: targetUuid,
        noteTitle: targetTitle,
        existingReminderAt: existingReminder,
        existingRepeatMode: existingRepeatMode,
        existingCustomDays: existingCustomDays,
      ),
    );

    if (!mounted) return;
    try {
      final updatedNote = await ref.read(notesDaoProvider).getNoteById(targetUuid);
      ref.read(activeNoteProvider.notifier).setNote(updatedNote);
      if (mounted) setState(() => _currentNoteWithFolder = updatedNote);
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
    final currentFolder = _currentNoteWithFolder?.folder ?? _selectedFolderForNewNote;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxTextWidth = 850.0;
        const double leftPadding = 48.0;

        final double rightPadding = constraints.maxWidth > (maxTextWidth + leftPadding + 48.0)
            ? constraints.maxWidth - maxTextWidth - leftPadding
            : 48.0;

        return AppScaffold(
          backgroundColor: panelColor,
          title: _buildTopMetaRow(currentFolder),
          centerTitle: false,
          onClose: _handleCloseNote,
          actions: [
            _buildUndoRedoButtons(),
            if (!_isNewNote)
              NoteEditorOptionButton(
                isLocked: _isLocked,
                isPinned: _currentNoteWithFolder?.note.pinnedAt != null,
                isChecklist: _contentVersion == ContentVersion.checklist,
                hasReminder: _currentNoteWithFolder?.note.reminderAt != null,
                onPressed: (NoteAction option) async {
                  if (_isNewNote && option != NoteAction.info) {
                    SnackBarManager.show(msg: 'Please save the note first', type: SnackBarMessageType.error);
                    return;
                  }

                  final targetUuid = _currentNoteWithFolder!.note.uuid;
                  final actionsController = ref.read(noteActionsControllerProvider);
                  final deviceInfo = await ref.read(deviceInfoProvider.future);
                  if (!context.mounted) return;

                  switch (option) {
                    case NoteAction.delete:
                      _isDeleted = true;
                      await actionsController.deleteNotes([targetUuid], deviceInfo.extractPlatform);
                      _handleCloseNote();
                      break;
                    case NoteAction.pin:
                      await actionsController.togglePinNotes([targetUuid]);
                      try {
                        final updatedNote = await ref.read(notesDaoProvider).getNoteById(targetUuid);
                        ref.read(activeNoteProvider.notifier).setNote(updatedNote);
                        _currentNoteWithFolder = updatedNote;
                      } catch (_) {}
                      if (mounted) setState(() {});
                      break;
                    case NoteAction.lock:
                      _handleLockToggle();
                      break;
                    case NoteAction.archive:
                      await actionsController.archiveNotes([targetUuid]);
                      _handleCloseNote();
                      break;
                    case NoteAction.info:
                      if (!context.mounted) return;
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteDetails);
                      break;
                    case NoteAction.checklist:
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
                    case NoteAction.find:
                      if (_isFind) {
                        _highlightedContentController.searchQuery = '';
                      }
                      setState(() {
                        _isFind = !_isFind;
                      });
                      break;
                    case NoteAction.reminder:
                      await _openReminderDialog();
                      break;
                    default:
                      break;
                  }
                },
              ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isFind)
                FindReplaceWidget(
                  contentController: _highlightedContentController,
                  contentFocusNode: _contentFocusNode,
                  onClose: () {
                    setState(() {
                      _isFind = false;
                    });
                  },
                  padding: leftPadding,
                ),
              _buildTitleField(leftPadding: leftPadding, rightPadding: rightPadding),
              Expanded(
                child: _buildContentField(leftPadding: leftPadding, rightPadding: rightPadding),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMetaRow(Folder? currentFolder) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 8),
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
          const SizedBox(width: 16),
          Text(
            'Edited ${_getFormattedDate()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _isSaved,
            builder: (context, isSaved, child) {
              return isSaved
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all, size: 16, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    )
                  : Material(
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
                              Icon(Icons.done, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Save',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
            },
          ),
          if (_currentNoteWithFolder?.note.reminderAt != null) ...[
            const SizedBox(width: 8),
            _buildReminderChip(context, _currentNoteWithFolder!.note.reminderAt!),
          ],
          const SizedBox(width: 16),
          _buildNewLabel(),
        ],
      ),
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
              Text(
                formattedDate,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPast ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
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
      child: Text('New', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
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
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Widget _buildTitleField({required double leftPadding, required double rightPadding}) {
    return FocusTraversalOrder(
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
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(leftPadding, 32, rightPadding, 8),
            hintText: 'Title',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
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
                    return Padding(
                      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _titleController.clear();
                          _isAutoSyncingTitle = true;
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentField({required double leftPadding, required double rightPadding}) {
    return FocusTraversalOrder(
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
            ? Padding(
                padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
                child: ListenableBuilder(
                  listenable: _highlightedContentController,
                  builder: (context, _) {
                    return CheckListWidget(
                      initialData: _currentChecklist,
                      searchQuery: _highlightedContentController.searchQuery,
                      onChange: (List<CheckListItemModel> updatedList) {
                        _currentChecklist = updatedList;
                        _highlightedContentController.text = jsonEncode(updatedList.map((e) => e.toJson()).toList());
                      },
                      onSubmit: (List<CheckListItemModel> updatedList) {
                        _currentChecklist = updatedList;
                        _highlightedContentController.text = jsonEncode(updatedList.map((e) => e.toJson()).toList());
                      },
                    );
                  },
                ),
              )
            : TextField(
                controller: _highlightedContentController,
                undoController: _undoController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(leftPadding, 8, rightPadding, 32),
                  hintText: 'Type here...',
                ),
              ),
      ),
    );
  }
}
