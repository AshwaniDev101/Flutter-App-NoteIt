import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/util/logger.dart';
import '../../features/folders/core/providers.dart';
import '../../features/home/core/providers.dart';
import '../../features/reminder/reminder_manager.dart';
import '../shared_preference/shared_preference_manager.dart';

/// Centralized manager & Riverpod provider for switching between the main production database (`note_it_db`)
/// and the sandbox test database (`note_it_db_test`).
final activeDatabaseNameProvider = NotifierProvider<ActiveDatabaseNameNotifier, String>(() {
  return ActiveDatabaseNameNotifier();
});

/// Boolean provider indicating whether the test database (`note_it_db_test`) is currently active.
final isTestDatabaseProvider = Provider<bool>((ref) {
  final activeDb = ref.watch(activeDatabaseNameProvider);
  return activeDb == ActiveDatabaseNameNotifier.testDatabaseName;
});

class ActiveDatabaseNameNotifier extends Notifier<String> {
  static const String mainDatabaseName = 'note_it_db';
  static const String testDatabaseName = 'note_it_db_test';

  @override
  String build() {
    return ref.watch(sharedPreferenceProvider).activeDatabaseName;
  }

  /// Switches the active SQLite database filename to [newName].
  ///
  /// Safely clears active UI selection states (selected note, folder, search query)
  /// and updates Riverpod state, automatically disposing the previous database handle.
  Future<void> setDatabaseName(String newName) async {
    if (state == newName) return;

    AppLogger.d('DatabaseSwitcher: Switching active database from $state to $newName...');

    // 1. Reset active note selection, active folder, and search query to prevent cross-DB ID lookup errors
    ref.read(activeNoteProvider.notifier).clear();
    ref.read(activeFolderProvider.notifier).clear();
    ref.read(searchQueryProvider.notifier).clear();

    // 2. Persist in SharedPreferences & update state
    await ref.read(sharedPreferenceProvider).setActiveDatabaseName(newName);
    state = newName;

    // 3. Re-arm pending reminders from the new active database
    ReminderManager().rearmPendingReminders();

    AppLogger.d('DatabaseSwitcher: Successfully switched active database to $newName');
  }

  /// Toggles between the production database (`note_it_db`) and test database (`note_it_db_test`).
  Future<void> toggleDatabase() async {
    final isTest = state == testDatabaseName;
    final target = isTest ? mainDatabaseName : testDatabaseName;
    await setDatabaseName(target);
  }
}
