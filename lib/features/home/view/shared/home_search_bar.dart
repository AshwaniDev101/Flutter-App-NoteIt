import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/viewmodel/viewmodel.dart';
import 'package:noteit/shared/app_search_bar.dart';

/// Centralized Search Bar widget for Home pages (both mobile and desktop).
///
/// Wraps [AppSearchBar] with Riverpod state management connected to
/// [searchQueryProvider] and [homeViewModelProvider].
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    void clearSearch() {
      controller.clear();
      ref.read(searchQueryProvider.notifier).clear();
      ref.read(homeViewModelProvider.notifier).exitSearchMode();
    }

    return AppSearchBar(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      borderRadius: borderRadius ?? BorderRadius.circular(30),
      isKeyboardDriven: isKeyboardDriven,
      onKeyboardModeChanged: onKeyboardModeChanged,
      onTap: () {
        if (!homeState.isSearchMode) viewModel.enterSearchMode();
        onTap?.call();
      },
      onClear: clearSearch,
      onChanged: (value) {
        if (value.isNotEmpty && !homeState.isSearchMode) viewModel.enterSearchMode();
        if (value.isEmpty) {
          clearSearch();
        } else {
          ref.read(searchQueryProvider.notifier).updateQuery(value);
        }
      },
    );
  }
}
