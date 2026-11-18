import 'package:flutter/material.dart';

import '../../core/helpers/platform_helper.dart';
import 'app_bottom_sheet.dart';

/// Specification for an individual menu item in [AdaptiveMenuButton].
class MenuItemSpec<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;

  const MenuItemSpec({
    required this.value,
    required this.label,
    this.icon,
    this.leading,
    this.isSelected = false,
    required this.onTap,
  });
}

/// Specification for a grouped menu section in [AdaptiveMenuButton].
class MenuSectionSpec<T> {
  final String? title;
  final List<MenuItemSpec<T>> items;

  const MenuSectionSpec({
    this.title,
    required this.items,
  });
}

/// An adaptive menu button that displays a desktop [MenuAnchor] popup card
/// on wide layouts and a mobile [AppBottomSheet] on compact screens.
class AdaptiveMenuButton<T> extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final String sheetTitle;
  final List<MenuSectionSpec<T>> sections;
  final double desktopWidth;
  final bool closeOnSelect;

  const AdaptiveMenuButton({
    super.key,
    required this.icon,
    required this.sections,
    this.sheetTitle = '',
    this.tooltip = '',
    this.desktopWidth = 250.0,
    this.closeOnSelect = true,
  });

  @override
  State<AdaptiveMenuButton<T>> createState() => _AdaptiveMenuButtonState<T>();
}

class _AdaptiveMenuButtonState<T> extends State<AdaptiveMenuButton<T>> {
  final MenuController _menuController = MenuController();

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (bottomSheetContext, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sheetTitle.isNotEmpty)
              AppBottomSheetHeader(title: widget.sheetTitle),
            for (int i = 0; i < widget.sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              for (final item in widget.sections[i].items)
                _buildActionTile(
                  context,
                  item,
                  onSelect: () {
                    if (widget.closeOnSelect) {
                      Navigator.of(bottomSheetContext).pop();
                    } else {
                      setModalState(() {});
                    }
                  },
                ),
            ],
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
      return IconButton(
        icon: Icon(widget.icon),
        tooltip: widget.tooltip,
        onPressed: () => _showMobileBottomSheet(context),
      );
    }

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
          icon: Icon(widget.icon),
          tooltip: widget.tooltip,
        );
      },
      menuChildren: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Material(
            color: colorScheme.surfaceContainer,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: widget.desktopWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.sheetTitle.isNotEmpty)
                      AppBottomSheetHeader(title: widget.sheetTitle),
                    for (int i = 0; i < widget.sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      for (final item in widget.sections[i].items)
                        _buildActionTile(
                          context,
                          item,
                          onSelect: () {
                            if (widget.closeOnSelect) {
                              _menuController.close();
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    MenuItemSpec<T> item, {
    VoidCallback? onSelect,
  }) {
    return AppMenuTile(
      label: item.label,
      icon: item.icon,
      leading: item.leading,
      isSelected: item.isSelected,
      onTap: () {
        item.onTap();
        onSelect?.call();
      },
    );
  }
}
