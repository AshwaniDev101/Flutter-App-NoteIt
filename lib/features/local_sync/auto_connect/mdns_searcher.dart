import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

import '../../../core/config.dart';
import '../../../core/util/logger.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import 'mdns_broadcast.dart';

// ==== Client side ===
enum ScanStatus { idle, scanning, found, error }

typedef MdnsState = ({ScanStatus status, List<Service> devices});

final mdnsSearcherProvider = NotifierProvider<MdnsSearcherNotifier, MdnsState>(() {
  return MdnsSearcherNotifier();
});

class MdnsSearcherNotifier extends Notifier<MdnsState> {
  Discovery? _discovery;

  @override
  MdnsState build() {
    ref.onDispose(stopScan);
    return (status: ScanStatus.idle, devices: []);
  }

  /// Helper to safely extract and decode UTF-8 strings from mDNS TXT records
  String? _decodeTxt(Map<String, Uint8List?>? txt, String key) {
    if (txt == null || !txt.containsKey(key) || txt[key] == null) return null;
    try {
      // List<int>.from safely converts the Uint8List so utf8.decode doesn't crash
      return utf8.decode(List<int>.from(txt[key]!));
    } catch (_) {
      return null;
    }
  }

  /// Helper to filter out invalid services and our own ghost broadcasts
  List<Service> _getValidServices(List<Service> rawServices, String myUuid) {
    return rawServices.where((s) {
      if (s.port == null) return false;

      // Extract UUID from the discovered service
      final discoveredUuid = _decodeTxt(s.txt, 'uuid');

      // IGNORE OUR OWN GHOST BROADCASTS
      // MUST FILTER HERE TOO!
      if (discoveredUuid == null || discoveredUuid == myUuid) return false;

      return true;
    }).toList();
  }

  /// RADAR MODE: Finds ALL NoteIt devices for the SearchNearBy UI (No UUID needed)
  Future<void> startRadar() async {

    // --- POLICE CODE ---
    AppLogger.d('MdnsSearcherNotifier: Stopping any active broadcasts before scanning.');
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    // -------------------

    if (state.status == ScanStatus.scanning) return;

    state = (status: ScanStatus.scanning, devices: []);

    try {
      // sometimes Device does not allow custom tcp name like _noteitsync._tcp
      enableLogging(LogTopic.errors);
      disableServiceTypeValidation(true);

      _discovery = await startDiscovery(AppConfig.mdnsServiceType, ipLookupType: IpLookupType.any);

      // We don't want to crash if _discovery drops instantly
      if (_discovery == null) return;

      final myUuid = ref.read(sharedPreferenceProvider).hostUuid;

      // IMMEDIATELY populate the state in case it found devices instantly
      // Filter out invalid services before they hit the state
      state = (status: ScanStatus.scanning, devices: _getValidServices(_discovery!.services, myUuid));

      _discovery!.addListener(() {

        // The listener fires even when devices disconnect.
        // If _discovery is suddenly null here, abort.
        if (_discovery == null) return;

        // Update the state with the live list of all found devices
        state = (status: ScanStatus.scanning, devices: _getValidServices(_discovery!.services, myUuid));
      });
    } catch (e, st) {
      AppLogger.e('MdnsSearcherNotifier: Radar Error', error: e, stack: st);
      state = (status: ScanStatus.error, devices: []);
    }
  }

  /// Starts scanning the network for the specific UUID.
  /// Returns a Record (ip, port, deviceType, protocolVersion) if found, or null if it fails/times out.
  /// TARGETED MODE: Background auto-connect searching for a specific UUID
  Future<({String ip, int port, String deviceType, int protocolVersion})?> findServer(String targetUuid) async {

    // --- POLICE CODE ---
    AppLogger.d('MdnsSearcherNotifier: Stopping any active broadcasts before targeted scan.');
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    // -------------------

    if (state.status == ScanStatus.scanning) return null;

    state = (status: ScanStatus.scanning, devices: []);
    final completer = Completer<({String ip, int port, String deviceType, int protocolVersion})?>();

    try {
      _discovery = await startDiscovery(AppConfig.mdnsServiceType, ipLookupType: IpLookupType.any);

      if (_discovery == null) {
        state = (status: ScanStatus.error, devices: []);
        completer.complete(null);
        return completer.future;
      }

      _discovery!.addListener(() {
        if (_discovery == null) return; // Prevent _TypeError if discovery is stopped

        for (var service in _discovery!.services) {
          final discoveredUuid = _decodeTxt(service.txt, 'uuid');

          if (discoveredUuid == targetUuid) {

            // 1. Try service.host first (Sometimes a String on Android)
            // 2. Try the first item in service.addresses (Usually works on Windows/iOS)
            String? ip;
            if (service.host != null && service.host!.isNotEmpty) {
              ip = service.host;
            } else if (service.addresses != null && service.addresses!.isNotEmpty) {
              ip = service.addresses!.first.address;
            }

            final port = service.port;

            if (ip != null && port != null && !completer.isCompleted) {
              AppLogger.d('MdnsSearcherNotifier: Found exact paired server at $ip:$port!');
              state = (status: ScanStatus.found, devices: []);

              // Extract new metadata for auto-connect handshake
              final deviceType = _decodeTxt(service.txt, 'type') ?? 'unknown';

              final vStr = _decodeTxt(service.txt, 'v');
              final protocolVersion = vStr != null ? (int.tryParse(vStr) ?? 0) : 0;

              stopScan();
              completer.complete((
              ip: ip,
              port: port,
              deviceType: deviceType,
              protocolVersion: protocolVersion
              ));
              return;
            }
          }
        }
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          AppLogger.d('MdnsSearcherNotifier: Scan timed out.');
          state = (status: ScanStatus.error, devices: []);
          stopScan();
          completer.complete(null);
        }
      });
    } catch (e, st) {
      AppLogger.e('MdnsSearcherNotifier: Targeted Scan Error', error: e, stack: st);
      state = (status: ScanStatus.error, devices: []);
      completer.complete(null);
    }

    return completer.future;
  }

  void stopScan() {
    if (_discovery != null) {
      stopDiscovery(_discovery!);
      _discovery = null;
    }
    state = (status: ScanStatus.idle, devices: []);
  }
}