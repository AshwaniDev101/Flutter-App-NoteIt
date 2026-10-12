import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../../../provider/sync_client_provider.dart';

enum ConnectionStatus { initial, connecting, success, error }

class ConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;

  const ConnectionState({
    this.status = ConnectionStatus.initial,
    this.errorMessage,
  });
}

// 1. Changed to standard NotifierProvider
final hostConnectionControllerProvider =
NotifierProvider<HostConnectionController, ConnectionState>(() {
  return HostConnectionController();
});

// 2. Changed to standard Notifier
class HostConnectionController extends Notifier<ConnectionState> {
  @override
  ConnectionState build() {
    return const ConnectionState();
  }

  Future<void> connect({
    required String ip,
    required int port,
    required String hostUuid,
    required String hostName,
    required String devicePlatform,
    required int protocolVersion,
    required Future<String?> Function() requestPin,
  }) async {
    // Set to connecting
    state = const ConnectionState(status: ConnectionStatus.connecting);

    try {
      final isKnown = await ref.read(syncedDevicesDaoProvider).isDeviceKnown(hostUuid);
      String? pin;

      if (!isKnown) {
        pin = await requestPin();
        if (pin == null) {
          // User canceled PIN entry, quietly reset
          state = const ConnectionState(status: ConnectionStatus.initial);
          return;
        }
      }

      // Execute connection using your existing dialer
      await ref.read(syncClientProvider.notifier).connectToHost(
        ip: ip,
        port: port,
        hostUuid: hostUuid,
        hostName: hostName,
        pin: pin,
        // --- PASS TO THE DIALER ---
        devicePlatform: devicePlatform,
        protocolVersion: protocolVersion,
      );

      // Success!
      state = const ConnectionState(status: ConnectionStatus.success);

    } catch (e) {
      // Clean up the error message and set error state
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = ConnectionState(
        status: ConnectionStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  // Optional: A helper to reset the state when the screen closes
  void reset() {
    state = const ConnectionState(status: ConnectionStatus.initial);
  }
}