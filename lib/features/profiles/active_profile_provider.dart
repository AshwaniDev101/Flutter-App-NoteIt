import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/util/logger.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../../features/folders/core/providers.dart';
import '../../features/home/core/providers.dart';
import '../../features/lock/lock_manger/lock_manager.dart';
import '../../features/reminder/reminder_manager.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

/// Riverpod provider managing the currently active user workspace profile.
final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, Profile>(() {
  return ActiveProfileNotifier();
});

class ActiveProfileNotifier extends Notifier<Profile> {
  bool _isSwitching = false;

  @override
  Profile build() {
    final prefs = ref.watch(sharedPreferenceProvider);
    final savedProfileId = prefs.activeProfileId;
    final repo = ProfileRepository.instance;

    if (savedProfileId != null) {
      final profile = repo.getProfileById(savedProfileId);
      if (profile != null) {
        return profile;
      }
    }

    // Default fallback to primary 'Default' profile
    return ProfileRepository.defaultProfile;
  }

  /// Switches the active profile to [targetProfile].
  ///
  /// Executes the clean 6-step switching teardown & re-arm sequence:
  /// 1. Clears active UI selection states (selected note, folder, search query).
  /// 2. Flushes session lock tokens.
  /// 3. Cancels pending OS system notifications for previous profile.
  /// 4. Saves [targetProfile.id] in SharedPreferences & updates `lastUsedAt`.
  /// 5. Updates Riverpod state -> triggers SQLite connection swap via `localDatabaseProvider`.
  /// 6. Re-arms pending reminders from the new active profile's database.
  Future<void> switchProfile(Profile targetProfile) async {
    if (state.id == targetProfile.id || _isSwitching) return;

    _isSwitching = true;
    try {
      AppLogger.d('ActiveProfileNotifier: Switching profile from ${state.name} (${state.id}) to ${targetProfile.name} (${targetProfile.id})...');

      // 1. Clear active UI selection states
      ref.read(activeNoteProvider.notifier).clear();
      ref.read(activeFolderProvider.notifier).clear();
      ref.read(searchQueryProvider.notifier).clear();

      // 2. Clear unlocked note sessions for security
      ref.read(lockManagerProvider.notifier).clearAllSessions();

      // 3. Cancel scheduled local OS notifications for previous profile
      await ReminderManager().cancelAllNotifications();

      // 4. Update SharedPreferences & touch lastUsedAt timestamp
      await ref.read(sharedPreferenceProvider).setActiveProfileId(targetProfile.id);
      await ProfileRepository.instance.touchProfileLastUsed(targetProfile.id);

      // 5. Update state -> triggers Riverpod rebuild & SQLite handle swap
      state = targetProfile;

      // 6. Re-arm pending reminders from newly active profile's database
      ReminderManager().rearmPendingReminders();

      AppLogger.d('ActiveProfileNotifier: Successfully switched active profile to ${targetProfile.name}');
    } finally {
      _isSwitching = false;
    }
  }

  /// Updates the current active profile's metadata without triggering database handle teardown.
  void updateActiveProfile(Profile updatedProfile) {
    if (state.id == updatedProfile.id) {
      state = updatedProfile;
    }
  }
}
