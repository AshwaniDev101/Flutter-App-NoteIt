# Restructure SharedPreferenceManager

This plan outlines the steps to refactor the monolithic `SharedPreferenceManager` into smaller, domain-specific preference classes following the Single Responsibility Principle (SRP) and leveraging Riverpod for dependency injection. This will improve code maintainability, testability, and reduce the likelihood of merge conflicts.

## User Review Required

> [!IMPORTANT]
> The current `SharedPreferenceManager` has a `reminderSoundListenable` which is a `ValueNotifier<bool>`. We need to decide how to handle this reactive state in the new structure. A Riverpod `StateNotifier` or `Notifier` would be the idiomatic way to handle this, rather than a raw `ValueNotifier` inside the preferences class. I will migrate this to a proper Riverpod provider in the `ReminderPreferences` module.

> [!IMPORTANT]
> To avoid breaking the app during the transition, I propose a phased approach. First, we'll set up the base `SharedPreferences` provider. Then, we'll create the new domain-specific classes. Finally, we'll update the usages in the app. However, given the scope, I will create the new structure and map the methods. You will need to manually update the UI/Business logic files to use the new providers where applicable, as doing it all automatically might cause unforeseen issues if not carefully tested.

## Open Questions

1. Are you okay with migrating the `reminderSoundListenable` (`ValueNotifier`) to a standard Riverpod `NotifierProvider`? This is highly recommended when using Riverpod.
2. The current `SharedPreferenceManager.clearAll()` clears *everything*. We will keep a global utility for this, but should it be tied to a specific domain (like Auth/Session) or left as a global utility?

## Proposed Changes

We will introduce a central `SharedPreferences` provider and then split the preferences into feature-based repositories.

### Core Providers

#### [NEW] `lib/core/providers/shared_prefs_provider.dart`
Will contain the base Riverpod provider that holds the initialized `SharedPreferences` instance.
```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});
```

### Domain Preferences

We will create the following files, moving the respective keys and methods from `SharedPreferenceManager` into them:

#### [NEW] `lib/database/shared_preference/sync_preferences.dart`
- Moves keys: `_keySyncMode`, `_keyHostUuid`, `_keyLastSyncTime`, `_keyLastCloudSyncTime`.
- Moves methods related to `SyncMode`, `SyncEngine`, `SyncRole`, and timestamps.
- Exposes `syncPreferencesProvider`.

#### [NEW] `lib/database/shared_preference/theme_preferences.dart`
- Moves keys: `_keyThemeType`, `_keyShowDynamicKeyHints`, `_keyAppendShortcutToTooltips`.
- Moves methods related to theme and interface hints.
- Exposes `themePreferencesProvider`.

#### [NEW] `lib/database/shared_preference/security_preferences.dart`
- Moves keys: `_keyMasterPassword`, `_keyHasMasterPassword`, `_keyKeepUnlockedSession`.
- Moves methods related to master password and session lock.
- Exposes `securityPreferencesProvider`.

#### [NEW] `lib/database/shared_preference/note_view_preferences.dart`
- Moves keys related to active folder/note, view types, and sort options (e.g., `_keyLastActiveFolderId`, `_keyPageViewPrefix`).
- Moves methods related to page view and sorting.
- Exposes `noteViewPreferencesProvider`.

#### [NEW] `lib/database/shared_preference/layout_preferences.dart`
- Moves keys: `_keyWindowWidth`, `_keyDefaultWindowWidth`, `_keyWindowHeight`, `_keyListPanelWidth`, etc.
- Moves methods related to window and panel dimensions.
- Exposes `layoutPreferencesProvider`.

#### [NEW] `lib/database/shared_preference/editor_preferences.dart`
- Moves keys: `_keyPutCursorOnContent`, `_keyTitleFontSize`, `_keyContentFontSize`, `_keyLineSpacing`.
- Moves methods related to editor configuration.
- Exposes `editorPreferencesProvider`.

#### [NEW] `lib/database/shared_preference/reminder_preferences.dart`
- Moves keys: `_keyCustomSoundPath`, `_keyCustomSoundName`, `_keyReminderSoundEnabled`, etc.
- Moves methods related to reminder configuration.
- Exposes `reminderPreferencesProvider`.
- **Note:** Will include a Riverpod Notifier for `reminderSoundEnabled` state.

#### [NEW] `lib/database/shared_preference/date_time_preferences.dart`
- Moves keys: `_keyTimeUseSystemFormat`, `_keyTimeIs24Hour`, `_keyTimeDayFormat`, etc.
- Moves methods related to date/time formatting.
- Exposes `dateTimePreferencesProvider`.

#### [NEW] `lib/database/shared_preference/workspace_preferences.dart`
- Moves keys: `_keyActiveWorkspaceId`, `_keyEnableWorkspace`, `_keyShowDeviceFilter`.
- Moves methods related to workspaces.
- Exposes `workspacePreferencesProvider`.

### Deprecation & Transition

#### [MODIFY] `lib/database/shared_preference/shared_preference_manager.dart`
- We will deprecate this class but keep it temporarily intact (or route its methods to the new providers) so the app compiles while you transition the UI/Notifier code to use the new domain-specific providers.
- We will add the `clearAll` method to a utility or keep it here temporarily.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors in the new files.

### Manual Verification
- Update `main.dart` to override `sharedPreferencesProvider` with the initialized instance.
- Check that the app compiles.
- Gradually replace usages of `SharedPreferenceManager.instance` in the app's widgets and notifiers with the specific feature providers (e.g., `ref.watch(themePreferencesProvider)`). Verify that settings still load and save correctly.