import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

import '../../../core/util/logger.dart';

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

  /// RADAR MODE: Finds ALL NoteIt devices for the SearchNearBy UI (No UUID needed)
  Future<void> startRadar() async {
    if (state.status == ScanStatus.scanning) return;

    state = (status: ScanStatus.scanning, devices: []);

    try {
      // sometimes Device does not allow custom tcp name like _noteitsync._tcp
      enableLogging(LogTopic.errors);
      disableServiceTypeValidation(true);

      _discovery = await startDiscovery('_noteitsync._tcp', ipLookupType: IpLookupType.any);

// We don't want to crash if _discovery drops instantly
      if (_discovery == null) return;

      // IMMEDIATELY populate the state in case it found devices instantly
      // Filter out invalid services before they hit the state

      final validServices = _discovery!.services.where((s) => s.port != null).toList();
      state = (status: ScanStatus.scanning, devices: validServices);

      _discovery!.addListener(() {

        // The listener fires even when devices disconnect.
        // If _discovery is suddenly null here, abort.
        if (_discovery == null) return;


        final currentValidServices = _discovery!.services.where((s) => s.port != null).toList();

        // Update the state with the live list of all found devices
        state = (status: ScanStatus.scanning, devices: currentValidServices);
        // state = (status: ScanStatus.scanning, devices: _discovery!.services.toList());


      });
    } catch (e) {
      AppLogger.d('mDNS Radar Error: $e');
      state = (status: ScanStatus.error, devices: []);
    }
  }

  /// Starts scanning the network for the specific UUID.
  /// Returns a Record (ip, port) if found, or null if it fails/times out.
  /// TARGETED MODE: Background auto-connect searching for a specific UUID
  Future<({String ip, int port})?> findServer(String targetUuid) async {
    if (state.status == ScanStatus.scanning) return null;

    state = (status: ScanStatus.scanning, devices: []);
    final completer = Completer<({String ip, int port})?>();

    try {
      _discovery = await startDiscovery('_noteitsync._tcp', ipLookupType: IpLookupType.any);

      if (_discovery == null) {
        state = (status: ScanStatus.error, devices: []);
        completer.complete(null);
        return completer.future;
      }

      _discovery!.addListener(() {
        if (_discovery == null) return; // Prevent _TypeError if discovery is stopped

        for (var service in _discovery!.services) {
          final rawUuidBytes = service.txt?['uuid'];

          if (rawUuidBytes != null) {
            final discoveredUuid = utf8.decode(rawUuidBytes);

            if (discoveredUuid == targetUuid) {

              // 1. Try service.host first (Sometimes a String on Android)
              // 2. Try the first item in service.addresses (Usually works on Windows/iOS)
              String? ip;
              if (service.host != null && service.host!.isNotEmpty) {
                ip = service.host;
              } else if (service.addresses != null && service.addresses!.isNotEmpty) {
                ip = service.addresses!.first.address;
              }

              // final ip = service.host ?? service.addresses?.firstOrNull?.address;
              final port = service.port;

              if (ip != null && port != null && !completer.isCompleted) {
                AppLogger.d('mDNS: Found exact paired server at $ip:$port!');
                state = (status: ScanStatus.found, devices: []);

                stopScan();
                completer.complete((ip: ip, port: port));
                return;
              }
            }
          }
        }
      });

      Future.delayed(const Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          AppLogger.d('mDNS: Scan timed out.');
          state = (status: ScanStatus.error, devices: []);
          stopScan();
          completer.complete(null);
        }
      });
    } catch (e) {
      AppLogger.d('mDNS Targeted Scan Error: $e');
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
