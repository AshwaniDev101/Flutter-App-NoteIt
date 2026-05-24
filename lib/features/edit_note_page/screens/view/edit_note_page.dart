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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final viewModelState = ref.watch(editNoteViewModelProvider);
    final viewModel = ref.read(editNoteViewModelProvider.notifier);

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 6),

                Row(
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

                    const SizedBox(width: 4),

                    Expanded(
                      child: TextField(
                        readOnly: !viewModelState.isEditing,
                        controller: titleController,
                        onTap: () {
                          if (!viewModelState.isEditing) {
                            viewModel.setEditing(true);
                          }
                        },
                        decoration: const InputDecoration(hintText: "Title", border: InputBorder.none),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (String value) {
                        if (value == 'toggle_lock') {
                          if (widget.note != null) {
                            // Toggle the opposite of whatever the current state is
                            bool isCurrentlyLocked = widget.note!.isLocked;
                            viewModel.lockNote(widget.note!.id, isLocked: !isCurrentlyLocked);

                            if(!isCurrentlyLocked)
                              {
                                Navigator.of(context).pop();
                              }
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        // Determine the current state here
                        bool isLocked = widget.note?.isLocked ?? false;

                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'toggle_lock',
                            child: Row(
                              children: [
                                // Dynamically change the icon and text based on the lock state
                                Icon(isLocked ? Icons.lock_open : Icons.lock_outline, size: 20),
                                const SizedBox(width: 8),
                                Text(isLocked ? 'Unlock' : 'Lock'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),

                Row(
                  children: [
                    Text(viewModelState.isEditing ? "Editing" : "Saved", style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text("4/23/26 8:48 AM", style: TextStyle(fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: TextField(
                    readOnly: !viewModelState.isEditing,
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    onTap: () {
                      if (!viewModelState.isEditing) {
                        viewModel.setEditing(true);
                      }
                    },
                    decoration: const InputDecoration(hintText: "Start writing your note...", border: InputBorder.none),
                    style: TextStyle(fontSize: 15),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.undo)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.redo)),
                  ],
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

    if (title.isEmpty && content.isEmpty) {
      if (widget.note == null) {
        // Don't save empty new notes
        return;
      }
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

  String getLockLabel() {
    if (widget.note != null && widget.note!.isLocked) {
      return "Unlock";
    } else {
      return "Lock";
    }
  }
}
