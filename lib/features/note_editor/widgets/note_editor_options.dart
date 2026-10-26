import 'package:flutter/material.dart';

import '../../../shared/note_card/core/note_action.dart';


class NoteEditorOptionButton extends StatefulWidget {
  final void Function(NoteAction) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;
  final bool hasReminder;
  final List<NoteAction> options;

  static const List<NoteAction> defaultOptions = [
    NoteAction.delete,
    NoteAction.pin,
    NoteAction.lock,
    NoteAction.archive,
    NoteAction.info,
    NoteAction.checklist,
    NoteAction.find,
    NoteAction.reminder,
  ];

  const NoteEditorOptionButton({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
    this.hasReminder = false,
    this.options = defaultOptions,
  });

  @override
  State<NoteEditorOptionButton> createState() => _NoteEditorOptionButtonState();
}

class _NoteEditorOptionButtonState extends State<NoteEditorOptionButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    // final colorSchema = Theme.of(context).colorScheme;
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          tooltip: "Option Menu",
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.segment),
        );
      },
      menuChildren: [
        NoteEditorOptionMenu(
          onPressed: widget.onPressed,
          isLocked: widget.isLocked,
          isPinned: widget.isPinned,
          isChecklist: widget.isChecklist,
          hasReminder: widget.hasReminder,
          options: widget.options,
        ),
      ],
    );
  }
}

class NoteEditorOptionMenu extends StatelessWidget {
  final void Function(NoteAction) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;
  final bool hasReminder;
  final List<NoteAction> options;

  const NoteEditorOptionMenu({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
    this.hasReminder = false,
    this.options = NoteEditorOptionButton.defaultOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 196,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              final appearance = option.getAppearance(
                isLocked: isLocked,
                isPinned: isPinned,
                isChecklist: isChecklist,
                hasReminder: hasReminder,
              );

              final Color iconColor = appearance.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant;

              return _editorOption(
                context: context,
                icon: Icon(appearance.icon, color: iconColor),
                name: appearance.label,
                tooltip: appearance.tooltip,
                onPressed: () {
                  MenuController.maybeOf(context)?.close();
                  onPressed(option);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _editorOption({
    required Icon icon,
    required String name,
    required String tooltip,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            height: 60,
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
