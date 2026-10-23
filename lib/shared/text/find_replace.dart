import 'package:flutter/material.dart';

import '../overlays/snack_bar_manager.dart';
import 'highlighting_text_field.dart';

class FindReplaceWidget extends StatefulWidget {
  final HighlightingTextField contentController;
  final FocusNode contentFocusNode;
  final VoidCallback onClose;
  final double padding;

  const FindReplaceWidget({
    super.key,
    required this.contentController,
    required this.contentFocusNode,
    required this.onClose,
    this.padding = 0,
  });

  @override
  State<FindReplaceWidget> createState() => _FindReplaceWidgetState();
}

class _FindReplaceWidgetState extends State<FindReplaceWidget> {
  late final TextEditingController _findController;
  late final TextEditingController _replaceController;
  late final FocusNode _findFocusNode;

  bool _isReplace = false;

  @override
  void initState() {
    super.initState();
    _findController = TextEditingController();
    _replaceController = TextEditingController();
    _findFocusNode = FocusNode();

    // Wire the find text directly to the highlighter
    _findController.addListener(() {
      widget.contentController.searchQuery = _findController.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _findFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // widget.contentController.searchQuery = '';
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _findNext() {
    final query = _findController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;
    if (content.isEmpty) return;

    // Use lowercase for case-insensitive search to match your HighlightingTextEditingController
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    // Get the current cursor position (end of current selection)
    int startIndex = 0;
    if (widget.contentController.selection.isValid) {
      startIndex = widget.contentController.selection.extentOffset;
      // Safety check in case the selection is invalid (-1)
      if (startIndex < 0) startIndex = 0;
    }

    // 1. Search for the next occurrence AFTER the current cursor position
    int matchIndex = contentLower.indexOf(queryLower, startIndex);

    // 2. If not found, wrap around to the top of the document and search again
    if (matchIndex == -1 && startIndex > 0) {
      matchIndex = contentLower.indexOf(queryLower, 0);
    }

    // 3. If a match is found, select it
    if (matchIndex != -1) {
      // Update the selection to highlight the exact matched text
      widget.contentController.selection = TextSelection(
        baseOffset: matchIndex,
        extentOffset: matchIndex + query.length,
      );

      // Request focus to ensure the TextField scrolls to the highlighted selection
      widget.contentFocusNode.requestFocus();
    } else {
      // Notify the user if no matches were found anywhere
      SnackBarManager.show(
        msg: 'No matches found',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  void _findPrevious() {
    final query = _findController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;
    if (content.isEmpty) return;

    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    // Get the start of the current selection so we search backwards from there
    int startIndex = content.length;
    if (widget.contentController.selection.isValid) {
      startIndex = widget.contentController.selection.baseOffset;
      if (startIndex < 0) startIndex = content.length;
    }

    // `lastIndexOf` searches backwards from the given index
    // We subtract 1 from startIndex so we don't just find the currently selected word again
    int matchIndex = contentLower.lastIndexOf(queryLower, startIndex - 1);

    // If not found, wrap around to the very bottom of the document
    if (matchIndex == -1) {
      matchIndex = contentLower.lastIndexOf(queryLower, content.length);
    }

    if (matchIndex != -1) {
      widget.contentController.selection = TextSelection(
        baseOffset: matchIndex,
        extentOffset: matchIndex + query.length,
      );
      widget.contentFocusNode.requestFocus();
    } else {
      SnackBarManager.show(
        msg: 'No matches found',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  void _replace() {
    final query = _findController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;
    final selection = widget.contentController.selection;

    // 1. Check if there is an active selection in the text field
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = content.substring(selection.baseOffset, selection.extentOffset);

      // 2. Case-insensitive check to see if the highlighted text is our search query
      if (selectedText.toLowerCase() == query.toLowerCase()) {
        // 3. Replace just that specific highlighted range
        final newContent = content.replaceRange(selection.baseOffset, selection.extentOffset, replaceText);

        // 4. Update the controller with the new text and put the cursor right after the replaced text
        widget.contentController.value = TextEditingValue(
          text: newContent,
          selection: TextSelection.collapsed(offset: selection.baseOffset + replaceText.length),
        );

        // 5. Automatically jump to highlight the next occurrence
        _findNext();
        return;
      }
    }

    // If nothing was selected or the selection didn't match the query,
    // we assume the user just wants to find the first occurrence to prepare for replacing.
    _findNext();
  }

  void _replaceAll() {
    final query = _findController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;

    // We use a RegExp here to ensure the "Replace All" is case-insensitive,
    // which matches the behavior of your custom highlighting and _findNext.
    // RegExp.escape prevents crashes if the user searches for characters like * or [
    final regex = RegExp(RegExp.escape(query), caseSensitive: false);

    final newContent = content.replaceAll(regex, replaceText);

    if (content != newContent) {
      widget.contentController.value = TextEditingValue(
        text: newContent,
        // Reset the cursor to the beginning after a mass replacement
        selection: const TextSelection.collapsed(offset: 0),
      );

      SnackBarManager.show(
        msg: 'All occurrences replaced',
        type: SnackBarMessageType.acknowledgment,
      );
    } else {
      SnackBarManager.show(
        msg: 'No matches found to replace',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding, vertical: 8.0),
      child: Align(
        // Aligns the search bar to the right side of the editor
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          // Prevents the bar from stretching endlessly on wide monitors
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- FIND ROW ---
                Row(
                  children: [
                    // Toggle Replace arrow
                    IconButton(
                      icon: Icon(
                        _isReplace ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      splashRadius: 20,
                      constraints: const BoxConstraints(), // Removes default huge padding
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Toggle Replace',
                      onPressed: () {
                        setState(() {
                          _isReplace = !_isReplace;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Find Input
                    Expanded(
                      child: TextField(
                        controller: _findController,
                        focusNode: _findFocusNode,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Find',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _findNext(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Navigation and Close Actions
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Previous Match',
                      onPressed: _findPrevious,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Next Match',
                      onPressed: _findNext,
                    ),
                    Container(
                        width: 1,
                        height: 16,
                        color: colorScheme.outlineVariant,
                        margin: const EdgeInsets.symmetric(horizontal: 6)
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Close',
                      onPressed: () {
                        // lear highlights safely during the button press
                        widget.contentController.searchQuery = '';
                        //  Tell the parent to remove the widget
                        widget.onClose();
                      },
                    ),
                  ],
                ),

                // --- REPLACE ROW ---
                if (_isReplace) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Perfectly aligns the Replace text field under the Find text field
                      const SizedBox(width: 44),

                      // Replace Input
                      Expanded(
                        child: TextField(
                          controller: _replaceController,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Replace',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Replace Actions
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _replace,
                        child: const Text('Replace'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _replaceAll,
                        child: const Text('All'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
