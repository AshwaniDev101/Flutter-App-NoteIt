import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/logger.dart';
import '../../../database/drift/folders/folders_dao.dart';
import '../../../database/drift/local_database.dart';
import '../../../shared/app_bars/app_search_bar.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import '../providers/folder_providers.dart';
import '../viewmodel/folder_view_model.dart';
import 'dialogs/folder_editor_dialog.dart';
import 'widgets/folder_context_menu.dart';
import 'widgets/folder_list_item.dart';

enum SearchBarPosition { top, bottom }

class FolderSelectorContainer extends ConsumerStatefulWidget {
  final Folder? selectedFolder;
  final ValueChanged<Folder?> onFolderSelected;
  final String title;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool showEmptyNoteCount;
  final SearchBarPosition searchBarPosition;
  final bool allowContextMenus;
  final EdgeInsetsGeometry padding;

  const FolderSelectorContainer({
    super.key,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.title = 'Folders',
    this.emptyLabel = 'All Notes',
    this.emptyIcon = Icons.home,
    this.showEmptyNoteCount = false,
    this.searchBarPosition = SearchBarPosition.bottom,
    this.allowContextMenus = true,
    this.padding = const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
  });

  @override
  ConsumerState<FolderSelectorContainer> createState() =>
      _FolderSelectorContainerState();
}

class _FolderSelectorContainerState
    extends ConsumerState<FolderSelectorContainer> {
  late final TextEditingController _searchController;
  bool _isEmptyOptionHovering = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(folderViewModelProvider.notifier).clearSearchQuery();
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FolderEditorDialog(),
    );

    if (result != null && mounted) {
      AppLogger.d(
        "FolderSelectorContainer: User triggered folder creation '${result['name']}'",
      );
      final viewModel = ref.read(folderViewModelProvider.notifier);
      final newUuid = await viewModel.createFolder(
        name: result['name'],
        colorIndex: result['colorIndex'],
      );

      final dao = ref.read(foldersDaoProvider);
      final allFolders = await dao.select(dao.folders).get();
      final newFolder = allFolders.where((f) => f.uuid == newUuid).firstOrNull;
      if (newFolder != null) {
        widget.onFolderSelected(newFolder);
      }
    }
  }

  Widget _buildSearchBarAndAddButton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final viewModel = ref.read(folderViewModelProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: AppSearchBar(
            controller: _searchController,
            hintText: 'Search folders...',
            fillColor: colorScheme.surfaceContainerLow,
            onChanged: (value) => viewModel.updateSearchQuery(value),
            onClear: _clearSearch,
          ),
        ),
        if (widget.allowContextMenus) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showCreateFolderDialog(context),
              icon: Icon(
                Icons.add_rounded,
                size: 22,
                color: colorScheme.onPrimaryContainer,
              ),
              tooltip: 'New Folder',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyFoldersView(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No Folders',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'There are no folders, Create a folder to start organizing your notes.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.allowContextMenus) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateFolderDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Folder'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final folderState = ref.watch(folderViewModelProvider);
    final foldersAsync = ref.watch(activeFoldersStreamProvider);
    final totalNotesCountAsync = ref.watch(totalNotesCountStreamProvider);
    final allNoteCount = totalNotesCountAsync.value ?? 0;
    final activeFolder = widget.selectedFolder;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title.isNotEmpty)
            AppBottomSheetHeader(title: widget.title),

          if (widget.searchBarPosition == SearchBarPosition.top) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildSearchBarAndAddButton(context, colorScheme),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (folders) {
                if (folders.isEmpty) {
                  return _buildEmptyFoldersView(
                    context,
                    colorScheme,
                    textTheme,
                  );
                }

                final lowerQuery = folderState.searchQuery.toLowerCase().trim();
                final showEmptyOption =
                    folders.isNotEmpty &&
                    (lowerQuery.isEmpty ||
                        widget.emptyLabel.toLowerCase().contains(lowerQuery) ||
                        'all notes'.contains(lowerQuery) ||
                        'no folder'.contains(lowerQuery) ||
                        'none'.contains(lowerQuery));

                final filteredFolders = folders.where((f) {
                  return f.folder.name.toLowerCase().contains(lowerQuery);
                }).toList();

                if (filteredFolders.isEmpty && !showEmptyOption) {
                  return Center(
                    child: Text(
                      "No results found",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (showEmptyOption)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            hoverColor: colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            onTap: () => widget.onFolderSelected(null),
                            onHover: (hovering) =>
                                setState(() => _isEmptyOptionHovering = hovering),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: activeFolder == null
                                    ? colorScheme.primaryContainer.withValues(
                                        alpha: 0.4,
                                      )
                                    : _isEmptyOptionHovering
                                        ? colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.5)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: Icon(
                                        widget.emptyIcon,
                                        size: 18,
                                        color: activeFolder == null
                                            ? colorScheme.primary
                                            : _isEmptyOptionHovering
                                                ? colorScheme.onSurface
                                                : colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.emptyLabel,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: activeFolder == null
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: activeFolder == null
                                            ? colorScheme.primary
                                            : _isEmptyOptionHovering
                                                ? colorScheme.onSurface
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (widget.showEmptyNoteCount)
                                    Flexible(
                                      flex: 0,
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          left: 8.0,
                                          right: 4.0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: activeFolder == null
                                              ? colorScheme.primaryContainer
                                                    .withValues(alpha: 0.6)
                                              : _isEmptyOptionHovering
                                                  ? colorScheme
                                                        .surfaceContainerHighest
                                                  : colorScheme
                                                        .surfaceContainerHighest
                                                        .withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '$allNoteCount',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: activeFolder == null
                                                ? colorScheme.primary
                                                : _isEmptyOptionHovering
                                                    ? colorScheme.onSurface
                                                    : colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (showEmptyOption && filteredFolders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),

                    ...filteredFolders.map((folderWithCount) {
                      final folderData = folderWithCount.folder;
                      final isSelected = activeFolder?.uuid == folderData.uuid;

                      return FolderListItem(
                        folderWithCount: folderWithCount,
                        isSelected: isSelected,
                        allowPinning: widget.allowContextMenus,
                        onSelect: () => widget.onFolderSelected(folderData),
                        onContextMenu: widget.allowContextMenus
                            ? (details) {
                                FolderContextMenu.show(
                                  context: context,
                                  ref: ref,
                                  folder: folderData,
                                  position: details?.globalPosition,
                                  selectedFolder: widget.selectedFolder,
                                  onFolderSelected: widget.onFolderSelected,
                                );
                              }
                            : null,
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          if (widget.searchBarPosition == SearchBarPosition.bottom) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 4.0,
                right: 4.0,
                top: 8.0,
                bottom: 16.0,
              ),
              child: _buildSearchBarAndAddButton(context, colorScheme),
            ),
          ],
        ],
      ),
    );
  }
}
