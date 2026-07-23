import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/managers/lock_manger/lock_manager.dart';
import '../../../../shared/widgets/snack_bar_manager.dart';
import '../../../password_page/screens/view/password_page.dart';
import '../../../password_page/screens/view/setup_password_page.dart';
import '../view_model/edit_note_view_model.dart';
import 'package:noteit/database/drift/drift_database.dart';

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

  bool _isAutoSyncingTitle = false;

  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.existingNote?.isLocked ?? false;
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _titleFocusNode = FocusNode();

    // Force rebuild on focus state changes to toggle the visibility of the trailing 'X' and options menu
    _titleFocusNode.addListener(() {
      setState(() {});
    });

    if (_titleController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    }

    _contentController.addListener(_syncTitleFromContent);
    _titleController.addListener(_onTitleChanged);
  }

  void _syncTitleFromContent() {
    if (_isAutoSyncingTitle) {
      final contentText = _contentController.text;
      final firstLine = contentText.isNotEmpty ? contentText.split('\n').first : '';

      if (_titleController.text != firstLine) {
        _titleController.value = _titleController.value.copyWith(
          text: firstLine,
          selection: TextSelection.collapsed(offset: firstLine.length),
        );
      }
    }
  }

  void _onTitleChanged() {
    if (_titleController.text.isEmpty) {
      _isAutoSyncingTitle = true;
    } else {
      final firstLine = _contentController.text.split('\n').first;
      if (_titleController.text != firstLine) {
        _isAutoSyncingTitle = false;
      }
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_syncTitleFromContent);
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = widget.existingNote?.updatedAt ?? widget.existingNote?.createdAt ?? DateTime.now();

    if (widget.existingNote == null) {
      return "${now.month}/${now.day}/${now.year}";
    }

    return "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _saveAndExit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (context.mounted) context.pop();
      return;
    }

    final viewModel = ref.read(editNoteViewModelProvider.notifier);

    if (widget.existingNote == null) {
      await viewModel.saveNote(title, content);
    } else {
      if (title != widget.existingNote!.title || content != widget.existingNote!.content) {
        await viewModel.updateNote(widget.existingNote!.id, title, content);
      }
    }

    final state = ref.read(editNoteViewModelProvider);

    if (state.error != null) {
      SnackBarManager.show(msg: 'Failed to save note: ${state.error}');
    } else {
      if (context.mounted) {
        context.pop();
      }
    }
  }

  // Pop-up menu builder to reduce widget tree nesting in the main build method

  Widget _buildOptionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) async {
        if (value == 'toggle_lock') {
          bool isCurrentlyLocked = _isLocked;
          final lockManager = ref.read(lockManagerProvider.notifier);

          String? enteredPassword;
          bool shouldProceed = false;

          // Check if Master Password needs to be setup
          if (!lockManager.hasMasterPassword) {
            enteredPassword = await showGeneralDialog<String>(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black45,
              pageBuilder: (context, anim1, anim2) => const SetupPasswordPage(),
            );

            if (enteredPassword != null && enteredPassword.isNotEmpty) {
              await lockManager.setupMasterPassword(enteredPassword);
              if (context.mounted) {
                SnackBarManager.show(msg: 'Master Password Created!');
              }
              shouldProceed = true;
            }
          }
          // If we just want to LOCK the note, skip the password page
          else if (!isCurrentlyLocked) {
            enteredPassword = ''; // Pass an empty string since we are just locking
            shouldProceed = true;
          }
          // If we want to UNLOCK the note, ask for the password
          else {
            enteredPassword = await showGeneralDialog<String>(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black45,
              pageBuilder: (context, anim1, anim2) => const PasswordPage(),
            );

            if (enteredPassword != null && enteredPassword.isNotEmpty) {
              shouldProceed = true;
            }
          }

          // Proceed with locking/unlocking if authorized to do so
          if (shouldProceed) {
            final success = await lockManager.togglePersistentLock(
              widget.existingNote!.id,
              enteredPassword ?? '',
              shouldLock: !isCurrentlyLocked,
            );

            if (success) {
              if (context.mounted) {

                setState(() {
                  _isLocked = !_isLocked;
                });

                if(!isCurrentlyLocked){
                  context.pop();  // Kick them out of the editor if they just locked it
                }

              }
            } else {
              if (context.mounted) SnackBarManager.show(msg: 'Incorrect Password');
            }
          }
        }
        // Handle discard: immediately pop the route without triggering the save lifecycle
        else if (value == 'discard') {
          if (context.mounted) {
            context.pop();
          }
        }
        else if (value == 'delete') {
          if (widget.existingNote != null) {
            ref.read(editNoteViewModelProvider.notifier).deleteNote(widget.existingNote!.id);
            if (context.mounted) {
              context.pop();
            }
          }
        }
      },
      itemBuilder: (BuildContext context) {
        // bool isLocked = widget.existingNote?.isLocked ?? false;
        final colorScheme = Theme.of(context).colorScheme;

        return [
          PopupMenuItem<String>(
            value: 'toggle_lock',
            child: Row(
              children: [
                Icon(_isLocked ? Icons.lock_clock_outlined: Icons.lock_outline, size: 20),
                const SizedBox(width: 12),
                Text(_isLocked ? 'Remove Lock' : 'Lock Note'),
              ],
            ),
          ),

          // Discard action
          PopupMenuItem<String>(
            value: 'discard',
            child: Row(
              children: [
                Icon(Icons.close, size: 20, color: colorScheme.onSurface),
                const SizedBox(width: 12),
                Text(
                  'Discard Changes',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),

          // Delete action
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                SizedBox(width: 12),
                Text(
                  'Delete Note',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isNewNote = widget.existingNote == null;
    // bool isLocked = widget.existingNote?.isLocked ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndExit();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await _saveAndExit();
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [

              Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    // Forces the text to align vertically in the absolute center of the available space
                    textAlignVertical: TextAlignVertical.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      // Removes default Material padding so the centering algorithm works accurately
                      isDense: true,
                      hintText: "Title",
                      hintStyle: textTheme.titleMedium?.copyWith(color: Colors.black38),
                      border: InputBorder.none,
                      // Removed vertical padding, relying entirely on textAlignVertical for Y-axis alignment
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      suffixIcon: _titleFocusNode.hasFocus
                          ? ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
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

              // Options menu
              if (!isNewNote) ...[
                _buildOptionMenu(),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metadata header: Trailing alignment for timestamp and state indicator
              Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18.0,),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isNewNote ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNewNote ? 'New' : 'Updating...',
                        style: textTheme.labelSmall?.copyWith(
                          color: isNewNote ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if(_isLocked)
                      Icon(Icons.lock_outline, size: 16, color: colorScheme.onSurfaceVariant),
                      SizedBox(width: 10,),
                    Text(
                      _getFormattedDate(),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Primary editor canvas leveraging CustomPaint for dynamic gridline rendering
              Expanded(
                child: CustomPaint(
                  // painter: NotebookLinesPainter(
                  //   // Exact calculation: fontSize (18) * height (1.6) = 28.8
                  //   lineHeight: 28.8,
                  //   lineColor: colorScheme.primary.withValues(alpha: 0.08),
                  //   // Exact calculation: Container top padding (16.0) + lineHeight (28.8) = 44.8
                  //   // This forces the very first drawn line to sit underneath the first line of text
                  //   topPadding: 44.8,
                  // ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                    child: TextField(
                      controller: _contentController,
                      undoController: _undoController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),

              // Editor tool palette: Embedded in body layout to persist above the virtual keyboard inset
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder<UndoHistoryValue>(
                      valueListenable: _undoController,
                      builder: (context, value, child) {
                        return IconButton(
                          onPressed: value.canUndo ? () => _undoController.undo() : null,
                          icon: const Icon(Icons.undo),
                          tooltip: 'Undo',
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    ValueListenableBuilder<UndoHistoryValue>(
                      valueListenable: _undoController,
                      builder: (context, value, child) {
                        return IconButton(
                          onPressed: value.canRedo ? () => _undoController.redo() : null,
                          icon: const Icon(Icons.redo),
                          tooltip: 'Redo',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Low-level painter implementation for ruled canvas lines
class NotebookLinesPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;
  final double topPadding;

  NotebookLinesPainter({
    required this.lineHeight,
    required this.lineColor,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    double y = topPadding;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight; // Uniformly steps down based on calculated text bounds
    }
  }

  @override
  bool shouldRepaint(covariant NotebookLinesPainter oldDelegate) {
    return oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.topPadding != topPadding;
  }
}