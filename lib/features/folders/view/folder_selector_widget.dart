import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'folders.dart';

class FolderSelectorWidget extends ConsumerStatefulWidget {
  const FolderSelectorWidget({super.key});

  @override
  ConsumerState<FolderSelectorWidget> createState() => _ModernSelectorWidgetState();
}

class _ModernSelectorWidgetState extends ConsumerState<FolderSelectorWidget> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    // Rebuild the overlay to reflect filtered results
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showOverlay();
    }
  }

  void _closeDropdown() {
    _removeOverlay();
    setState(() {
      _isOpen = false;
      _searchController.clear(); // Reset search when closed
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Invisible background to catch outside taps and close the dropdown
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8), // 8px spacing below the button
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 220, // Width of the dropdown
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Dropdown Items List wrapped in a Consumer to watch Riverpod streams
                      Consumer(
                        builder: (context, ref, child) {
                          final foldersAsync = ref.watch(activeFoldersStreamProvider);
                          final activeFolder = ref.watch(activeFolderProvider);
                          final searchQuery = _searchController.text.toLowerCase();

                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: foldersAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                              error: (err, stack) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Error loading folders', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                              ),
                              data: (folders) {
                                final filteredFolders = folders.where((f) {
                                  return f.folder.name.toLowerCase().contains(searchQuery);
                                }).toList();

                                final showAllNotesOption = 'all notes'.contains(searchQuery) || searchQuery.isEmpty;

                                if (filteredFolders.isEmpty && !showAllNotesOption) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No results found'),
                                  );
                                }

                                return ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    // Default "All Notes" Option
                                    if (showAllNotesOption)
                                      _buildListItem(
                                        context: context,
                                        title: 'All Notes',
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        isSelected: activeFolder == null,
                                        onTap: () {
                                          ref.read(activeFolderProvider.notifier).clear();
                                          _closeDropdown();
                                        },
                                      ),

                                    // Real Folder Options
                                    ...filteredFolders.map((folderWithCount) {
                                      final folderData = folderWithCount.folder;
                                      final isSelected = activeFolder?.uuid == folderData.uuid;
                                      final folderColor = Colors.primaries[folderData.colorIndex % Colors.primaries.length];

                                      return _buildListItem(
                                        context: context,
                                        title: folderData.name,
                                        color: folderColor,
                                        isSelected: isSelected,
                                        onTap: () {
                                          ref.read(activeFolderProvider.notifier).setFolder(folderData);
                                          _closeDropdown();
                                        },
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  Widget _buildListItem({
    required BuildContext context,
    required String title,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the active folder to update the button's UI
    final activeFolder = ref.watch(activeFolderProvider);

    final currentName = activeFolder?.name ?? 'All Notes';
    final currentColor = activeFolder != null
        ? Colors.primaries[activeFolder.colorIndex % Colors.primaries.length]
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // Matches the subtle rounded outline border in the reference image
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
              color: _isOpen ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}