import 'package:drift/drift.dart';

class AppKeybindings extends Table {
  // The internal name of the action ('search', 'new_note', 'toggle_menu')
  TextColumn get actionName => text()();

  // The visual label for your KeyHint UI ("S", "N", "M")
  TextColumn get keyLabel => text()();

  // The actual integer ID of the logical key (LogicalKeyboardKey.keyId)
  IntColumn get keyId => integer()();

  // Modifiers
  BoolColumn get useCtrl => boolean().withDefault(const Constant(false))();
  BoolColumn get useAlt => boolean().withDefault(const Constant(false))();
  BoolColumn get useShift => boolean().withDefault(const Constant(false))();
  BoolColumn get useMeta => boolean().withDefault(const Constant(false))(); // Mac Cmd key etc

  // Allows the user to turn off a shortcut without deleting the row
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  // Helps you group shortcuts in your Settings UI ('Global', 'Editor', 'Navigation')
  TextColumn get category => text().withDefault(const Constant('General'))();

  @override
  Set<Column> get primaryKey => {actionName};
}