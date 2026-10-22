import 'package:flutter/material.dart';

/// Standardized Material 3 bottom sheet for mobile views across NoteIt.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, StateSetter setModalState) builder,
  double? heightFactor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext bottomSheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final bottomPadding = MediaQuery.of(bottomSheetContext).viewInsets.bottom;
          final content = Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: builder(context, setModalState),
          );

          if (heightFactor != null) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(bottomSheetContext).height * heightFactor,
                child: content,
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: content,
              ),
            ),
          );
        },
      );
    },
  );
}

/// Reusable styled list tile for popup menus and bottom sheets.
class AppMenuTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;

  const AppMenuTile({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final leadingWidget = leading ??
        (icon != null
            ? Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              )
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        leading: leadingWidget,
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_rounded, size: 20, color: colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
