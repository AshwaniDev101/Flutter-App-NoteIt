import 'package:flutter/material.dart';

/// search UI and interactions across the NoteIt application.
///
/// Features:
/// - Reactive clear (`X`) button via [ValueListenableBuilder] (no extra setState calls needed).
/// - Keyboard focus highlight border (`isKeyboardDriven`) for desktop traversal.
/// - Excluded focus on clear button so Tab key navigation skips clear button.
/// - Supports both embedded/inline layout and [AppSearchBar.appBar] header layout.
class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool isKeyboardDriven;
  final ValueChanged<bool>? onKeyboardModeChanged;
  final bool autofocus;
  final Color? fillColor;
  final Widget? prefixIcon;
  final Widget? trailing;
  final bool isAppBarVariant;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.onTap,
    this.borderRadius,
    this.isKeyboardDriven = false,
    this.onKeyboardModeChanged,
    this.autofocus = false,
    this.fillColor,
    this.prefixIcon,
    this.trailing,
  }) : isAppBarVariant = false;

  /// Specialized variant suited for embedding inside an [AppBar.title].
  const AppSearchBar.appBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search notes...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.onTap,
    this.autofocus = true,
    this.trailing,
  })  : borderRadius = null,
        isKeyboardDriven = false,
        onKeyboardModeChanged = null,
        fillColor = Colors.transparent,
        prefixIcon = null,
        isAppBarVariant = true;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleClear() {
    widget.controller.clear();
    if (widget.onClear != null) {
      widget.onClear!();
    } else {
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(8);
    final focusNode = _effectiveFocusNode;

    final effectiveFillColor = widget.fillColor ??
        (widget.isAppBarVariant
            ? Colors.transparent
            : colorScheme.surfaceContainerLowest);

    final suffixWidget = ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final showClear = value.text.isNotEmpty;
        if (!showClear && widget.trailing == null) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClear)
              ExcludeFocus(
                child: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _handleClear,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Clear search',
                ),
              ),
            if (widget.trailing != null) widget.trailing!,
          ],
        );
      },
    );

    final inputDecoration = InputDecoration(
      filled: !widget.isAppBarVariant || widget.fillColor != null,
      fillColor: effectiveFillColor,
      isDense: true,
      contentPadding: widget.isAppBarVariant
          ? const EdgeInsets.symmetric(horizontal: 0, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintText: widget.hintText,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      prefixIcon: widget.isAppBarVariant
          ? null
          : (widget.prefixIcon ??
              Icon(Icons.search_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant)),
      prefixIconConstraints: widget.isAppBarVariant
          ? null
          : const BoxConstraints(minWidth: 36, minHeight: 36),
      suffixIcon: suffixWidget,
      border: widget.isAppBarVariant
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
      focusedBorder: widget.isAppBarVariant
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
    );

    final textFieldWidget = TextField(
      controller: widget.controller,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: inputDecoration,
      onSubmitted: widget.onSubmitted,
      onTap: () {
        if (widget.onKeyboardModeChanged != null) {
          widget.onKeyboardModeChanged!(false);
        }
        widget.onTap?.call();
      },
      onChanged: widget.onChanged,
    );

    if (widget.isAppBarVariant) {
      return Semantics(
        label: widget.hintText,
        textField: true,
        child: textFieldWidget,
      );
    }

    return Semantics(
      label: widget.hintText,
      textField: true,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) {
          final parentFocused = Focus.maybeOf(context)?.hasFocus ?? false;
          final isFocused = focusNode.hasFocus || parentFocused;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: (isFocused && widget.isKeyboardDriven)
                    ? colorScheme.primary
                    : Colors.transparent,
                width: (isFocused && widget.isKeyboardDriven) ? 2 : 0,
              ),
            ),
            child: child,
          );
        },
        child: textFieldWidget,
      ),
    );
  }
}
