import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// The Enum is now purely the "Identity" of the action.
enum NoteEditorOption {
  delete,
  pin,
  lock,
  archive,
  info,
  checklist,
  find,
  reminder,
}

//  Define a Dart Record type for how an option should look.
typedef OptionAppearance = ({String label, IconData icon, String tooltip, bool isActive});

// The Extension holds all the dynamic UI logic, removing it from the Widget's build method.
extension NoteEditorOptionUI on NoteEditorOption {
  OptionAppearance getAppearance({
    required bool isLocked,
    required bool isPinned,
    required bool isChecklist,
  }) {
    switch (this) {
      case NoteEditorOption.lock:
        return (
        label: isLocked ? 'Unlock' : 'Lock',
        icon: isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
        tooltip: isLocked ? 'Remove Lock' : 'Lock Note',
        isActive: isLocked,
        );
      case NoteEditorOption.pin:
        return (
        label: isPinned ? 'Unpin' : 'Pin',
        icon: isPinned ? CupertinoIcons.pin_slash : Icons.push_pin_outlined,
        tooltip: isPinned ? 'Unpin Note' : 'Pin Note',
        isActive: isPinned,
        );
      case NoteEditorOption.checklist:
        return (
        label: isChecklist ? 'Plain-text' : 'Checklist',
        icon: isChecklist ? Icons.notes : Icons.check_box_outlined, // Icons.notes represents plain text well
        tooltip: isChecklist ? 'Convert to Plain-text' : 'Turn to Checklist',
        isActive: isChecklist,
        );
      case NoteEditorOption.delete:
        return (label: 'Delete', icon: Icons.delete_outline, tooltip: 'Delete Note', isActive: false);
      case NoteEditorOption.archive:
        return (label: 'Archive', icon: Icons.archive_outlined, tooltip: 'Archive Note', isActive: false);
      case NoteEditorOption.info:
        return (label: 'Details', icon: Icons.info_outline, tooltip: 'Note Meta Data', isActive: false);
      case NoteEditorOption.find:
        return (label: 'Find', icon: Icons.search_outlined, tooltip: 'Find in Note', isActive: false);
      case NoteEditorOption.reminder:
        return (label: 'Reminder', icon: Icons.notifications_none_outlined, tooltip: 'Set Reminder', isActive: false);
    }
  }
}

class NoteEditorOptionButton extends StatefulWidget {
  final void Function(NoteEditorOption) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;

  const NoteEditorOptionButton({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
  });

  @override
  State<NoteEditorOptionButton> createState() => _NoteEditorOptionButtonState();
}

class _NoteEditorOptionButtonState extends State<NoteEditorOptionButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorSchema = Theme.of(context).colorScheme;
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(Icons.segment, color: colorSchema.primary),
        );
      },
      menuChildren: [
        NoteEditorOptionMenu(
          onPressed: widget.onPressed,
          isLocked: widget.isLocked,
          isPinned: widget.isPinned,
          isChecklist: widget.isChecklist,
        ),
      ],
    );
  }
}

class NoteEditorOptionMenu extends StatelessWidget {
  final void Function(NoteEditorOption) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;

  const NoteEditorOptionMenu({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
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
            children: NoteEditorOption.values.map((option) {

              // Look how clean the build method becomes. No if/else statements.
              final appearance = option.getAppearance(
                isLocked: isLocked,
                isPinned: isPinned,
                isChecklist: isChecklist,
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
                Text(name, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}