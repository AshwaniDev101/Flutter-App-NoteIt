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
            if (widget.sheetTitle.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  widget.sheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
            ],
            for (int i = 0; i < widget.sections.length; i++) ...[
              if (i > 0 && widget.sections[i].title == null)
                const SizedBox(height: 8),
              if (widget.sections[i].title != null)
                _buildSectionHeader(context, widget.sections[i].title!),
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
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 2,
          margin: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: widget.desktopWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.sections.length; i++) ...[
                    if (i > 0 && widget.sections[i].title != null)
                      const Divider(indent: 12, endIndent: 12),
                    if (widget.sections[i].title != null)
                      _buildSectionHeader(context, widget.sections[i].title!),
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
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
      ),
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
