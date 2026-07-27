import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

final mdnsServiceProvider = Provider((ref) => MDnsService());

class MDnsService {
  final String serviceType = '_noteit._tcp';
  Registration? _registration;
  Discovery? _discovery;

  /// WINDOWS ONLY: Broadcasts existence on the local router
  Future<void> startBroadcasting(int port) async {
    try {
      _registration = await register(
        Service(
          name: 'NoteIt Sync Host',
          type: serviceType,
          port: port,
        ),
      );
      print("mDNS: Broadcasting noteit host on port $port");
    } catch (e) {
      print("mDNS Error: Could not start broadcasting -> $e");
    }
  }

  /// ANDROID ONLY: Scans the Wi-Fi for the Windows host and returns its IP/Port
  Future<String?> findHostAddress() async {
    print("mDNS: Scanning for noteit host...");
    try {
      _discovery = await startDiscovery(serviceType, ipLookupType: IpLookupType.v4);

      // A Completer lets us turn a callback listener into a Future we can await
      final completer = Completer<String?>();

      // Create a listener that checks the list every time a new device is found
      void checkServices() {
        for (final service in _discovery!.services) {
          if (service.name != null && service.name!.contains('NoteIt')) {

            // Wait until the service actually resolves an IP address
            if (service.addresses != null && service.addresses!.isNotEmpty) {
              final ip = service.addresses!.first.address;
              final port = service.port;

              print("mDNS: Found host at $ip:$port");

              // Clean up the listener and stop the scanner
              _discovery!.removeListener(checkServices);
              stopScanning();

              if (!completer.isCompleted) {
                completer.complete("ws://$ip:$port");
              }
            }
          }
        }
      }

      // Attach the listener to the discovery object
      _discovery!.addListener(checkServices);

      // Call it once immediately just in case the host was found instantly
      checkServices();

      // Return the future, but add a timeout so it doesn't hang forever if the Windows app is closed
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("mDNS: Scan timed out.");
          _discovery?.removeListener(checkServices);
          stopScanning();
          return null; // Return null so the UI knows to stop loading
        },
      );
    } catch (e) {
      print("mDNS Scan Failed: $e");
      return null;
    }
  }

  void stopBroadcasting() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
  }

  void stopScanning() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!); // Calls the nsd package function
      _discovery = null;
    }
  }
}