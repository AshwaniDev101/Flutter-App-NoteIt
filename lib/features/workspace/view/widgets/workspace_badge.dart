import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../../../shared/menus/app_bottom_sheet.dart';
import '../../providers/active_workspace_provider.dart';
import '../../providers/workspace_providers.dart';
import '../workspace_menu_content.dart';
import 'workspace_avatar_badge.dart';

class WorkspaceBadge extends ConsumerStatefulWidget {
  const WorkspaceBadge({super.key});

  @override
  ConsumerState<WorkspaceBadge> createState() => _WorkspaceBadgeState();
}

class _WorkspaceBadgeState extends ConsumerState<WorkspaceBadge> {
  final MenuController _menuController = MenuController();

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (bottomSheetContext, setModalState) {
        return WorkspaceMenuContent(
          onCloseMenu: () => Navigator.of(bottomSheetContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWorkspaceEnabled = ref.watch(workspaceEnableProvider);
    if (!isWorkspaceEnabled) {
      return const SizedBox.shrink();
    }

    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = !PlatformHelper.isWideLayout(context);

    void openWorkspaceMenu() {
      if (isMobile) {
        _showMobileBottomSheet(context);
      } else {
        if (_menuController.isOpen) {
          _menuController.close();
        } else {
          _menuController.open();
        }
      }
    }

    final avatarWidget = WorkspaceAvatarBadge(
      activeWorkspaceName: activeWorkspace.name,
      photoUrl: null,
      onTap: openWorkspaceMenu,
    );

    if (isMobile) {
      return avatarWidget;
    }

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return avatarWidget;
      },
      menuChildren: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(4),
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: WorkspaceMenuContent(
                onCloseMenu: () {
                  if (_menuController.isOpen) _menuController.close();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
