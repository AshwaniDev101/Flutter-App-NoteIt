import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/database/drift/local_database.dart';

import '../../../../shared/widgets/snack_bar_manager.dart';
import '../../../home/core/providers.dart';
import '../../../unlock/lock_manger/lock_manager.dart';
import '../../../unlock/view/setup_password_page.dart';
import '../view_model/edit_note_view_model.dart';

class DesktopEditNotePage extends ConsumerStatefulWidget {
  final Note? existingNote;

  const DesktopEditNotePage({super.key, this.existingNote});

  @override
  ConsumerState<DesktopEditNotePage> createState() => _DesktopEditNotePageState();
}

class _DesktopEditNotePageState extends ConsumerState<DesktopEditNotePage> {

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final UndoHistoryController _undoController = UndoHistoryController();

  late final EditNoteViewModel _viewModel;


  bool _isAutoSyncingTitle = false;
  late bool _isLocked;
  // bool _hasTriggeredFinalSave = false;
  bool _hasCreatedNewNote = false;
  Timer? _autoSaveTimer;
  bool _isDeleted = false;
  bool _isSaved = true;


  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  bool get _isNewNote =>
      widget.existingNote == null ||
          (widget.existingNote!.title.isEmpty &&
              widget.existingNote!.content.isEmpty &&
              widget.existingNote!.cloudSyncStatus == 0 &&
              widget.existingNote!.localSyncStatus == 0);

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(editNoteViewModelProvider.notifier);
    _isLocked = widget.existingNote?.isLocked ?? false;

    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');

    _titleFocusNode = FocusNode()..addListener(() => setState(() {}));
    _contentFocusNode = FocusNode();

    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      _isAutoSyncingTitle = false;
    }

    _contentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);

    // used for saving changes to the note automatically
    _titleController.addListener(_scheduleAutoSave);
    _contentController.addListener(_scheduleAutoSave);
  }

  void _scheduleAutoSave() {

    // Hide the "Saved" text the moment they start typing
    if (_isSaved && mounted) {
      setState(() => _isSaved = false);
    }

    // If the user is still typing, cancel the previous countdown
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();

    // Start a new 1-second countdown
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _executeSave(); // Silently save in the background
    });
  }

  void _syncTitleFromContent() {
    if (!_isAutoSyncingTitle) return;

    String firstLine = _contentController.text.isNotEmpty ? _contentController.text.split('\n').first : '';


    // FIX: Restrict to exactly 30 characters maximum
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

  void _onTitleChanged() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      // Calculate what the auto-sync text should look like right now
      String expectedSync = _contentController.text.isNotEmpty ? _contentController.text.split('\n').first : '';
      if (expectedSync.length > 30) expectedSync = expectedSync.substring(0, 30);

      // If the actual title text doesn't match the expected sync text,
      // it means the user manually typed in the title field. Turn off auto-sync!
      if (_titleController.text != expectedSync) {
        _isAutoSyncingTitle = false;
      }
    }
  }

  @override
  void dispose() {
    // Cancel the auto-save timer
    _autoSaveTimer?.cancel();

    // Grab the exact text before the controllers are destroyed
    final finalTitle = _titleController.text;
    final finalContent = _contentController.text;

    // Push the final DB save to the next event loop, completely escaping Flutter's widget teardown cycle!
    Future(() {
      _executeSave(
        isManualSave: false,
        isDisposing: true,
        overrideTitle: finalTitle,
        overrideContent: finalContent,
      );
    });

    // Clean up listeners and controllers
    _contentController.removeListener(_syncTitleFromContent);
    _titleController.removeListener(_onTitleChanged);
    _titleController.removeListener(_scheduleAutoSave);
    _contentController.removeListener(_scheduleAutoSave);

    _titleFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _executeSave({
    bool isManualSave = false,
    bool isDisposing = false,
    String? overrideTitle,
    String? overrideContent,
  }) {
    if (_isDeleted) return;

    // Use the overrides if we are disposing, otherwise read directly from controllers
    final title = (overrideTitle ?? _titleController.text).trim();
    final content = (overrideContent ?? _contentController.text).trim();

    if (title.isEmpty && content.isEmpty) return;

    if (_isNewNote) {
      if (_hasCreatedNewNote) return;
      _viewModel.saveNote(title, content);
      // Don't update local variables if the widget is already dead
      if (!isDisposing) _hasCreatedNewNote = true;
    } else {
      if (title != widget.existingNote!.title || content != widget.existingNote!.content) {
        _viewModel.updateNote(widget.existingNote!.uuid, title, content);
      }
    }

    // Only touch setState if we are 100% sure the widget is alive and not disposing
    if (!isDisposing && mounted) {
      setState(() => _isSaved = true);

      if (isManualSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
        );
      }
    }
  }

  String _getFormattedDate() {
    final now = widget.existingNote?.updatedAt ?? widget.existingNote?.createdAt ?? DateTime.now();
    return _isNewNote
        ? "${now.month}/${now.day}/${now.year}"
        : "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {

    final panelColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        child: Scaffold(
          backgroundColor: panelColor,
          appBar: AppBar(
            backgroundColor: panelColor,
            automaticallyImplyLeading: false,
            titleSpacing: 8,
            // titleSpacing: 24,
            title: _buildTitleField(maxWidth: 300),
            actions: [
              _buildUndoRedoButtons(),
              const SizedBox(width: 8),
              _buildDesktopOptionButtons(),
            ],
          ),
          body: Column(
            children: [
              _buildMetaDataRow(padding: 24.0),
              Expanded(child: _buildContentField(padding: 24.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField({double? maxWidth}) {
    return Row(
      children: [
        Flexible(
          child: Container(
            height: 40,
            constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
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

        // Auto save indicator
        AnimatedOpacity(
          opacity: _isSaved ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 100),
          child: Row(
            children: [
              Icon(
                Icons.cloud_done_outlined, // Cute cloud checkmark
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
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
        ),

        // const SizedBox(width: 16),
        // Desktop always shows the save button inline
        // TextButton.icon(
        //   onPressed: () => _executeSave(isManualSave: true),
        //   icon: const Icon(Icons.save),
        //   label: const Text("Save"),
        // ),
      ],
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
          child: TextField(
            controller: _contentController,
            undoController: _undoController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: InputBorder.none),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaDataRow({required double padding}) {
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
          const Spacer(),
          if (_isLocked) ...[
            const Icon(Icons.lock_outline, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
              _getFormattedDate(),
              style: Theme.of(context).textTheme.bodySmall
          ),
        ],
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
          builder: (context, value, child) => IconButton(
            onPressed: value.canUndo ? () => _undoController.undo() : null,
            icon: const Icon(Icons.undo, size: 20),
          ),
        ),
        ValueListenableBuilder<UndoHistoryValue>(
          valueListenable: _undoController,
          builder: (context, value, child) => IconButton(
            onPressed: value.canRedo ? () => _undoController.redo() : null,
            icon: const Icon(Icons.redo, size: 20),
          ),
        ),
      ],
    );
  }

  /// Displays actions inline on the Desktop App Bar.
  Widget _buildDesktopOptionButtons() {
    return FocusTraversalOrder(
      order: const NumericFocusOrder(6),
      child: Row(
        children: [
          IconButton(
            tooltip: widget.existingNote?.isPinned == true ? 'Unpin Note' : 'Pin Note',
            icon: Icon(
              widget.existingNote?.isPinned == true ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            onPressed: () {
              // TODO: Add pin toggle logic here
            },
          ),

          IconButton(
            tooltip: _isLocked ? 'Remove Lock' : 'Lock Note',
            icon: Icon(_isLocked ? Icons.lock_clock_outlined : Icons.lock_outline),
            onPressed: _handleLockToggle,
          ),

          IconButton(
            tooltip: 'Delete Note',
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleDeleteNote,
          ),
          IconButton(
            tooltip: 'Close Note',
            icon: const Icon(Icons.close_outlined),
            onPressed: _handleCloseNote,
          ),
        ],
      ),
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

    if (shouldProceed && widget.existingNote != null) {
      final success = await lockManager.togglePersistentLock(
        widget.existingNote!.uuid,
        '',
        shouldLock: !isCurrentlyLocked,
        ignorePassword: true,
      );

      if (success) {
        if (mounted) {
          setState(() => _isLocked = !_isLocked);
        }

        // If we are unlocking (!isCurrentlyLocked == false), Notes it stays open!
        if (!isCurrentlyLocked) {
          _handleCloseNote();
        }

      } else {
        if (mounted) SnackBarManager.show(msg: 'Action failed');
      }
    }
  }
  void _handleCloseNote() {
    // send signal the parent class to pop the note
    ref.read(activeNoteProvider.notifier).clear();

    // Pop if opened via router/mobile
    if (context.canPop()) context.pop();
  }
  void _handleDeleteNote() {
    if (!_isNewNote && widget.existingNote != null) {

      _isDeleted = true;
      // _hasTriggeredFinalSave = true;
      ref.read(editNoteViewModelProvider.notifier).deleteNote(widget.existingNote!.uuid);
    }
    _handleCloseNote();
  }
}