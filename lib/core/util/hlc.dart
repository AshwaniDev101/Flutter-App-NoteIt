import 'package:flutter/foundation.dart';

/// Hybrid Logical Clock (HLC) helper for NoteIt.
///
/// Combines physical UTC wall clock time, a logical monotonic counter,
/// and a unique device identifier into a sortable string:
/// `2026-03-30T15:00:00.000Z_000001_DESKTOP-ABC`
///
/// Lexicographical string comparison on HLC strings provides a total ordering
/// that guarantees deterministic Last-Write-Wins (LWW) conflict resolution
/// without relying strictly on physical system clocks.
@immutable
class Hlc implements Comparable<Hlc> {
  final DateTime physicalTime;
  final int counter;
  final String deviceId;

  const Hlc({
    required this.physicalTime,
    required this.counter,
    required this.deviceId,
  });

  /// Formats the HLC into a standardized, sortable string.
  String pack() {
    final isoString = physicalTime.toUtc().toIso8601String();
    final paddedCounter = counter.toString().padLeft(6, '0');
    final sanitizedDeviceId = deviceId.replaceAll('_', '-');
    return '${isoString}_${paddedCounter}_$sanitizedDeviceId';
  }

  @override
  String toString() => pack();

  /// Generates a fresh HLC string for the local device.
  ///
  /// Protects against wall-clock skew by ensuring physical time is at least
  /// [lastKnownTime] + 1ms if system clock was set backwards.
  static String generate({
    required String deviceId,
    int counter = 1,
    DateTime? lastKnownTime,
  }) {
    var nowUtc = DateTime.now().toUtc();

    if (lastKnownTime != null && nowUtc.isBefore(lastKnownTime)) {
      nowUtc = lastKnownTime.add(const Duration(milliseconds: 1));
    }

    final hlc = Hlc(
      physicalTime: nowUtc,
      counter: counter,
      deviceId: deviceId,
    );

    return hlc.pack();
  }

  /// Parses an HLC string back into an [Hlc] object.
  static Hlc? parse(String? hlcString) {
    if (hlcString == null || hlcString.isEmpty) return null;

    final parts = hlcString.split('_');
    if (parts.length < 3) return null;

    try {
      final physicalTime = DateTime.parse(parts[0]).toUtc();
      final counter = int.parse(parts[1]);
      final deviceId = parts.sublist(2).join('_');

      return Hlc(
        physicalTime: physicalTime,
        counter: counter,
        deviceId: deviceId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compares two HLC strings lexicographically.
  /// Returns > 0 if [hlcA] is newer than [hlcB].
  static int compareStrings(String? hlcA, String? hlcB) {
    if (hlcA == null && hlcB == null) return 0;
    if (hlcA == null) return -1;
    if (hlcB == null) return 1;
    return hlcA.compareTo(hlcB);
  }

  @override
  int compareTo(Hlc other) {
    final timeComp = physicalTime.compareTo(other.physicalTime);
    if (timeComp != 0) return timeComp;

    final counterComp = counter.compareTo(other.counter);
    if (counterComp != 0) return counterComp;

    return deviceId.compareTo(other.deviceId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hlc &&
        other.physicalTime == physicalTime &&
        other.counter == counter &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(physicalTime, counter, deviceId);
}
