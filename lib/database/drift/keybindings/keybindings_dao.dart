import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_database.dart';
import 'keybindings_table.dart';

part 'keybindings_dao.g.dart';

final keybindingsDaoProvider = Provider(
      (ref) => ref.watch(localDatabaseProvider).keybindingsDao,
);

class AppActions {
  AppActions._();
  static const String search = 'search';
  static const String newNote = 'new_note';
  static const String toggleMenu = 'toggle_menu';
  static const String deleteNote = 'delete_note';
  static const String saveNote = 'save_note';
}

class ShortcutCategories {
  ShortcutCategories._();
  static const String global = 'global';
  static const String navigation = 'navigation';
}

@DriftAccessor(tables: [AppKeybindings])
class KeybindingsDao extends DatabaseAccessor<LocalDatabase> with _$KeybindingsDaoMixin {
  KeybindingsDao(super.db);

  /// Now filters by the current platform and hides soft-deleted settings
  Stream<List<AppKeybinding>> watchKeybindingsForPlatform(String platform) {
    return (select(appKeybindings)
      ..where((t) => t.targetPlatform.equals(platform))
      ..where((t) => t.deletedAt.isNull())
    ).watch();
  }

  /// Platform parameter so seeds are tied to the specific OS
  Future<void> seedDefaultKeybindings(String platform) async {
    // We use insertOrIgnore so we don't overwrite user preferences on app restart!
    await batch((batch) {
      batch.insertAll(
        appKeybindings,
        [
          AppKeybindingsCompanion.insert(
            actionName: AppActions.search,
            targetPlatform: Value(platform), // Part of the new Primary Key
            keyLabel: 'S',
            keyId: LogicalKeyboardKey.keyS.keyId,
            useCtrl: const Value(true),
            category: const Value(ShortcutCategories.global),
          ),
          AppKeybindingsCompanion.insert(
            actionName: AppActions.newNote,
            targetPlatform: Value(platform),
            keyLabel: 'N',
            keyId: LogicalKeyboardKey.keyN.keyId,
            useCtrl: const Value(true),
            category: const Value(ShortcutCategories.global),
          ),
          AppKeybindingsCompanion.insert(
            actionName: AppActions.toggleMenu,
            targetPlatform: Value(platform),
            keyLabel: 'M',
            keyId: LogicalKeyboardKey.keyM.keyId,
            useCtrl: const Value(true),
            category: const Value(ShortcutCategories.navigation),
          ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// .custom() to increment the sync counter, handles targetPlatform,
  /// and safely translates the UI boolean into a sync-safe timestamp.
  Future<bool> updateKeybinding(
      String actionName, {
        required String targetPlatform, // Required because of composite primary key
        required String keyLabel,
        required int keyId,
        bool useCtrl = false,
        bool useAlt = false,
        bool useShift = false,
        bool useMeta = false,
        bool isEnabled = true,
      }) async {

    final updatedCount = await (update(appKeybindings)
      // Look up by BOTH actionName and platform
      ..where((t) => t.actionName.equals(actionName) & t.targetPlatform.equals(targetPlatform)))
        .write(
      AppKeybindingsCompanion.custom(
        keyLabel: Variable(keyLabel),
        keyId: Variable(keyId),
        useCtrl: Variable(useCtrl),
        useAlt: Variable(useAlt),
        useShift: Variable(useShift),
        useMeta: Variable(useMeta),

        // If enabled = true, timestamp is null. If false, record the exact time.
        disabledAt: Variable(isEnabled ? null : DateTime.now().toUtc()),

        // CRITICAL SYNC ENGINE UPDATES
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: appKeybindings.updateCounter + const Constant(1),
      ),
    );

    if (updatedCount == 0) {
      await into(appKeybindings).insert(
        AppKeybindingsCompanion.insert(
          actionName: actionName,
          targetPlatform: Value(targetPlatform),
          keyLabel: keyLabel,
          keyId: keyId,
          useCtrl: Value(useCtrl),
          useAlt: Value(useAlt),
          useShift: Value(useShift),
          useMeta: Value(useMeta),
          disabledAt: Value(isEnabled ? null : DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
    return true;
  }

  /// Soft delete a keybinding if the user wants to completely clear it
  /// (Syncs the deletion to their other devices)
  Future<void> softDeleteKeybinding(String actionName, String targetPlatform) async {
    await (update(appKeybindings)
      ..where((t) => t.actionName.equals(actionName) & t.targetPlatform.equals(targetPlatform)))
        .write(
      AppKeybindingsCompanion.custom(
        deletedAt: Variable(DateTime.now().toUtc()),
        updatedAt: Variable(DateTime.now().toUtc()),
        updateCounter: appKeybindings.updateCounter + const Constant(1),
      ),
    );
  }
}