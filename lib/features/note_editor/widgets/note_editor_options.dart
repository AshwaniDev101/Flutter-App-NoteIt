import 'package:flutter/material.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../database/drift/keybindings/keybindings_dao.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import '../../../core/config/menu_anchor_constants.dart';
import '../../../shared/note_card/core/note_action.dart';
import '../../keybinding/shortcut_config.dart';
import '../../keybinding/smart_action_widget.dart';

class NoteEditorOptionButton extends StatelessWidget {
  final void Function(NoteAction) onPressed;
  final bool isLocked;
  final bool isPinned;
  final bool isChecklist;
  final bool hasReminder;
  final List<NoteAction> options;
  final IconData icon;
  final Widget Function(BuildContext context, VoidCallback onPressed)? builder;

  static const List<NoteAction> defaultOptions = [
    NoteAction.delete,
    NoteAction.pin,
    NoteAction.lock,
    NoteAction.archive,
    NoteAction.info,
    NoteAction.checklist,
    NoteAction.find,
    NoteAction.reminder,
    NoteAction.settings,
  ];

  const NoteEditorOptionButton({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
    this.hasReminder = false,
    this.options = defaultOptions,
    this.icon = Icons.more_vert,
    this.builder,
  });

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBottomSheetHeader(title: 'Note Options'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: NoteEditorOptionMenu(
                  isLocked: isLocked,
                  isPinned: isPinned,
                  isChecklist: isChecklist,
                  hasReminder: hasReminder,
                  options: options,
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

    final colorScheme = Theme.of(context).colorScheme;

    if (isMobile) {
      if (builder != null) {
        return builder!(context, () => _showMobileBottomSheet(context));
      }

      return IconButton(
        tooltip: "Option Menu",
        icon: Icon(icon),
        onPressed: () => _showMobileBottomSheet(context),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerLowest, // The background color
          foregroundColor: colorScheme.onSurface, // The icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      );
    }

    return MenuAnchor(
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        void toggleMenu() {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }

        if (builder != null) {
          return builder!(context, toggleMenu);
        }

        return IconButton(
          tooltip: "Option Menu",
          onPressed: toggleMenu,
          constraints: const BoxConstraints(),

          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: colorScheme.onSurface,
            hoverColor: colorScheme.surfaceContainerLow,

            // 2. Shrink the tap target to match the visible button size
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),

            // 3. Define the exact internal spacing you want around the icon
            // (e.g., 8.0 will make the button total 32x32 if the icon is 16)
            padding: const EdgeInsets.all(2),
          ),
          icon: Icon(icon,),
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
  final bool showCard;

  static const double _itemWidth = 60.0;
  static const double _itemHeight = 60.0;
  static const double _spacing = 8.0;
  static const int _columnCount = 3;

  const NoteEditorOptionMenu({
    super.key,
    required this.onPressed,
    this.isLocked = false,
    this.isPinned = false,
    this.isChecklist = false,
    this.hasReminder = false,
    this.options = NoteEditorOptionButton.defaultOptions,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double calculatedWidth = (_itemWidth * _columnCount) + (_spacing * (_columnCount - 1));

    final Widget wrapWidget = Wrap(
      alignment: WrapAlignment.start,
      spacing: _spacing,
      runSpacing: _spacing,
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

        final Widget optionWidget = _editorOption(
          context: context,
          icon: Icon(appearance.icon, color: iconColor),
          name: appearance.label,
          onPressed: () {
            MenuController.maybeOf(context)?.close();
            onPressed(option);
          },
        );

        if (option == NoteAction.find) {
          return SmartActionWidget(
            action: AppActions.findInNote,
            scope: ShortcutScope.editor,
            baseTooltip: appearance.tooltip,
            badgeTop: -2,
            badgeRight: -2,
            child: optionWidget,
          );
        }

        return optionWidget;
      }).toList(),
    );

    final content = Padding(
      padding: const EdgeInsets.all(8.0),
      child: showCard
          ? SizedBox(
              width: calculatedWidth,
              child: wrapWidget,
            )
          : SizedBox(
              width: double.infinity,
              child: wrapWidget,
            ),
    );

    if (!showCard) {
      return content;
    }

    return Card(
      color: colorScheme.surfaceContainerLowest,
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: content,
    );
  }

  Widget _editorOption({
    required Icon icon,
    required String name,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          height: _itemHeight,
          width: _itemWidth,
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
    );
  }
}
