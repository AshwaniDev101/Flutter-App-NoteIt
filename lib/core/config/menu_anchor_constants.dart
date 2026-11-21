/// Centralized semantic width constants for popups, dropdowns, and context menus.
class AppMenuWidths {
  const AppMenuWidths._();

  /// Compact menu width for quick note actions (e.g. NoteCard context menu).
  static const double compact = 180.0;

  /// Standard menu width for folder options, drawer, and adaptive menus (sort/view/filter).
  static const double standard = 280.0;

  /// Wide menu width for content-heavy panels (e.g. Workspace and Sync status menus).
  static const double wide = 340.0;

  /// Specialized menu width for note editor options.
  static const double editor = 196.0;
}
