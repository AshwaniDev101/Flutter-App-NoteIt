// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keybindings_dao.dart';

// ignore_for_file: type=lint
mixin _$KeybindingsDaoMixin on DatabaseAccessor<LocalDatabase> {
  $AppKeybindingsTable get appKeybindings => attachedDatabase.appKeybindings;
  KeybindingsDaoManager get managers => KeybindingsDaoManager(this);
}

class KeybindingsDaoManager {
  final _$KeybindingsDaoMixin _db;
  KeybindingsDaoManager(this._db);
  $$AppKeybindingsTableTableManager get appKeybindings =>
      $$AppKeybindingsTableTableManager(
        _db.attachedDatabase,
        _db.appKeybindings,
      );
}
