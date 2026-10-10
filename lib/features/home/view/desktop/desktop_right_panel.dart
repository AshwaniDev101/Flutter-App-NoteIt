import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../dev_tools/dev_page.dart';
import '../../../drawer/app_drawer.dart';
import '../../../local_sync/view/role_selector_page.dart';
import '../../../note_editor/screens/view/desktop_edit_page.dart';
import '../../../settings/view/settings_page.dart';
import '../../../themes/view/theme_page.dart';
import '../../../trash/trash_page.dart';
import '../../core/providers.dart';

class DesktopRightPanel extends ConsumerWidget {
  final Note? activeNote;

  const DesktopRightPanel({super.key, required this.activeNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    final currentView = ref.watch(desktopRightPanelViewProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(
            elevation: 0,

            // Automatically show the current page title
            // title: currentView != DrawerOption.allNotes
            //     ? Text(currentView.title)
            //     : null,
            scrolledUnderElevation: PlatformHelper.isDesktopScreen? 0.0 : null,

            actions: [
              // WebSocketConnectionIndicator(isConnected: isConnected),
              IconTray(),
              const SizedBox(width: 8),
              // Re-add standard window controls manually for desktop frame logic
              IconButton(icon: const Icon(Icons.minimize, size: 16), onPressed: () => windowManager.minimize()),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 16),
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => windowManager.close()),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),

      // Inject the Editor widget if a note is selected, otherwise show a placeholder graphic.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOutCubic,
        // Decelerates smoothly into place
        switchOutCurve: Curves.easeIn,

        transitionBuilder: (Widget child, Animation<double> animation) {
          // Scale from 96% to 100% while fading in
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },

        // The ValueKey is important here. It tells the AnimatedSwitcher when to trigger!
        child: switch (currentView) {
        // The Empty/None State
        //   DrawerOption.none => const _HomepagePlaceholder(key: ValueKey('none_view')),

        // The Editor State
        // We keep the fallback just in case the activeNote gets cleared while still in editor mode
          DrawerOption.allNotes => activeNote != null
              ? DesktopEditNotePage(key: ValueKey(activeNote!.uuid), existingNote: activeNote)
              : const _HomepagePlaceholder(key: ValueKey('editor_fallback')),

        // The Utility Panels
          DrawerOption.trash => const TrashPage(key: ValueKey('trash_view')),
          DrawerOption.settings => const SettingsPage(key: ValueKey('settings_view')),

        // New panels mapped to their respective widgets
          DrawerOption.localSync => const RoleSelectorPage(key: ValueKey('sync_view')),
          DrawerOption.themes => const ThemesPage(key: ValueKey('theme_view')),
          DrawerOption.devTools => const DevPage(key: ValueKey('dev_view')),
        },
      ),
    );
  }
}

/// A visual placeholder shown when no note is currently selected.
class _HomepagePlaceholder extends StatelessWidget {
  const _HomepagePlaceholder({super.key,});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 64),
          const SizedBox(height: 16),
          Text('No note selected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Select a note from the list or click + to start editing.'),
        ],
      ),
    );
  }
}
