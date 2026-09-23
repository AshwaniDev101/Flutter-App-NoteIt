import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

// ==== Server side ===

// Registration? is the State type that will be returned, while MdnsHostNotifier is responsible for running the functions.
// In-short mean provider is returning object of Registration when the server is broadcasting, else it returns null
final mdnsBroadcastProvider =
    NotifierProvider.autoDispose<MdnsBroadcastNotifier, Registration?>(() {
      return MdnsBroadcastNotifier();
    });

class MdnsBroadcastNotifier extends Notifier<Registration?> {
  // Sets the initial state when the provider is first created.
  // Default is null (server is not broadcasting yet).

  // It is for tracking the background task
  Registration? _activeRegistration;

  @override
  Registration? build() {
    ref.onDispose(() {
      // This completely bypasses Riverpod's strict teardown locks.
      if (_activeRegistration != null) {
        unregister(_activeRegistration!).then((_) {
          print('mDNS: Stopped broadcasting (auto-disposed)');
        }).catchError((e) {
          print('mDNS cleanup error: $e');
        });
      }
    });
    return null;
  }

  Future<void> startBroadcasting({
    required int port,
    required String uuid,
    required String deviceName,
  }) async {
    if (_activeRegistration != null) return; // If server is already broadcasting, do nothing

    // Creates the service
    try {
      final service = Service(
        name: deviceName,
        type: '_noteitsync._tcp',
        port: port,
        txt: {'uuid': utf8.encode(uuid)},
      );

      // Registers the service
      final registration = await register(service);
      print('mDNS: Broadcasting as ${registration.service.name} on port $port');

      // Save the registration object to state so we can cancel it later
      _activeRegistration = registration;
      state = registration;
    } catch (e) {
      print('mDNS Host Error: $e');
    }
  }

  /// Call this ONLY if you need a manual button to stop syncing while staying on the page.
  /// (The onDispose block handles the automatic cleanup when leaving the page).
  Future<void> stopBroadcasting() async {
    if (_activeRegistration != null) {
      final regToCancel = _activeRegistration!;

      // Clear both references
      _activeRegistration = null;
      state = null;

      await unregister(regToCancel);
      print('mDNS: Stopped broadcasting manually');
    }
  }
}
