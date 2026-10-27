import 'package:flutter/material.dart';

/// A styled interactive pill/chip designed for conversational "Mad Libs" sentences.
///
/// Looks like an editable blank embedded within body text, providing hover and focus feedback
/// for desktop mouse clicks as well as touch tap feedback on mobile.
class ConversationalChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final bool showDropdownArrow;
  final bool isActive;

  const ConversationalChip({
    super.key,
    required this.label,
    this.onTap,
    this.onTapDown,
    this.icon,
    this.showDropdownArrow = true,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = isActive
        ? colorScheme.primaryContainer.withValues(alpha: 0.8)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final fgColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onTapDown: onTapDown,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: isActive ? 0.4 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: fgColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: fgColor.withValues(alpha: 0.6),
                ),
              ),
              if (showDropdownArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: fgColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
