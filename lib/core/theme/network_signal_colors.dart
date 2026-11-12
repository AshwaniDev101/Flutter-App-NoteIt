import 'package:flutter/material.dart';

@immutable
class NetworkSignalColors extends ThemeExtension<NetworkSignalColors> {
  final Color connected;
  final Color connecting;
  final Color weakSignal;
  final Color failed;
  final Color pinRequired;

  const NetworkSignalColors({
    required this.connected,
    required this.connecting,
    required this.weakSignal,
    required this.failed,
    required this.pinRequired,
  });

  factory NetworkSignalColors.dark() => const NetworkSignalColors(
        connected: Color(0xFF66BB6A),
        connecting: Color(0xFFFFB74D),
        weakSignal: Color(0xFFFFB74D),
        failed: Color(0xFFEF5350),
        pinRequired: Color(0xFFFFB74D),
      );

  factory NetworkSignalColors.light() => const NetworkSignalColors(
        connected: Color(0xFF2E7D32),
        connecting: Color(0xFFE65100),
        weakSignal: Color(0xFFE65100),
        failed: Color(0xFFC62828),
        pinRequired: Color(0xFFE65100),
      );

  factory NetworkSignalColors.amoled() => const NetworkSignalColors(
        connected: Color(0xFF51CF66),
        connecting: Color(0xFFFCC419),
        weakSignal: Color(0xFFFCC419),
        failed: Color(0xFFFF6B6B),
        pinRequired: Color(0xFFFCC419),
      );

  factory NetworkSignalColors.sepia() => const NetworkSignalColors(
        connected: Color(0xFF388E3C),
        connecting: Color(0xFFF57C00),
        weakSignal: Color(0xFFF57C00),
        failed: Color(0xFFB0533C),
        pinRequired: Color(0xFFF57C00),
      );

  factory NetworkSignalColors.dracula() => const NetworkSignalColors(
        connected: Color(0xFF50FA7B),
        connecting: Color(0xFFFFB86C),
        weakSignal: Color(0xFFFFB86C),
        failed: Color(0xFFFF5555),
        pinRequired: Color(0xFFFFB86C),
      );

  factory NetworkSignalColors.nord() => const NetworkSignalColors(
        connected: Color(0xFFA3BE8C),
        connecting: Color(0xFFEBCB8B),
        weakSignal: Color(0xFFEBCB8B),
        failed: Color(0xFFBF616A),
        pinRequired: Color(0xFFEBCB8B),
      );

  factory NetworkSignalColors.catppuccin() => const NetworkSignalColors(
        connected: Color(0xFFA6E3A1),
        connecting: Color(0xFFFAB387),
        weakSignal: Color(0xFFFAB387),
        failed: Color(0xFFF38BA8),
        pinRequired: Color(0xFFFAB387),
      );

  factory NetworkSignalColors.forest() => const NetworkSignalColors(
        connected: Color(0xFF52B788),
        connecting: Color(0xFFD8A47F),
        weakSignal: Color(0xFFD8A47F),
        failed: Color(0xFFE56B6F),
        pinRequired: Color(0xFFD8A47F),
      );

  factory NetworkSignalColors.cyberpunk() => const NetworkSignalColors(
        connected: Color(0xFF00FF9D),
        connecting: Color(0xFFFFB800),
        weakSignal: Color(0xFFFFB800),
        failed: Color(0xFFFF3344),
        pinRequired: Color(0xFFFFB800),
      );

  factory NetworkSignalColors.ocean() => const NetworkSignalColors(
        connected: Color(0xFF2E7D32),
        connecting: Color(0xFFF77F00),
        weakSignal: Color(0xFFF77F00),
        failed: Color(0xFFD90429),
        pinRequired: Color(0xFFF77F00),
      );

  @override
  NetworkSignalColors copyWith({
    Color? connected,
    Color? connecting,
    Color? weakSignal,
    Color? failed,
    Color? pinRequired,
  }) {
    return NetworkSignalColors(
      connected: connected ?? this.connected,
      connecting: connecting ?? this.connecting,
      weakSignal: weakSignal ?? this.weakSignal,
      failed: failed ?? this.failed,
      pinRequired: pinRequired ?? this.pinRequired,
    );
  }

  @override
  NetworkSignalColors lerp(ThemeExtension<NetworkSignalColors>? other, double t) {
    if (other is! NetworkSignalColors) return this;
    return NetworkSignalColors(
      connected: Color.lerp(connected, other.connected, t)!,
      connecting: Color.lerp(connecting, other.connecting, t)!,
      weakSignal: Color.lerp(weakSignal, other.weakSignal, t)!,
      failed: Color.lerp(failed, other.failed, t)!,
      pinRequired: Color.lerp(pinRequired, other.pinRequired, t)!,
    );
  }
}
