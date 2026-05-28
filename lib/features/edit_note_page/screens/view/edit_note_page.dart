import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/edit_note_page/screens/view_model/edit_note_view_model.dart';
import 'package:noteit/models/note_model.dart';

import '../../../../shared/snack_bar_manager.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final NoteModel? note;

  const EditNotePage({this.note, super.key});

  @override
  ConsumerState<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends ConsumerState<EditNotePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(editNoteViewModelProvider);
    final viewModel = ref.read(editNoteViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !viewModelState.isEditing,
      onPopInvokedWithResult: (bool didPop, result) async {
        if (didPop) return;

        if (viewModelState.isEditing) {
          _saveNote(viewModel);
          viewModel.setEditing(false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (viewModelState.isEditing) {
                            _saveNote(viewModel);
                            viewModel.setEditing(false);
                          } else if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(viewModelState.isEditing ? Icons.check : Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          readOnly: !viewModelState.isEditing,
                          controller: titleController,
                          onTap: () {
                            if (!viewModelState.isEditing) viewModel.setEditing(true);
                          },
                          decoration: const InputDecoration(
                            hintText: "Title",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (String value) {
                          if (value == 'toggle_lock' && widget.note != null) {
                            bool isCurrentlyLocked = widget.note!.isLocked;
                            viewModel.lockNote(widget.note!.id, isLocked: !isCurrentlyLocked);

                            if (!isCurrentlyLocked) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          bool isLocked = widget.note?.isLocked ?? false;
                          return [
                            PopupMenuItem<String>(
                              value: 'toggle_lock',
                              child: Row(
                                children: [
                                  Icon(isLocked ? Icons.lock_open : Icons.lock_outline, size: 20),
                                  const SizedBox(width: 12),
                                  Text(isLocked ? 'Unlock Note' : 'Lock Note'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: viewModelState.isEditing
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          viewModelState.isEditing ? "Editing" : "Saved",
                          style: textTheme.labelSmall?.copyWith(
                            color: viewModelState.isEditing
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getFormattedDate(),
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: TextField(
                      readOnly: !viewModelState.isEditing,
                      controller: contentController,
                      undoController: _undoController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onTap: () {
                        if (!viewModelState.isEditing) viewModel.setEditing(true);
                      },
                      decoration: const InputDecoration(
                        hintText: "Start writing your note...",
                        border: InputBorder.none,
                      ),
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ),

                if (viewModelState.isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                    ),
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
                        const SizedBox(width: 16),
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
      ),
    );
  }

  Future<void> _saveNote(EditNoteViewModel viewModel) async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty && widget.note == null) {
      return;
    }

    if (widget.note != null) {
      await viewModel.updateNote(widget.note!.id, title, content);
    } else {
      await viewModel.saveNote(title, content);
    }

    if (mounted) {
      final state = ref.read(editNoteViewModelProvider);
      if (state.error != null) {
        SnackBarManager.show(msg: "Error saving note: ${state.error}");
      } else {
        SnackBarManager.show(msg: "Note Saved");
      }
    }
  }
}