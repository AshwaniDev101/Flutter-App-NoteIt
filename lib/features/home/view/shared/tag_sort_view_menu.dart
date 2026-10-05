import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db_sorting_filtering.dart';
import '../../core/providers.dart';

class FolderSortViewButton extends StatefulWidget {
  const FolderSortViewButton({super.key});

  @override
  State<FolderSortViewButton> createState() => _FolderSortViewButtonState();
}

class _FolderSortViewButtonState extends State<FolderSortViewButton> {
  // Controller to programmatically open/close the menu
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Open the menu when the user hovers over the button
      onEnter: (_) {
        // disabling opening menu when hover for now
        // if (!_menuController.isOpen) {
        //   _menuController.open();
        // }
      },
      child: MenuAnchor(
        controller: _menuController,
        // Removes default menu background/padding so your Card looks native
        style: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
        ),
        builder: (BuildContext context, MenuController controller, Widget? child) {
          return IconButton(
            onPressed: () {
              // Toggle menu on button press
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.filter_alt),
          );
        },
        menuChildren: const [
          // Forces the popup to be exactly 500x500
          SizedBox(width: 200, height: 250, child: FolderSortViewMenu()),
        ],
      ),
    );
  }
}

enum MenuActionCategory { sort, filter }

enum HomeMenuAction {
  sortCreated('by created time', Icons.calendar_month_outlined, MenuActionCategory.sort),
  sortName('alphabetically', Icons.sort_by_alpha, MenuActionCategory.sort),
  sortUpdated('by modified time', Icons.history, MenuActionCategory.sort),
  filterPhone('Phone', Icons.smartphone_outlined, MenuActionCategory.filter),
  filterWindows('Desktop', Icons.desktop_mac_outlined, MenuActionCategory.filter);

  final String label;
  final IconData? icon;
  final MenuActionCategory category;

  const HomeMenuAction(this.label, this.icon, this.category);
}


class FolderSortViewMenu extends ConsumerStatefulWidget {
  const FolderSortViewMenu({super.key});

  @override
  ConsumerState<FolderSortViewMenu> createState() => _FolderSortViewMenuState();
}

class _FolderSortViewMenuState extends ConsumerState<FolderSortViewMenu> {
  // Dummy states for now
  final List<String> _availableFolders = ['Work', 'Personal', 'Ideas', 'Urgent', 'To-Do', 'Archive', 'Finance'];
  String? _selectedFolder;
  String _folderSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Watch existing states
    final currentSortOption = ref.watch(noteSortPreferenceProvider);
    final currentPlatformFilter = ref.watch(platformFilterProvider);
    final currentView = ref.watch(noteViewTypeProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,

              // labelStyle: TextStyle(fontSize: 12),
              // unselectedLabelStyle: TextStyle(fontSize: 12),
              labelPadding: EdgeInsets.zero,

              tabs: [
                Tab(icon: Icon(Icons.folder,size: 20,), text: 'Folder'),
                Tab(icon: Icon(Icons.filter_list,size: 20,), text: 'Sort'),
                Tab(icon: Icon(Icons.view_comfortable_rounded,size: 20,), text: 'View'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Folder CONTENT
                  _buildFolderTab(),

                  // SORT & PLATFORM FILTER CONTENT
                  _buildSortTab(currentSortOption, currentPlatformFilter),

                  // VIEW CONTENT
                  _buildViewTab(currentView),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: FOLDERS
  Widget _buildFolderTab() {
    // Filter the folders based on the search query
    final filteredFolders = _availableFolders.where((folder) {
      return folder.toLowerCase().contains(_folderSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // MINI SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
          child: TextField(
            style: const TextStyle(fontSize: 12),
            onChanged: (value) {
              setState(() {
                _folderSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              isDense: true, // Keeps the text field thin
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: 'Search folders...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
              prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28), // Shrinks the icon area
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),

        // SCROLLABLE FOLDERS LIST
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity, // Ensures Wrap aligns to the left
              child: Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: filteredFolders.map((folder) { // Use filteredFolders here
                  final isSelected = _selectedFolder == folder;
                  return ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(folder, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFolder = selected ? folder : null;
                      });
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // TAB 2: SORT & FILTER
  Widget _buildSortTab(dynamic currentSortOption, dynamic currentPlatformFilter) {
    return ListView(

      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //   child: Text(
        //     'SORT BY',
        //     style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        //   ),
        // ),
        _buildActionTile(HomeMenuAction.sortCreated, currentSortOption == NoteSortPreference.createdAt),
        _buildActionTile(HomeMenuAction.sortName, currentSortOption == NoteSortPreference.name),
        _buildActionTile(HomeMenuAction.sortUpdated, currentSortOption == NoteSortPreference.updatedAt),

        // Disable filter platform for now
        // const Divider(),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //   child: Text(
        //     'FILTER PLATFORM',
        //     style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        //   ),
        // ),
        // _buildActionTile(HomeMenuAction.filterPhone, currentPlatformFilter == FilterPlatformOptions.android),
        // _buildActionTile(HomeMenuAction.filterWindows, currentPlatformFilter == FilterPlatformOptions.windows),
      ],
    );
  }


  // TAB 3: VIEWS
  Widget _buildViewTab(dynamic currentView) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: NoteViewType.values.map((view) {
        final isSelected = view == currentView;

        return ListTile(

          dense: true,
          // visualDensity: VisualDensity.compact,
          // contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),

          leading: Icon(view.icon, color: isSelected ? Colors.blue : Colors.black54),
          title: Text(
            view.label,
            style: TextStyle(color: Colors.black87, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
          ),
          // trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
          onTap: () {
            ref.read(noteViewTypeProvider.notifier).updateView(view);
          },
        );
      }).toList(),
    );
  }


  // HELPER BUILDER FOR SORT/FILTER TILE
  Widget _buildActionTile(HomeMenuAction action, bool isSelected) {
    return ListTile(

      dense: true,
      // visualDensity: VisualDensity.compact,
      // contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),

      leading: action.icon != null ? Icon(action.icon, color: Colors.black54) : null,
      title: Text(
        action.label,
        style: TextStyle(color: Colors.black87, fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal),
      ),
      // trailing: Icon(
      //   isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      //   color: isSelected ? Colors.blue : Colors.grey,
      // ),
      onTap: () {
        // Exact logic from your PopupMenu onSelected
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
    );
  }
}
