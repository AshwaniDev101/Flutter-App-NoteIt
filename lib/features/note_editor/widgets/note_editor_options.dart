import 'package:flutter/material.dart';

import '../../../core/util/platform_helper.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import '../../../shared/note_card/core/note_action.dart';

class NoteEditorOptionButton extends StatelessWidget {
  final void Function(NoteAction) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;
  final bool hasReminder;
  final List<NoteAction> options;
  final IconData icon;

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
    this.icon = Icons.segment,
  });

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Note Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: NoteEditorOptionMenu(
                  isLocked: isLocked,
                  isPinned: isPinned,
                  isChecklist: isChecklist,
                  hasReminder: hasReminder,
                  options: options,
                  width: double.infinity,
                  showCard: false,
                  onPressed: (option) {
                    Navigator.pop(context);
                    onPressed(option);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !PlatformHelper.isWideLayout(context);

    if (isMobile) {
      return IconButton(
        tooltip: "Option Menu",
        icon: Icon(icon),
        onPressed: () => _showMobileBottomSheet(context),
      );
    }

    return MenuAnchor(
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
          icon: Icon(icon),
        );
      },
      menuChildren: [
        NoteEditorOptionMenu(
          onPressed: onPressed,
          isLocked: isLocked,
          isPinned: isPinned,
          isChecklist: isChecklist,
          hasReminder: hasReminder,
          options: options,
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
  final double width;
  final bool showCard;

  const NoteEditorOptionMenu({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
    this.hasReminder = false,
    this.options = NoteEditorOptionButton.defaultOptions,
    this.width = 196,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: width,
        child: Wrap(
          alignment: WrapAlignment.center,
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
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant;

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
    );

    if (!showCard) {
      return content;
    }

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: content,
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
