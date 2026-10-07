import 'package:flutter/material.dart';

class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // Large UI Elements (Empty states, Settings headers)
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0), // * class_HostBroadcast-PairingPIN, class_PinEntryDialog-PINInput
    // displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0), // Redundant / Unused
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0), // * class_RoleSelectorPage-Title

    // Dialog Headers & App Bars
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0), // * class_ImportPage-Title
    // headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15), // Redundant / Unused
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.15), // * class_DevPage-SectionTitle, class_HostBroadcast-DeviceName, class_PinEntryDialog-Title

    // Note Title
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0), // * class_ExportPage-Headers, class_DrawerPage-Profile, class_DesktopLeftPanel-Title, class_DesktopEditPage-NoteTitle
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15), // * class_NoteCard-Title, class_RoleSelectorPage-RoleTile-Title, class_MobileEditPage-NoteTitle, class_SettingsPage-TileTitle
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1), // * class_HomepageDrawer-SectionTitle, class_SettingsPage-SectionTitle

    // Note Body
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5), // * class_DesktopEditPage-ContentEditor, class_MobileEditPage-ContentEditor
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.45), // * class_NoteCard-ContentBody, class_RoleSelectorPage-Description, class_SettingsPage-Subtitle, class_SnackBarManager-Text
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4), // * class_NoteEditorOptions-OptionLabel, class_RoleSelectorPage-RoleBadge, class_DesktopEditPage-Timestamp, class_TagSortViewMenu-SearchInput

    // Metadata (Timestamps, bottom row)
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1), // * class_HostBroadcast-PairingPINHeader
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5), // * class_NoteCard-Timestamp, class_DesktopEditPage-StatusBadge, class_HomepageDrawer-SectionHeader
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5), // * class_RoleSelectorPage-RecommendedBadge, class_SmartActionWidget-ShortcutLabel, class_MobileEditPage-StatusBadge
  );
}
