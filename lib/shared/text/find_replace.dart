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
  List<int> _matchIndices = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _findController = TextEditingController();
    _replaceController = TextEditingController();
    _findFocusNode = FocusNode();

    // Wire the find text directly to the highlighter and match counter
    _findController.addListener(_onFindTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _findFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _findController.removeListener(_onFindTextChanged);
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _onFindTextChanged() {
    widget.contentController.searchQuery = _findController.text;
    _updateMatches(autoSelectFirst: true);
  }

  void _updateMatches({bool autoSelectFirst = false}) {
    final query = _findController.text;
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _matchIndices = [];
          _currentMatchIndex = -1;
        });
      }
      widget.contentController.setActiveMatch(-1);
      return;
    }

    final content = widget.contentController.text;
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    List<int> matches = [];
    int start = 0;
    while (start < content.length) {
      int idx = contentLower.indexOf(queryLower, start);
      if (idx == -1) break;
      matches.add(idx);
      start = idx + query.length;
      if (query.isEmpty) break;
    }

    int nextIndex = -1;
    if (matches.isNotEmpty) {
      if (autoSelectFirst) {
        nextIndex = 0;
      } else if (_currentMatchIndex >= 0 && _currentMatchIndex < matches.length) {
        nextIndex = _currentMatchIndex;
      } else {
        nextIndex = 0;
      }
    }

    if (mounted) {
      setState(() {
        _matchIndices = matches;
        _currentMatchIndex = nextIndex;
      });
    }

    if (nextIndex >= 0 && nextIndex < matches.length) {
      final activeOffset = matches[nextIndex];
      widget.contentController.setActiveMatch(activeOffset);
      if (autoSelectFirst) {
        widget.contentController.selection = TextSelection(
          baseOffset: activeOffset,
          extentOffset: activeOffset + query.length,
        );
      }
    } else {
      widget.contentController.setActiveMatch(-1);
    }
  }

  void _findNext() {
    final query = _findController.text;
    if (query.isEmpty) return;

    _updateMatches(autoSelectFirst: false);

    if (_matchIndices.isEmpty) {
      SnackBarManager.show(
        msg: 'No matches found',
        type: SnackBarMessageType.acknowledgment,
      );
      return;
    }

    int nextMatchIdx = _currentMatchIndex + 1;
    if (nextMatchIdx >= _matchIndices.length) {
      nextMatchIdx = 0; // Wrap around to first match
    }

    final matchIndex = _matchIndices[nextMatchIdx];

    setState(() {
      _currentMatchIndex = nextMatchIdx;
    });

    widget.contentController.selection = TextSelection(
      baseOffset: matchIndex,
      extentOffset: matchIndex + query.length,
    );
    widget.contentController.setActiveMatch(matchIndex);
    widget.contentFocusNode.requestFocus();
  }

  void _findPrevious() {
    final query = _findController.text;
    if (query.isEmpty) return;

    _updateMatches(autoSelectFirst: false);

    if (_matchIndices.isEmpty) {
      SnackBarManager.show(
        msg: 'No matches found',
        type: SnackBarMessageType.acknowledgment,
      );
      return;
    }

    int prevMatchIdx = _currentMatchIndex - 1;
    if (prevMatchIdx < 0) {
      prevMatchIdx = _matchIndices.length - 1; // Wrap around to last match
    }

    final matchIndex = _matchIndices[prevMatchIdx];

    setState(() {
      _currentMatchIndex = prevMatchIdx;
    });

    widget.contentController.selection = TextSelection(
      baseOffset: matchIndex,
      extentOffset: matchIndex + query.length,
    );
    widget.contentController.setActiveMatch(matchIndex);
    widget.contentFocusNode.requestFocus();
  }

  void _replace() {
    final query = _findController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;
    final selection = widget.contentController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = content.substring(selection.baseOffset, selection.extentOffset);

      if (selectedText.toLowerCase() == query.toLowerCase()) {
        final newContent = content.replaceRange(selection.baseOffset, selection.extentOffset, replaceText);

        widget.contentController.value = TextEditingValue(
          text: newContent,
          selection: TextSelection.collapsed(offset: selection.baseOffset + replaceText.length),
        );

        _updateMatches(autoSelectFirst: false);
        _findNext();
        return;
      }
    }

    _findNext();
  }

  void _replaceAll() {
    final query = _findController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    final content = widget.contentController.text;

    final regex = RegExp(RegExp.escape(query), caseSensitive: false);
    final newContent = content.replaceAll(regex, replaceText);

    if (content != newContent) {
      widget.contentController.value = TextEditingValue(
        text: newContent,
        selection: const TextSelection.collapsed(offset: 0),
      );

      _updateMatches(autoSelectFirst: true);

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

  Widget _buildMatchCounter(ColorScheme colorScheme) {
    final query = _findController.text;
    if (query.isEmpty) return const SizedBox.shrink();

    final text = _matchIndices.isNotEmpty
        ? '${_currentMatchIndex + 1}/${_matchIndices.length}'
        : '0/0';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        widthFactor: 1.0,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _matchIndices.isNotEmpty
                ? colorScheme.primary
                : colorScheme.error,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding, vertical: 8.0),
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
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
                      constraints: const BoxConstraints(),
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
                          suffixIcon: _buildMatchCounter(colorScheme),
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
                        widget.contentController.searchQuery = '';
                        widget.contentController.setActiveMatch(-1);
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
