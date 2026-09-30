import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_database.dart';
import 'keybindings_table.dart';

part 'keybindings_dao.g.dart';

final keybindingsDaoProvider = Provider(
      (ref) => ref.watch(localDatabaseProvider).keybindingsDao,
);

@DriftAccessor(tables: [AppKeybindings])
class KeybindingsDao extends DatabaseAccessor<LocalDatabase> with _$KeybindingsDaoMixin {
  KeybindingsDao(super.db);

  Stream<List<AppKeybinding>> watchAllKeybindings() {
    return select(appKeybindings).watch();
  }

  Future<void> seedDefaultKeybindings() async {
    // We use insertOrIgnore instead!
    await batch((batch) {
      batch.insertAll(
        appKeybindings,
        [
          AppKeybindingsCompanion.insert(
            actionName: 'search',
            keyLabel: 'S',
            keyId: LogicalKeyboardKey.keyS.keyId,
            useCtrl: const Value(true),
            category: const Value('Global'), // Group for settings UI
          ),
          AppKeybindingsCompanion.insert(
            actionName: 'new_note',
            keyLabel: 'N',
            keyId: LogicalKeyboardKey.keyN.keyId,
            useCtrl: const Value(true),
            category: const Value('Global'),
          ),
          AppKeybindingsCompanion.insert(
            actionName: 'toggle_menu',
            keyLabel: 'M',
            keyId: LogicalKeyboardKey.keyM.keyId,
            useCtrl: const Value(true),
            category: const Value('Navigation'),
          ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<bool> updateKeybinding(
      String actionName, {
        required String keyLabel,
        required int keyId,
        bool useCtrl = false,
        bool useAlt = false,
        bool useShift = false,
        bool useMeta = false,
        bool isEnabled = true, // Added support for toggling
      }) async {
    return await (update(appKeybindings)..where((t) => t.actionName.equals(actionName))).write(
      AppKeybindingsCompanion(
        keyLabel: Value(keyLabel),
        keyId: Value(keyId),
        useCtrl: Value(useCtrl),
        useAlt: Value(useAlt),
        useShift: Value(useShift),
        useMeta: Value(useMeta),
        isEnabled: Value(isEnabled),
      ),
    ) > 0;
  }
}