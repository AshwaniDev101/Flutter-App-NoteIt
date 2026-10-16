import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';

class DesktopLeftPanel extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  // Existing parameters
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(bool) onDrawerChanged;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? activeNoteId;
  final bool isKeyboardDriven;
  final VoidCallback onAddNote;
  final Function(Note) onNoteTap;
  final Function(bool) onKeyboardModeChanged;

  const DesktopLeftPanel({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.scaffoldKey,
    required this.onDrawerChanged,
    required this.searchController,
    required this.searchFocusNode,
    this.activeNoteId,
    required this.isKeyboardDriven,
    required this.onAddNote,
    required this.onNoteTap,
    required this.onKeyboardModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onToggle,
                  tooltip: 'Toggle Sidebar',
                ),
                if (isExpanded)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        'NoteIt',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
              ],
            ),
          ),

          // New Note Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: InkWell(
              onTap: onAddNote,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    if (isExpanded)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            'New Note',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Main Navigation
          _NavItem(icon: Icons.notes, label: 'All Notes', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.star_border, label: 'Favorites', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.access_time, label: 'Recent', isExpanded: isExpanded, onTap: () {}),

          const SizedBox(height: 16),
          if (isExpanded)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text('FOLDERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),

          // Folders / Labels
          _NavItem(icon: Icons.folder_outlined, label: 'Personal', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.folder_outlined, label: 'Work', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.folder_outlined, label: 'Important', isExpanded: isExpanded, onTap: () {}),

          const Spacer(),
          const Divider(),

          // Bottom Actions
          _NavItem(icon: Icons.delete_outline, label: 'Trash', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.light_mode_outlined, label: 'Light Theme', isExpanded: isExpanded, onTap: () {}),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', isExpanded: isExpanded, onTap: () {}),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Helper widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            if (isExpanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}