import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/logger.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../features/cloud_sync/data/cloud_sync_service.dart';
import '../../../features/folders/core/providers.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
import '../../../features/reminder/reminder_manager.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileSwitchingState {
  final bool isSwitching;
  final Profile? targetProfile;

  const ProfileSwitchingState({
    this.isSwitching = false,
    this.targetProfile,
  });
}

final profileSwitchingProvider = NotifierProvider<ProfileSwitchingNotifier, ProfileSwitchingState>(() {
  return ProfileSwitchingNotifier();
});

class ProfileSwitchingNotifier extends Notifier<ProfileSwitchingState> {
  @override
  ProfileSwitchingState build() => const ProfileSwitchingState();

  void startSwitch(Profile target) {
    state = ProfileSwitchingState(isSwitching: true, targetProfile: target);
  }

  void endSwitch() {
    state = const ProfileSwitchingState(isSwitching: false, targetProfile: null);
  }
}

/// Riverpod provider managing the currently active user workspace profile.
final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, Profile>(() {
  return ActiveProfileNotifier();
});

class ActiveProfileNotifier extends Notifier<Profile> {
  bool _isSwitching = false;

  /// Returns true if a profile switch operation is currently in progress.
  bool get isSwitching => _isSwitching;

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
  /// Executes instant local database handle swap:
  /// 1. Stops active cloud sync listeners.
  /// 2. Clears active UI selection states (selected note, folder, search query).
  /// 3. Flushes session lock tokens.
  /// 4. Cancels pending OS system notifications for previous profile.
  /// 5. Saves [targetProfile.id] in SharedPreferences & updates `lastUsedAt`.
  /// 6. Updates Riverpod state -> triggers SQLite connection swap via `localDatabaseProvider`.
  /// 7. Re-arms pending reminders from the new active profile's database.
  Future<void> switchProfile(Profile targetProfile) async {
    if (state.id == targetProfile.id || _isSwitching) return;

    _isSwitching = true;
    ref.read(profileSwitchingProvider.notifier).startSwitch(targetProfile);
    try {
      AppLogger.d('ActiveProfileNotifier: Switching profile from "${state.name}" (${state.id}) to "${targetProfile.name}" (${targetProfile.id})...');

      // 1. Stop active cloud sync listeners
      ref.read(cloudSyncServiceProvider).stop();

      // 2. Clear active UI selection states
      ref.read(activeNoteProvider.notifier).clear();
      ref.read(activeFolderProvider.notifier).clear();
      ref.read(searchQueryProvider.notifier).clear();

      // 3. Clear unlocked note sessions for security
      ref.read(lockManagerProvider.notifier).clearAllSessions();

      // 4. Cancel scheduled local OS notifications for previous profile
      await ReminderManager().cancelAllNotifications();

      // 5. Update SharedPreferences & touch lastUsedAt timestamp
      await ref.read(sharedPreferenceProvider).setActiveProfileId(targetProfile.id);
      await ProfileRepository.instance.touchProfileLastUsed(targetProfile.id);

      // 6. Update state -> triggers Riverpod rebuild, syncModeProvider update & SQLite handle swap
      state = targetProfile;

      // 7. Re-arm pending reminders from newly active profile's database
      ReminderManager().rearmPendingReminders();

      AppLogger.d('ActiveProfileNotifier: Successfully switched active profile to ${targetProfile.name}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      _isSwitching = false;
      ref.read(profileSwitchingProvider.notifier).endSwitch();
    }
  }

  /// Updates the current active profile's metadata without triggering database handle teardown.
  void updateActiveProfile(Profile updatedProfile) {
    if (state.id == updatedProfile.id) {
      state = updatedProfile;
    }
  }
}
