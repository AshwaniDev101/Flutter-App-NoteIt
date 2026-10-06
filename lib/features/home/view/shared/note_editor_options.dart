import 'package:flutter/material.dart';

enum NoteEditorOption {
  delete('Delete', Icons.delete_outline, 'Delete Note'),
  pin('Pin', Icons.push_pin_outlined, 'Pin Note'),
  lock('Lock', Icons.lock_outline, 'Lock Note'),
  checklist('Checklist', Icons.check_box_outlined, 'Turn to Checklist'),
  archive('Archive', Icons.archive_outlined, 'Archive Note'),
  find('Find', Icons.search_outlined, 'Find in Note'),
  reminder('Reminder', Icons.notifications_none_outlined, 'Set Reminder'); // Semicolon is still required here

  final String label;
  final IconData icon;
  final String tooltip;

  const NoteEditorOption(this.label, this.icon, this.tooltip);
}

class NoteEditorOptionButton extends StatefulWidget {
  final void Function(NoteEditorOption) onPressed;
  final bool isLocked;
  final bool isPinned;

  const NoteEditorOptionButton({super.key, required this.onPressed, this.isLocked = false, this.isPinned = false});

  @override
  State<NoteEditorOptionButton> createState() => _NoteEditorOptionButtonState();
}

class _NoteEditorOptionButtonState extends State<NoteEditorOptionButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      // Removes default menu background/padding so your Card looks native
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
          icon: const Icon(Icons.list),
          // icon: const Icon(Icons.keyboard_double_arrow_down),
        );
      },
      menuChildren: [
        NoteEditorOptionMenu(onPressed: widget.onPressed, isLocked: widget.isLocked, isPinned: widget.isPinned),
      ],
    );
  }
}

class NoteEditorOptionMenu extends StatelessWidget {
  final void Function(NoteEditorOption) onPressed;
  final bool isLocked;
  final bool isPinned;

  const NoteEditorOptionMenu({super.key, required this.onPressed, this.isLocked = false, this.isPinned = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      // Padding around the Wrap
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 196,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: NoteEditorOption.values.map((option) {
              IconData currentIcon = option.icon;
              String currentTooltip = option.tooltip;
              String currentLabel = option.label;

              //  Check if this specific option is currently active
              bool isActive = false;
              if (option == NoteEditorOption.lock) {
                currentIcon = isLocked ? Icons.lock_clock : Icons.lock_outline;
                currentTooltip = isLocked ? 'Remove Lock' : 'Lock Note';
                currentLabel = isLocked ? 'Unlock' : 'Lock';
                isActive = isLocked;
              } else if (option == NoteEditorOption.pin) {
                currentIcon = isPinned ? Icons.push_pin : Icons.push_pin_outlined;
                currentTooltip = isPinned ? 'Unpin Note' : 'Pin Note';
                currentLabel = isPinned ? 'Unpin' : 'Pin';
                isActive = isPinned;
              }

              // Only active options get the primary color; others use the default
              final Color iconColor = isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant;

              final mainIcon = Icon(currentIcon, color: iconColor);

              return _editorOption(
                context: context,
                icon: mainIcon,
                name: currentLabel,
                tooltip: currentTooltip,
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
