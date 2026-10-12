import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config.dart';
import 'package:nsd/nsd.dart';

import '../../../core/app_env.dart';
import '../../../core/device_info.dart';
import '../../../core/util/logger.dart';
import '../provider/sync_session_provider.dart';
import 'mdns_searcher.dart';

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

  // It is for tracking the background task
  Registration? _activeRegistration;

  @override
  Registration? build() {
    ref.onDispose(() {
      // This completely bypasses Riverpod's strict teardown locks.
      if (_activeRegistration != null) {
        unregister(_activeRegistration!).then((_) {
          AppLogger.d('mDNS: Stopped broadcasting (auto-disposed)');
        }).catchError((e) {
          AppLogger.d('mDNS cleanup error: $e');
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

    // --- POLICE CODE ---
    AppLogger.d('mDNS Police: Stopping any active scans before broadcasting.');
    ref.read(mdnsSearcherProvider.notifier).stopScan();
    // -------------------
    if (_activeRegistration != null) return; // If server is already broadcasting, do nothing

    // Creates the service
    try {
      // Fetch your local device type
      final BaseDeviceInfo info = await ref.read(deviceInfoProvider.future);
      final myDeviceType = info.extractPlatform; //  'windows', 'android'


      //Inject them into the TXT record
      final service = Service(
        name: deviceName,
        type: AppConfig.mdnsServiceType,
        port: port,
        txt: {
          'uuid': utf8.encode(uuid),
          'type': utf8.encode(myDeviceType),
          'v': utf8.encode(AppConfig.syncProtocolVersion.toString()),
        },
      );

      // Registers the service
      final registration = await register(service);
      AppLogger.d('mDNS: Broadcasting as ${registration.service.name} on port $port');

      // Save the registration object to state so we can cancel it later
      _activeRegistration = registration;
      state = registration;
    } catch (e) {
      AppLogger.d('mDNS Host Error: $e');
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
      AppLogger.d('mDNS: Stopped broadcasting manually');
    }
  }
}
