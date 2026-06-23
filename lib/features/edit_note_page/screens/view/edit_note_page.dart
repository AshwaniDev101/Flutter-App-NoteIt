import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:noteit/shared/snack_bar_manager.dart';
import '../../../../database/drift/drift_database.dart';
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
  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    // Show updated time if it exists, otherwise fallback to creation time or current time
    final now = widget.existingNote?.updatedAt ?? widget.existingNote?.createdAt ?? DateTime.now();
    return "${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _saveAndExit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Prevent saving completely empty ghost notes
    if (title.isEmpty && content.isEmpty) {
      if (context.mounted) context.pop();
      return;
    }

    final viewModel = ref.read(editNoteViewModelProvider.notifier);

    // Execute Save or Update
    if (widget.existingNote == null) {
      await viewModel.saveNote(title, content);
    } else {
      // Efficiency check: Only run the update if the user actually changed the text
      if (title != widget.existingNote!.title || content != widget.existingNote!.content) {
        await viewModel.updateNote(widget.existingNote!.id, title, content);
      }
    }

    // Verify state and handle navigation or error reporting
    final state = ref.read(editNoteViewModelProvider);

    if (state.error != null) {
      SnackBarManager.show(msg: 'Failed to save note: ${state.error}');
    } else {
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await _saveAndExit();
            },
          ),
          actions: [
            if (widget.existingNote != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (String value) {
                  if (value == 'toggle_lock') {
                    bool isCurrentlyLocked = widget.existingNote!.isLocked;
                    ref.read(editNoteViewModelProvider.notifier).lockNote(
                      widget.existingNote!.id,
                      isLocked: !isCurrentlyLocked,
                    );

                    if (!isCurrentlyLocked) {
                      context.pop();
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  bool isLocked = widget.existingNote?.isLocked ?? false;
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
        body: SafeArea(
          child: Column(
            children: [
              // Meta Row: Date and Undo/Redo controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getFormattedDate(),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<UndoHistoryValue>(
                          valueListenable: _undoController,
                          builder: (context, value, child) {
                            return IconButton(
                              onPressed: value.canUndo ? () => _undoController.undo() : null,
                              icon: const Icon(Icons.undo, size: 20),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Undo',
                            );
                          },
                        ),
                        ValueListenableBuilder<UndoHistoryValue>(
                          valueListenable: _undoController,
                          builder: (context, value, child) {
                            return IconButton(
                              onPressed: value.canRedo ? () => _undoController.redo() : null,
                              icon: const Icon(Icons.redo, size: 20),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Redo',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Title Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Title",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              // Content Field
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: _contentController,
                    undoController: _undoController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: "Start writing your note...",
                      border: InputBorder.none,
                    ),
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}