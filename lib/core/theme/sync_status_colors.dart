import 'package:flutter/material.dart';

@immutable
class SyncStatusColors extends ThemeExtension<SyncStatusColors> {
  final Color synced;
  final Color syncing;
  final Color hosting;
  final Color searching;
  final Color reconnecting;
  final Color unauthenticated;
  final Color disconnected;
  final Color offline;

  const SyncStatusColors({
    required this.synced,
    required this.syncing,
    required this.hosting,
    required this.searching,
    required this.reconnecting,
    required this.unauthenticated,
    required this.disconnected,
    required this.offline,
  });

  factory SyncStatusColors.dark() => const SyncStatusColors(
        synced: Color(0xFF4CAF50),
        syncing: Color(0xFF64B5F6),
        hosting: Color(0xFFE2E6FF),
        searching: Color(0xFF4DD0E1),
        reconnecting: Color(0xFFFFB74D),
        unauthenticated: Color(0xFFFFB74D),
        disconnected: Color(0xFF8F95B2),
        offline: Color(0xFF8F95B2),
      );

  factory SyncStatusColors.light() => const SyncStatusColors(
        synced: Color(0xFF2E7D32),
        syncing: Color(0xFF1976D2),
        hosting: Color(0xFF292524),
        searching: Color(0xFF00838F),
        reconnecting: Color(0xFFE65100),
        unauthenticated: Color(0xFFE65100),
        disconnected: Color(0xFF78716C),
        offline: Color(0xFF78716C),
      );

  factory SyncStatusColors.amoled() => const SyncStatusColors(
        synced: Color(0xFF66BB6A),
        syncing: Color(0xFF90CAF9),
        hosting: Color(0xFFE0E0E0),
        searching: Color(0xFF80DEEA),
        reconnecting: Color(0xFFFFCC80),
        unauthenticated: Color(0xFFFFCC80),
        disconnected: Color(0xFFA0A0A0),
        offline: Color(0xFFA0A0A0),
      );

  factory SyncStatusColors.sepia() => const SyncStatusColors(
        synced: Color(0xFF388E3C),
        syncing: Color(0xFF1E88E5),
        hosting: Color(0xFF433422),
        searching: Color(0xFF0097A7),
        reconnecting: Color(0xFFF57C00),
        unauthenticated: Color(0xFFF57C00),
        disconnected: Color(0xFF78624E),
        offline: Color(0xFF78624E),
      );

  factory SyncStatusColors.dracula() => const SyncStatusColors(
        synced: Color(0xFF50FA7B),
        syncing: Color(0xFF8BE9FD),
        hosting: Color(0xFFF8F8F2),
        searching: Color(0xFF8BE9FD),
        reconnecting: Color(0xFFFFB86C),
        unauthenticated: Color(0xFFFFB86C),
        disconnected: Color(0xFF6272A4),
        offline: Color(0xFF6272A4),
      );

  factory SyncStatusColors.nord() => const SyncStatusColors(
        synced: Color(0xFFA3BE8C),
        syncing: Color(0xFF88C0D0),
        hosting: Color(0xFFECEFF4),
        searching: Color(0xFF81A1C1),
        reconnecting: Color(0xFFEBCB8B),
        unauthenticated: Color(0xFFEBCB8B),
        disconnected: Color(0xFFD8DEE9),
        offline: Color(0xFFD8DEE9),
      );

  factory SyncStatusColors.catppuccin() => const SyncStatusColors(
        synced: Color(0xFFA6E3A1),
        syncing: Color(0xFF89B4FA),
        hosting: Color(0xFFCDD6F4),
        searching: Color(0xFF74C7EC),
        reconnecting: Color(0xFFFAB387),
        unauthenticated: Color(0xFFFAB387),
        disconnected: Color(0xFFA6ADC8),
        offline: Color(0xFFA6ADC8),
      );

  factory SyncStatusColors.forest() => const SyncStatusColors(
        synced: Color(0xFF52B788),
        syncing: Color(0xFF74C7EC),
        hosting: Color(0xFFE8F5E9),
        searching: Color(0xFF95D5B2),
        reconnecting: Color(0xFFD8A47F),
        unauthenticated: Color(0xFFD8A47F),
        disconnected: Color(0xFF94A89A),
        offline: Color(0xFF94A89A),
      );

  factory SyncStatusColors.cyberpunk() => const SyncStatusColors(
        synced: Color(0xFF00FF9D),
        syncing: Color(0xFF00F0FF),
        hosting: Color(0xFFF1EBF9),
        searching: Color(0xFF00F0FF),
        reconnecting: Color(0xFFFFB800),
        unauthenticated: Color(0xFFFFB800),
        disconnected: Color(0xFFA59ABF),
        offline: Color(0xFFA59ABF),
      );

  factory SyncStatusColors.ocean() => const SyncStatusColors(
        synced: Color(0xFF2E7D32),
        syncing: Color(0xFF1E6091),
        hosting: Color(0xFF102A43),
        searching: Color(0xFF00838F),
        reconnecting: Color(0xFFE65100),
        unauthenticated: Color(0xFFE65100),
        disconnected: Color(0xFF486581),
        offline: Color(0xFF486581),
      );

  @override
  SyncStatusColors copyWith({
    Color? synced,
    Color? syncing,
    Color? hosting,
    Color? searching,
    Color? reconnecting,
    Color? unauthenticated,
    Color? disconnected,
    Color? offline,
  }) {
    return SyncStatusColors(
      synced: synced ?? this.synced,
      syncing: syncing ?? this.syncing,
      hosting: hosting ?? this.hosting,
      searching: searching ?? this.searching,
      reconnecting: reconnecting ?? this.reconnecting,
      unauthenticated: unauthenticated ?? this.unauthenticated,
      disconnected: disconnected ?? this.disconnected,
      offline: offline ?? this.offline,
    );
  }

  @override
  SyncStatusColors lerp(ThemeExtension<SyncStatusColors>? other, double t) {
    if (other is! SyncStatusColors) return this;
    return SyncStatusColors(
      synced: Color.lerp(synced, other.synced, t)!,
      syncing: Color.lerp(syncing, other.syncing, t)!,
      hosting: Color.lerp(hosting, other.hosting, t)!,
      searching: Color.lerp(searching, other.searching, t)!,
      reconnecting: Color.lerp(reconnecting, other.reconnecting, t)!,
      unauthenticated: Color.lerp(unauthenticated, other.unauthenticated, t)!,
      disconnected: Color.lerp(disconnected, other.disconnected, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }
}
