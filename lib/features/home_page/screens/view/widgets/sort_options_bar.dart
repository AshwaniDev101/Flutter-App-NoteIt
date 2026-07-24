import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/options.dart';
import '../../core/providers.dart';
import '../../core/sort.dart';
import '../home_page.dart';

class SortOptionsBar extends ConsumerWidget {
  const SortOptionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(noteSortOptionProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Created'),
              selected: currentSortOption == NoteSortOption.createdAt,
              onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.createdAt),
              avatar: const Icon(Icons.access_time, size: 16),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Name'),
              selected: currentSortOption == NoteSortOption.name,
              onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.name),
              avatar: const Icon(Icons.sort_by_alpha, size: 16),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Last Updated'),
              selected: currentSortOption == NoteSortOption.updatedAt,
              onSelected: (_) => ref.read(noteSortOptionProvider.notifier).updateSort(NoteSortOption.updatedAt),
              avatar: const Icon(Icons.update, size: 16),
              showCheckmark: false,
            ),

            Container(
              width: 1,
              height: 24,
              color: Colors.grey.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            ChoiceChip(
              label: const Text('Phone'),
              selected: currentPlatformFilter == PlatformOptions.android,
              onSelected: (_) => ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.android),
              avatar: const Icon(Icons.phone_android_outlined, size: 16, color: Colors.grey),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Windows'),
              selected: currentPlatformFilter == PlatformOptions.windows,
              onSelected: (_) => ref.read(platformFilterProvider.notifier).toggleFilter(PlatformOptions.windows),
              avatar: const Icon(Icons.desktop_windows_outlined, size: 16, color: Colors.grey),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),

          ],
        ),
      ),
    );
  }
}