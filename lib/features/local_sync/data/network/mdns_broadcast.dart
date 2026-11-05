import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:nsd/nsd.dart';

// ==== Server side ===

// Registration? is the State type that will be returned, while MdnsHostNotifier is responsible for running the functions.
// In-short mean provider is returning object of Registration when the server is broadcasting, else it returns null
final mdnsBroadcastProvider =
    NotifierProvider<MdnsBroadcastNotifier, Registration?>(() {
      return MdnsBroadcastNotifier();
    });

class MdnsBroadcastNotifier extends Notifier<Registration?> {
  // Use a static reference so that hot-restarts or provider rebuilds
  // retain knowledge of the active native Registration and unregister it cleanly.
  static Registration? _globalActiveRegistration;

  @override
  Registration? build() {
    ref.onDispose(() {
      _closeNativeRegistration();
    });
    return _globalActiveRegistration;
  }

  Future<void> startBroadcasting({
    required int port,
    required String uuid,
    required String deviceName,
  }) async {
    // --- POLICE CODE ---
    AppLogger.d('MdnsBroadcastNotifier: Stopping any active scans before broadcasting.');
    ref.read(mdnsSearcherProvider.notifier).stopScan();
    // -------------------

    // ALWAYS unregister prior registration before starting a new broadcast
    if (_globalActiveRegistration != null) {
      AppLogger.d('MdnsBroadcastNotifier: Unregistering prior active broadcast before starting new broadcast.');
      await stopBroadcasting();
    }

    // Creates the service
    try {
      // Fetch your local device type
      final BaseDeviceInfo info = await ref.read(deviceInfoProvider.future);
      final myDeviceType = info.extractPlatform; // 'windows', 'android'

      // Inject them into the TXT record
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
      AppLogger.d('MdnsBroadcastNotifier: Broadcasting as ${registration.service.name} on port $port');

      // Save the registration object statically so we can cancel it cleanly
      _globalActiveRegistration = registration;
      state = registration;
    } catch (e, st) {
      AppLogger.e('MdnsBroadcastNotifier: Host Error', error: e, stack: st);
    }
  }

  void _closeNativeRegistration() {
    if (_globalActiveRegistration != null) {
      final regToCancel = _globalActiveRegistration!;
      _globalActiveRegistration = null;
      try {
        unregister(regToCancel);
        AppLogger.d('MdnsBroadcastNotifier: Stopped broadcasting successfully');
      } catch (e) {
        AppLogger.e('MdnsBroadcastNotifier: Unregister error', error: e);
      }
    }
  }

  /// Call this ONLY if you need a manual button to stop syncing while staying on the page.
  /// (The onDispose block handles the automatic cleanup when leaving the page).
  Future<void> stopBroadcasting() async {
    _closeNativeRegistration();
    if (state != null) {
      state = null;
    }
  }
}
