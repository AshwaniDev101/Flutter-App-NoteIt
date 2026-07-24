import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/features/home_page/screens/view/widgets/notes_grid_view.dart';
import 'package:noteit/features/home_page/screens/view/widgets/sort_options_bar.dart';
import 'package:noteit/features/password_page/screens/view/password_page.dart';
import '../../../../shared/managers/lock_manger/lock_manager.dart';
import '../../../../database/sync_manager.dart';
import '../../../drawer_page/homepage_drawer.dart';
import '../core/home_app_bars.dart';
import '../core/providers.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isSelectMode = false;
  final Set<int> noteIds = {};

  bool isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider.notifier).executeFullSync();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (noteIds.contains(id)) {
        noteIds.remove(id);
        if (noteIds.isEmpty) isSelectMode = false;
      } else {
        noteIds.add(id);
      }
    });
  }

  void _exitSearchMode() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() => isSearchMode = false);
  }

  void _clearSelection() {
    setState(() {
      isSelectMode = false;
      noteIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // Forces Riverpod to keep the SyncManager awake
    ref.watch(syncNotifierProvider);

    return PopScope(
      canPop: !isSelectMode && !isSearchMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (isSelectMode) {
          _clearSelection();
        } else if (isSearchMode) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
        drawer: const HomepageDrawer(),
        appBar: _buildResponsiveAppBar(isAndroid),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.edit),
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSearchMode && !isAndroid) const SortOptionsBar(),
              Expanded(
                child: NotesGridView(
                  isSelectMode: isSelectMode,
                  noteIds: noteIds,
                  onToggleSelection: _toggleSelection,
                  onEnableSelectMode: () => setState(() => isSelectMode = true),
                  onPromptPassword: _promptForPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(bool isAndroid) {
    if (isSelectMode) {
      return SelectModeAppBar(
        noteIds: noteIds,
        onClearSelection: _clearSelection,
        onSelectAll: () {
          final currentNotes = ref.read(filteredNotesProvider).value ?? [];
          final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;
          setState(() {
            if (isAllSelected) {
              _clearSelection();
            } else {
              noteIds.addAll(currentNotes.map((note) => note.id));
            }
          });
        },
      );
    }

    if (isSearchMode) {
      return SearchModeAppBar(
        searchController: _searchController,
        onExitSearchMode: _exitSearchMode,
      );
    }

    return DefaultHomeAppBar(
      isAndroid: isAndroid,
      searchController: _searchController,
      onEnterSearchMode: () => setState(() => isSearchMode = true),
    );
  }

  Future<void> _promptForPassword(BuildContext context, Note note) async {
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const PasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null && enteredPassword.isNotEmpty && context.mounted) {
      final lockManager = ref.read(lockManagerProvider.notifier);

      if (!lockManager.hasMasterPassword) {
        await lockManager.setupMasterPassword(enteredPassword);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Master Password Set!')));
      }

      final success = lockManager.verifyAndSessionUnlock(note.id, enteredPassword);
      if (success) {
        context.push(AppRoutes.edit, extra: note);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
      }
    }
  }
}