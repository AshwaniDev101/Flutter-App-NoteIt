import 'package:flutter/material.dart';

// ==========================================
// PURE DATA MODEL (For JSON / Database)
// ==========================================
class CheckListItemModel {
  final String id;
  final String text;
  final bool isChecked;

  CheckListItemModel({
    required this.id,
    required this.text,
    required this.isChecked,
  });

  // Convert a single item TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
    };
  }

  // Convert a single item FROM JSON
  factory CheckListItemModel.fromJson(Map<String, dynamic> json) {
    return CheckListItemModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isChecked: json['isChecked'] as bool,
    );
  }
}

// ==========================================
// UI STATE MODEL (For Controllers/Focus)
// ==========================================

// Custom controller to highlight text while in Edit Mode
class ChecklistTextController extends TextEditingController {
  String _searchQuery = '';

  ChecklistTextController({super.text});

  String get searchQuery => _searchQuery;

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
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

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.copyWith(backgroundColor: Colors.yellow.withValues(alpha: 0.5), color: Colors.black) ??
            const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
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

  ChecklistItemController({String? initialId, String text = '', this.isChecked = false})
      : id = initialId ?? UniqueKey().toString(),
        textController = ChecklistTextController(text: text),
        focusNode = FocusNode();

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }
}

// ==========================================
// THE WIDGET
// ==========================================
class CheckListWidget extends StatefulWidget {
  final List<CheckListItemModel>? initialData;
  final Function(List<CheckListItemModel>)? onChange;
  final Function(List<CheckListItemModel>)? onSubmit;
  final String searchQuery;

  const CheckListWidget({
    super.key,
    this.initialData,
    this.onChange,
    this.onSubmit,
    this.searchQuery = '',
  });

  @override
  State<CheckListWidget> createState() => _CheckListWidgetState();
}

class _CheckListWidgetState extends State<CheckListWidget> {
  final List<ChecklistItemController> fieldItems = [];
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _isEditing = false;
      for (var item in widget.initialData!) {
        final uiItem = ChecklistItemController(
          initialId: item.id,
          text: item.text,
          isChecked: item.isChecked,
        );
        uiItem.textController.searchQuery = widget.searchQuery;
        fieldItems.add(uiItem);
      }
    } else {
      _isEditing = true;
    }
  }

  // Pushes search updates down to the internal checklist fields
  @override
  void didUpdateWidget(CheckListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      for (var item in fieldItems) {
        item.textController.searchQuery = widget.searchQuery;
      }
    }
  }

  @override
  void dispose() {
    for (var item in fieldItems) {
      item.dispose();
    }
    super.dispose();
  }

  // Generates pure data from UI state
  List<CheckListItemModel> _generateExportData() {
    return fieldItems
        .where((item) => item.textController.text.trim().isNotEmpty)
        .map((item) => CheckListItemModel(
      id: item.id,
      text: item.textController.text.trim(),
      isChecked: item.isChecked,
    ))
        .toList();
  }

  void _notifyChange() {
    if (widget.onChange != null) {
      widget.onChange!(_generateExportData());
    }
  }

  void _addTopItem() {
    final newItem = ChecklistItemController();
    newItem.textController.searchQuery = widget.searchQuery;
    setState(() {
      fieldItems.insert(0, newItem);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newItem.focusNode.requestFocus();
    });
    _notifyChange();
  }

  void _addBottomItem() {
    final newItem = ChecklistItemController();
    newItem.textController.searchQuery = widget.searchQuery;
    setState(() {
      fieldItems.add(newItem);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newItem.focusNode.requestFocus();
    });
    _notifyChange();
  }

  void _removeItem(int index) {
    setState(() {
      final removedItem = fieldItems.removeAt(index);
      removedItem.dispose();
    });
    _notifyChange();
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = fieldItems.removeAt(oldIndex);
      fieldItems.insert(newIndex, item);
    });
    _notifyChange();
  }

  void _saveList() {
    setState(() {
      final emptyItems = fieldItems
          .where((item) => item.textController.text.trim().isEmpty)
          .toList();

      for (var item in emptyItems) {
        fieldItems.remove(item);
        item.dispose();
      }

      _isEditing = false;
    });

    if (widget.onSubmit != null) {
      widget.onSubmit!(_generateExportData());
    }
  }

  void _editList() {
    setState(() {
      _isEditing = true;
    });
  }

  // Custom renderer for highlighted text while in View Mode
  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) return Text(text, style: style);

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) return Text(text, style: style);

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.copyWith(backgroundColor: Colors.yellow.withValues(alpha: 0.5), color: Colors.black),
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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Empty checklist. Tap to edit.", style: TextStyle(color: Colors.grey)),
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
                      item.textController.text.trim(),
                      widget.searchQuery,
                      TextStyle(
                        fontSize: 16,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked ? Colors.grey : Colors.white,
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
        DummyChecklistTile(
          hintText: "Add item",
          onTap: _addTopItem,
        ),

        Flexible(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: fieldItems.length,
            onReorderItem: _onReorderItem,
            itemBuilder: (context, index) {
              final itemData = fieldItems[index];

              return ChecklistTile(
                key: ValueKey(itemData.id),
                index: index,
                controller: itemData.textController,
                focusNode: itemData.focusNode,
                onClose: () => _removeItem(index),
              );
            },
          ),
        ),

        DummyChecklistTile(
          hintText: "Add item",
          onTap: _addBottomItem,
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveList,
            child:const Text('Submit'),
          ),
        )
      ],
    );
  }
}

// --- Other Widgets ---
class ChecklistTile extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function() onClose;

  const ChecklistTile({
    super.key,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
              child: Icon(Icons.drag_indicator_rounded, color: Colors.grey),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 12.0),
              child: Icon(Icons.add, color: Colors.blue),
            ),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  color: Colors.grey.shade600,
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