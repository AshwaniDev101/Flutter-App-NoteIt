import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

// ==== Server side ===

// Registration? is the State type that will be returned, while MdnsHostNotifier is responsible for running the functions.
// In-short mean provider is returning object of Registration when the server is broadcasting, else it returns null
final mdnsBroadcastProvider =
    NotifierProvider<MdnsBroadcastNotifier, Registration?>(() {
      return MdnsBroadcastNotifier();
    });

class MdnsBroadcastNotifier extends Notifier<Registration?> {
  // Sets the initial state when the provider is first created.
  // Default is null (server is not broadcasting yet).
  @override
  Registration? build() => null;

  Future<void> startBroadcasting({
    required int port,
    required String uuid,
    required String deviceName,
  }) async {
    if (state != null) return; // If server is already broadcasting, do nothing

    // Creates the service
    try {
      final service = Service(
        name: deviceName,
        type: '_http._tcp',
        port: port,
        txt: {'uuid': utf8.encode(uuid)},
      );

      // Registers the service
      final registration = await register(service);
      print('mDNS: Broadcasting as ${registration.service.name} on port $port');

      // Save the registration object to state so we can cancel it later
      state = registration;
    } catch (e) {
      print('mDNS Host Error: $e');
    }
  }

  /// Call this when the user clicks "Stop Syncing" or closes the app
  Future<void> stopBroadcasting() async {
    if (state != null) {
      await unregister(state!);
      print('mDNS: Stopped broadcasting');
      state = null;
    }
  }
}
