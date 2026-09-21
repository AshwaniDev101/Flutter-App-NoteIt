import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

// ==== Client side ===
enum ScanStatus { idle, scanning, found, error }

final mdnsSearcherProvider = NotifierProvider<MdnsSearcherNotifier, ScanStatus>(() {
  return MdnsSearcherNotifier();
});

class MdnsSearcherNotifier extends Notifier<ScanStatus> {
  Discovery? _discovery;

  @override
  ScanStatus build() {
    return ScanStatus.idle;
  }

  /// Starts scanning the network for the specific UUID.
  /// Returns a Record (ip, port) if found, or null if it fails/times out.
  Future<({String ip, int port})?> findServer(String targetUuid) async {
    if (state == ScanStatus.scanning) return null;

    state = ScanStatus.scanning;

    // A Completer lets us turn a listener stream into a simple Future we can await
    final completer = Completer<({String ip, int port})?>();

    try {
      _discovery = await startDiscovery('_http._tcp', ipLookupType: IpLookupType.any);

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
                state = ScanStatus.found;

                stopScan(); // Shut down the network scanner to save battery
                completer.complete((ip: ip, port: port));
                return;
              }
            }
          }
        }
      });

      // 60-second timeout so it doesn't scan forever if the server is off
      Future.delayed(const Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          print('mDNS: Scan timed out.');
          state = ScanStatus.error;
          stopScan();
          completer.complete(null);
        }
      });
    } catch (e) {
      print('mDNS Scan Error: $e');
      state = ScanStatus.error;
      completer.complete(null);
    }

    return completer.future;
  }

  void stopScan() {
    if (_discovery != null) {
      stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (state == ScanStatus.scanning) {
      state = ScanStatus.idle;
    }
  }
}
