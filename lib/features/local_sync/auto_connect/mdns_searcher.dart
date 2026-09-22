import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

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

      // IMMEDIATELY populate the state in case it found devices instantly
      state = (status: ScanStatus.scanning, devices: _discovery!.services.toList());

      _discovery!.addListener(() {
        // Update the state with the live list of all found devices
        state = (status: ScanStatus.scanning, devices: _discovery!.services.toList());
      });

    } catch (e) {
      print('mDNS Radar Error: $e');
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

      _discovery!.addListener(() {
        for (var service in _discovery!.services) {
          final rawUuidBytes = service.txt?['uuid'];

          if (rawUuidBytes != null) {
            final discoveredUuid = utf8.decode(rawUuidBytes);

            if (discoveredUuid == targetUuid) {
              final ip = service.host ?? service.addresses?.first.address;
              final port = service.port;

              if (ip != null && port != null && !completer.isCompleted) {
                print('mDNS: Found exact paired server at $ip:$port!');
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
          print('mDNS: Scan timed out.');
          state = (status: ScanStatus.error, devices: []);
          stopScan();
          completer.complete(null);
        }
      });
    } catch (e) {
      print('mDNS Targeted Scan Error: $e');
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
