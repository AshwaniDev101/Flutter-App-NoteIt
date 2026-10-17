import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/viewmodel/viewmodel.dart';

/// Centralized Search Bar widget for Home pages (both mobile and desktop).
///
/// Features:
/// - Connects to [searchQueryProvider] and [homeViewModelProvider] automatically.
/// - Shows a clear (X) icon when search text is non-empty.
/// - Configurable border radius (rounded pill for mobile, square/subtle for desktop).
/// - Supports focus node and keyboard-driven focus highlights.
class HomeSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final BorderRadius? borderRadius;
  final bool isKeyboardDriven;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onKeyboardModeChanged;

  const HomeSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search notes...',
    this.borderRadius,
    this.isKeyboardDriven = false,
    this.onTap,
    this.onKeyboardModeChanged,
  });

  /// Clears search text and resets search state providers.
  void _clearSearch(WidgetRef ref) {
    controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(homeViewModelProvider.notifier).exitSearchMode();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(30);

    final isFocused = focusNode?.hasFocus ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          // Show accent focus border when keyboard navigation is active
          color: (isFocused && isKeyboardDriven) ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,

        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          isDense: true,
          // contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: hintText,

          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? ExcludeFocus(
                      child: IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _clearSearch(ref)),
                    )
                  : const SizedBox.shrink();
            },
          ),
          prefixIcon: const Icon(Icons.search, size: 18),
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),

          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          border: OutlineInputBorder(borderRadius: effectiveBorderRadius, borderSide: BorderSide.none),

          focusedBorder: OutlineInputBorder(borderRadius: effectiveBorderRadius, borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),

        onTap: () {
          if (onKeyboardModeChanged != null) {
            onKeyboardModeChanged!(false);
          }
          if (!homeState.isSearchMode) viewModel.enterSearchMode();
          if (onTap != null) onTap!();
        },
        onChanged: (value) {
          if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
          if (value.isEmpty) {
            _clearSearch(ref);
          } else {
            ref.read(searchQueryProvider.notifier).updateQuery(value);
          }
        },
      ),
    );
  }
}
