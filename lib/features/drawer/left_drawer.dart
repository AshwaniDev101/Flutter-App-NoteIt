import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/folders/view/folders.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class LeftDrawer extends ConsumerWidget {
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

  const LeftDrawer({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header / Toggle Button
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 12.0),
          child: Row(
            mainAxisAlignment:
            isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onToggle,
                tooltip: 'Toggle Sidebar',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (isExpanded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'NoteIt',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurface,
                      ),
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
          child: FilledButton(
            onPressed: onAddNote,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 10.0 : 0.0, vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 22),
                if (isExpanded)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        'New Note',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Main Navigation
        // Removed `isSelected: true` so it no longer has a background color
        _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'All Notes', isExpanded: isExpanded, isSelected: false, onTap: () {}),

        const SizedBox(height: 16),

        // Responsive Folder Area
        if (isExpanded)
          const Expanded(
            child: FolderContainer(),
          )
        else
          const FolderMenuButton(),

        // Replaced Spacer with a fixed sized box since Expanded takes the rest
        if (!isExpanded) const Spacer(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
        ),
        const SizedBox(height: 8),

        // Bottom Actions
        _NavItem(icon: RightPanelPageOptions.archivePage.icon, label: RightPanelPageOptions.archivePage.label, isExpanded: isExpanded, onTap: () {}),
        _NavItem(icon: Icons.delete_outline_rounded, label: 'Trash', isExpanded: isExpanded, onTap: () {}),
        _NavItem(icon: Icons.light_mode_outlined, label: 'Light Theme', isExpanded: isExpanded, onTap: () {}),
        _NavItem(icon: RightPanelPageOptions.localSync.icon, label: RightPanelPageOptions.localSync.label, isExpanded: isExpanded, onTap: () {}),
        _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', isExpanded: isExpanded, onTap: () {}),
        const SizedBox(height: 12),
      ],
    );
  }
}


/// Helper widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isExpanded,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),

            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10.0 : 0.0),
            child: Row(
              mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? (activeIcon ?? icon) : icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                if (isExpanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}