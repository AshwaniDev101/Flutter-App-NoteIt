import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/database/drift/drift_database.dart';

import '../../../../shared/widgets/snack_bar_manager.dart';
import '../../../unlock/lock_manger/lock_manager.dart';
import '../../../unlock/view/setup_password_page.dart';
import '../view_model/edit_note_view_model.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final Note? existingNote;

  const EditNotePage({super.key, this.existingNote});

  @override
  ConsumerState<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends ConsumerState<EditNotePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocusNode;
  final UndoHistoryController _undoController = UndoHistoryController();
  late final EditNoteViewModel _viewModel;

  bool _isAutoSyncingTitle = false;
  late bool _isLocked;
  bool _hasTriggeredFinalSave = false;
  bool _hasCreatedNewNote = false;

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

    if (_titleController.text.isEmpty) _isAutoSyncingTitle = true;

    _contentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);
  }

  void _syncTitleFromContent() {
    if (!_isAutoSyncingTitle) return;
    final firstLine = _contentController.text.isNotEmpty ? _contentController.text.split('\n').first : '';
    if (_titleController.text != firstLine) {
      _titleController.value = _titleController.value.copyWith(
        text: firstLine,
        selection: TextSelection.collapsed(offset: firstLine.length),
      );
    }
  }

  void _onTitleChanged() {
    if (_titleController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      if (_titleController.text != _contentController.text.split('\n').first) _isAutoSyncingTitle = false;
    }
  }

  @override
  void dispose() {
    _executeSave(isManualSave: false);
    _contentController.removeListener(_syncTitleFromContent);
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _executeSave({bool isManualSave = false}) {
    if (_hasTriggeredFinalSave && !isManualSave) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    if (_isNewNote) {
      if (_hasCreatedNewNote) return; // Prevent duplicating the dummy note
      _viewModel.saveNote(title, content);
      _hasCreatedNewNote = true;
    } else {
      if (title != widget.existingNote!.title || content != widget.existingNote!.content) {
        _viewModel.updateNote(widget.existingNote!.uuid, title, content);
      }
    }

    if (isManualSave && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
      );
    }
    if (!isManualSave) _hasTriggeredFinalSave = true;
  }

  void _handleMobileBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    _executeSave(isManualSave: false);
    if (mounted) context.pop();
  }

  String _getFormattedDate() {
    final now = widget.existingNote?.updatedAt ?? widget.existingNote?.createdAt ?? DateTime.now();
    return _isNewNote
        ? "${now.month}/${now.day}/${now.year}"
        : "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !isDesktop) _handleMobileBack();
      },
      child: isDesktop ? _buildDesktopUI() : _buildMobileUI(),
    );
  }

  Widget _buildDesktopUI() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: _buildTitleField(colorScheme, textTheme, maxWidth: 300),
        actions: [_buildUndoRedoButtons(), if (!_isNewNote) _buildOptionMenu(), const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          _buildMetaDataRow(colorScheme, textTheme, padding: 24.0),
          Expanded(child: _buildContentField(textTheme, padding: 24.0)),
        ],
      ),
    );
  }

  Widget _buildMobileUI() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleMobileBack),
        titleSpacing: 0,
        title: _buildTitleField(colorScheme, textTheme, showSaveIcon: false),
        actions: [if (!_isNewNote) _buildOptionMenu(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMetaDataRow(colorScheme, textTheme, padding: 16.0),
            Expanded(child: _buildContentField(textTheme, padding: 16.0)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildUndoRedoButtons(isMobileView: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(ColorScheme colorScheme, TextTheme textTheme, {double? maxWidth, bool showSaveIcon = true}) {
    return Row(
      children: [
        Flexible(
          child: Container(
            height: 40,
            constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              textAlignVertical: TextAlignVertical.center,
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                hintText: "Title",
                suffixIcon: _titleFocusNode.hasFocus
                    ? ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
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
        if (showSaveIcon) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _executeSave(isManualSave: true),
            icon: Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            label: const Text("Save"),
          ),
        ],
      ],
    );
  }

  Widget _buildContentField(TextTheme textTheme, {required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
      child: TextField(
        controller: _contentController,
        undoController: _undoController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(border: InputBorder.none),
        style: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildMetaDataRow(ColorScheme colorScheme, TextTheme textTheme, {required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _isNewNote ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _isNewNote ? 'New' : 'Updating...',
              style: textTheme.labelSmall?.copyWith(
                color: _isNewNote ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (_isLocked) ...[
            Icon(Icons.lock_outline, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(_getFormattedDate(), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildUndoRedoButtons({bool isMobileView = false}) {
    return Row(
      mainAxisAlignment: isMobileView ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<UndoHistoryValue>(
          valueListenable: _undoController,
          builder: (context, value, child) => IconButton(
            onPressed: value.canUndo ? () => _undoController.undo() : null,
            style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            icon: Icon(Icons.undo, size: isMobileView ? 24 : 20),
          ),
        ),
        SizedBox(width: isMobileView ? 24 : 0),
        ValueListenableBuilder<UndoHistoryValue>(
          valueListenable: _undoController,
          builder: (context, value, child) => IconButton(
            onPressed: value.canRedo ? () => _undoController.redo() : null,
            style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            icon: Icon(Icons.redo, size: isMobileView ? 24 : 20),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionMenu() {
    return PopupMenuButton<String>(
      style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) async {
        if (value == 'toggle_lock') {
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

          if (shouldProceed) {
            final success = await lockManager.togglePersistentLock(
              widget.existingNote!.uuid,
              '',
              shouldLock: !isCurrentlyLocked,
              ignorePassword: true,
            );

            if (success) {
              if (mounted) {
                setState(() {
                  _isLocked = !_isLocked;
                });

                if (!isCurrentlyLocked && defaultTargetPlatform == TargetPlatform.android) {
                  context.pop();
                }
              }
            } else {
              if (mounted) SnackBarManager.show(msg: 'Action failed');
            }
          }
        } else if (value == 'delete') {
          if (!_isNewNote && widget.existingNote != null) {
            _hasTriggeredFinalSave = true;
            // FIXED: Passing UUID instead of integer ID
            ref.read(editNoteViewModelProvider.notifier).deleteNote(widget.existingNote!.uuid);
            if (defaultTargetPlatform == TargetPlatform.android && mounted) {
              context.pop();
            }
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 'toggle_lock',
            child: Row(
              children: [
                Icon(_isLocked ? Icons.lock_clock_outlined : Icons.lock_outline, size: 16),
                const SizedBox(width: 12),
                Text(_isLocked ? 'Remove Lock' : 'Lock Note'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                SizedBox(width: 12),
                Text('Delete Note', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
