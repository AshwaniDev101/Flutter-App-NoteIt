import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:nsd/nsd.dart';

// ==== Client side ===
enum ScanStatus { idle, scanning, found, error }

typedef MdnsState = ({ScanStatus status, List<Service> devices});

final mdnsSearcherProvider = NotifierProvider<MdnsSearcherNotifier, MdnsState>(() {
  return MdnsSearcherNotifier();
});

class MdnsSearcherNotifier extends Notifier<MdnsState> {
  Discovery? _discovery;
  Timer? _scanTimer;

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

  /// Helper to filter out invalid services, our own ghost broadcasts, and deduplicate by host UUID
  List<Service> _getValidServices(List<Service> rawServices, String myUuid) {
    final Map<String, Service> uniqueByUuid = {};

    for (final s in rawServices) {
      if (s.port == null) continue;

      // Extract UUID from the discovered service
      final discoveredUuid = _decodeTxt(s.txt, 'uuid');

      // IGNORE OUR OWN BROADCASTS
      if (discoveredUuid == null || discoveredUuid == myUuid) continue;

      // Deduplicate: Keep single entry per unique host UUID
      uniqueByUuid[discoveredUuid] = s;
    }

    return uniqueByUuid.values.toList();
  }

  /// RADAR MODE: Finds ALL NoteIt devices for the SearchNearBy UI (No UUID needed).
  /// Initial scan defaults to 3 seconds. User-triggered retries pass 10 seconds.
  Future<void> startRadar({Duration duration = const Duration(seconds: 3)}) async {

    // --- POLICE CODE ---
    AppLogger.d('MdnsSearcherNotifier: Stopping any active broadcasts before scanning.');
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    // -------------------

    _scanTimer?.cancel();

    if (_discovery != null) {
      stopDiscovery(_discovery!);
      _discovery = null;
    }

    state = (status: ScanStatus.scanning, devices: []);

    try {
      // sometimes Device does not allow custom tcp name like _noteitsync._tcp
      enableLogging(LogTopic.errors);
      disableServiceTypeValidation(true);

      _discovery = await startDiscovery(AppConfig.mdnsServiceType, ipLookupType: IpLookupType.any);

      // We don't want to crash if _discovery drops instantly
      if (_discovery == null) {
        state = (status: ScanStatus.error, devices: []);
        return;
      }

      final myUuid = ref.read(sharedPreferenceProvider).hostUuid;

      // IMMEDIATELY populate the state in case it found devices instantly
      // Filter out invalid services before they hit the state
      final foundServices = _getValidServices(_discovery!.services, myUuid);
      state = (status: ScanStatus.scanning, devices: foundServices);

      _discovery!.addListener(() {
        // The listener fires even when devices disconnect.
        // If _discovery is suddenly null here, abort.
        if (_discovery == null) return;

        // Update the state with the live list of all found devices
        final liveServices = _getValidServices(_discovery!.services, myUuid);
        state = (status: ScanStatus.scanning, devices: liveServices);
      });

      // Trigger parallel subnet probe fallback for Windows / Firewalled environments
      _probeSubnetForHosts(myUuid).then((subnetServices) {
        if (subnetServices.isNotEmpty) {
          final merged = List<Service>.from(state.devices);
          for (var s in subnetServices) {
            if (!merged.any((existing) => existing.host == s.host)) {
              merged.add(s);
            }
          }
          state = (
            status: state.status == ScanStatus.scanning ? ScanStatus.scanning : ScanStatus.found,
            devices: merged,
          );
        }
      });

      // Automatically complete scan after requested duration
      _scanTimer = Timer(duration, () {
        if (state.status == ScanStatus.scanning) {
          final currentDevices = state.devices;
          AppLogger.d('MdnsSearcherNotifier: Radar scan finished after ${duration.inSeconds}s. Found ${currentDevices.length} devices.');
          if (_discovery != null) {
            stopDiscovery(_discovery!);
            _discovery = null;
          }
          state = (
            status: currentDevices.isNotEmpty ? ScanStatus.found : ScanStatus.idle,
            devices: currentDevices,
          );
        }
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
        return await completer.future;
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

      // Trigger parallel subnet probe fallback for targeted server lookup
      _probeSubnetForHosts(ref.read(sharedPreferenceProvider).hostUuid).then((subnetServices) {
        for (var service in subnetServices) {
          final ip = service.host;
          final port = service.port;
          if (ip != null && port != null && !completer.isCompleted) {
            AppLogger.d('MdnsSearcherNotifier: Found host via direct subnet probe at $ip:$port!');
            stopScan();
            completer.complete((
              ip: ip,
              port: port,
              deviceType: 'unknown',
              protocolVersion: AppConfig.syncProtocolVersion,
            ));
            return;
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

  /// Probes local Wi-Fi subnet (/24) on default sync port (34215)
  /// as a bulletproof fallback when mDNS is blocked by Windows Firewall or router isolation.
  Future<List<Service>> _probeSubnetForHosts(String myUuid) async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? localIp;
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      if (localIp == null) return [];

      final parts = localIp.split('.');
      if (parts.length != 4) return [];
      final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

      final discoveredServices = <Service>[];
      final futures = <Future<void>>[];

      for (int i = 1; i <= 254; i++) {
        final targetIp = '$prefix$i';
        if (targetIp == localIp) continue;

        futures.add(
          Socket.connect(
            targetIp,
            AppConfig.defaultSyncPort,
            timeout: const Duration(milliseconds: 300),
          ).then((socket) {
            socket.destroy();
            AppLogger.d('MdnsSearcherNotifier: Subnet probe found active host at $targetIp:${AppConfig.defaultSyncPort}');

            final service = Service(
              name: 'NoteIt Host ($targetIp)',
              type: AppConfig.mdnsServiceType,
              port: AppConfig.defaultSyncPort,
              host: targetIp,
              txt: {
                'uuid': utf8.encode('subnet-$targetIp'),
                'type': utf8.encode('unknown'),
                'v': utf8.encode(AppConfig.syncProtocolVersion.toString()),
              },
            );
            discoveredServices.add(service);
          }).catchError((_) {}),
        );
      }

      await Future.wait(futures);
      return discoveredServices;
    } catch (e) {
      return [];
    }
  }

  void stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (_discovery != null) {
      stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (state.status != ScanStatus.idle || state.devices.isNotEmpty) {
      Future.microtask(() {
        state = (status: ScanStatus.idle, devices: const []);
      });
    }
  }
}
