import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/db_sorting_filtering.dart';

// Define the categories so our builder knows how to handle routing
enum MenuActionCategory { sort, filter }

// The Enhanced Enum holding all UI configurations in one place
enum HomeMenuAction {
  // Added standard Material icons that match your UI reference
  sortCreated('Created', Icons.calendar_month_outlined, MenuActionCategory.sort),
  sortName('Name', Icons.sort_by_alpha, MenuActionCategory.sort),
  sortUpdated('Last Updated', Icons.history, MenuActionCategory.sort),

  filterPhone('Phone', Icons.smartphone_outlined, MenuActionCategory.filter),
  filterWindows('Windows', Icons.window, MenuActionCategory.filter);

  final String label;
  final IconData? icon;
  final MenuActionCategory category;

  const HomeMenuAction(this.label, this.icon, this.category);
}

class SortFilterOptionMenu extends ConsumerWidget {
  const SortFilterOptionMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the active state rules
    final currentSortOption = ref.watch(noteSortPreferenceProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);

    return PopupMenuButton<HomeMenuAction>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Sort & Filter',
      onSelected: (HomeMenuAction action) {
        // Strict routing based on the enum action
        switch (action) {
          case HomeMenuAction.sortCreated:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
            break;
          case HomeMenuAction.sortName:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
            break;
          case HomeMenuAction.sortUpdated:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
            break;

          case HomeMenuAction.filterPhone:
            ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
            break;
          case HomeMenuAction.filterWindows:
            ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<HomeMenuAction>>[
        const PopupMenuItem<HomeMenuAction>(
          enabled: false,
          child: Text('SORT BY', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),

        _buildMenuItem(HomeMenuAction.sortCreated, currentSortOption == NoteSortPreference.createdAt),
        _buildMenuItem(HomeMenuAction.sortName, currentSortOption == NoteSortPreference.name),
        _buildMenuItem(HomeMenuAction.sortUpdated, currentSortOption == NoteSortPreference.updatedAt),

        const PopupMenuDivider(),

        const PopupMenuItem<HomeMenuAction>(
          enabled: false,
          child: Text('FILTER PLATFORM', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),

        _buildMenuItem(HomeMenuAction.filterPhone, currentPlatformFilter == FilterPlatformOptions.android),
        _buildMenuItem(HomeMenuAction.filterWindows, currentPlatformFilter == FilterPlatformOptions.windows),
      ],
    );
  }

  // Unified Builder Method
  PopupMenuItem<HomeMenuAction> _buildMenuItem(HomeMenuAction action, bool isSelected) {
    return PopupMenuItem<HomeMenuAction>(
      value: action,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (action.icon != null) ...[
                Icon(action.icon, size: 20, color: Colors.black54),
                const SizedBox(width: 12),
              ],
              Text(
                action.label,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
          
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }
}