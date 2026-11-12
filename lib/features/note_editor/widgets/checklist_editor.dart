import 'package:flutter/material.dart';

class CheckListItemModel {
  final String id;
  final String text;
  final bool isChecked;

  CheckListItemModel({
    required this.id,
    required this.text,
    required this.isChecked,
  });

  factory CheckListItemModel.fromJson(Map<String, dynamic> json) {
    return CheckListItemModel(
      id: json['id'] as String? ?? UniqueKey().toString(),
      text: json['text'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
    };
  }
}

class ChecklistTextController extends TextEditingController {
  String _searchQuery = '';

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (_searchQuery.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final matches = _searchQuery.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final highlightStyle = TextStyle(
      backgroundColor: colorScheme.secondaryContainer,
      color: colorScheme.onSecondaryContainer,
    );

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.merge(highlightStyle) ?? highlightStyle,
      ));
      currentIndex = match.end;
    }
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return TextSpan(style: style, children: spans);
  }
}

class ChecklistItemController {
  final String id;
  final ChecklistTextController textController;
  final FocusNode focusNode;
  bool isChecked;

  ChecklistItemController({
    required this.id,
    required String text,
    this.isChecked = false,
  })  : textController = ChecklistTextController()..text = text,
        focusNode = FocusNode();

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }
}

class CheckListWidget extends StatefulWidget {
  final List<CheckListItemModel> initialData;
  final ValueChanged<List<CheckListItemModel>>? onChange;
  final ValueChanged<List<CheckListItemModel>>? onSubmit;
  final String searchQuery;

  const CheckListWidget({
    super.key,
    required this.initialData,
    this.onChange,
    this.onSubmit,
    this.searchQuery = '',
  });

  @override
  State<CheckListWidget> createState() => _CheckListWidgetState();
}

class _CheckListWidgetState extends State<CheckListWidget> {
  late List<ChecklistItemController> fieldItems;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    fieldItems = widget.initialData
        .map((item) => ChecklistItemController(
              id: item.id,
              text: item.text,
              isChecked: item.isChecked,
            ))
        .toList();
    _updateSearchQuery();
  }

  @override
  void didUpdateWidget(CheckListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _updateSearchQuery();
    }
  }

  void _updateSearchQuery() {
    for (var item in fieldItems) {
      item.textController.setSearchQuery(widget.searchQuery);
    }
  }

  @override
  void dispose() {
    for (var item in fieldItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    final updatedData = fieldItems
        .map((item) => CheckListItemModel(
              id: item.id,
              text: item.textController.text,
              isChecked: item.isChecked,
            ))
        .toList();
    widget.onChange?.call(updatedData);
  }

  void _addItem() {
    final newItem = ChecklistItemController(
      id: UniqueKey().toString(),
      text: '',
    );

    setState(() {
      fieldItems.add(newItem);
    });

    _notifyChange();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        newItem.focusNode.requestFocus();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      final removed = fieldItems.removeAt(index);
      removed.dispose();
    });
    _notifyChange();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = fieldItems.removeAt(oldIndex);
      fieldItems.insert(newIndex, item);
    });
    _notifyChange();
  }

  void _editList() {
    setState(() {
      _isEditing = true;
    });
  }

  void _doneEditing() {
    setState(() {
      _isEditing = false;
    });
    final updatedData = fieldItems
        .map((item) => CheckListItemModel(
              id: item.id,
              text: item.textController.text,
              isChecked: item.isChecked,
            ))
        .toList();
    widget.onSubmit?.call(updatedData);
  }

  Widget _buildHighlightedText(BuildContext context, String text, String searchQuery, TextStyle style) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final matches = searchQuery.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final highlightStyle = TextStyle(
      backgroundColor: colorScheme.secondaryContainer,
      color: colorScheme.onSecondaryContainer,
    );

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.merge(highlightStyle),
      ));
      currentIndex = match.end;
    }
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isEditing) {
      return InkWell(
        onTap: _editList,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fieldItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Empty checklist. Tap to edit.", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),

              ...fieldItems.map((item) => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: item.isChecked,
                    onChanged: (bool? newValue) {
                      setState(() {
                        item.isChecked = newValue ?? false;
                      });
                      _notifyChange();
                    },
                  ),
                  Expanded(
                    child: _buildHighlightedText(
                      context,
                      item.textController.text.trim(),
                      widget.searchQuery,
                      TextStyle(
                        fontSize: 16,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _doneEditing,
              child: const Text("Done"),
            ),
          ],
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fieldItems.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final item = fieldItems[index];
            return ReorderableChecklistTile(
              key: ValueKey(item.id),
              index: index,
              controller: item.textController,
              focusNode: item.focusNode,
              onClose: () => _removeItem(index),
            );
          },
        ),
        DummyChecklistTile(
          hintText: "Add item",
          onTap: _addItem,
        ),
      ],
    );
  }
}

class ReorderableChecklistTile extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;

  const ReorderableChecklistTile({
    super.key,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
              child: Icon(Icons.drag_indicator_rounded, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: "Type an item...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class DummyChecklistTile extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;

  const DummyChecklistTile({
    super.key,
    required this.hintText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
              child: Icon(Icons.add, color: colorScheme.primary),
            ),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
