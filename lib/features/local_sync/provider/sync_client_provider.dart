import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/sync/sync_engine.dart';
import 'package:noteit/features/local_sync/provider/sync_server_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/config.dart';
import '../../../core/util/device_info.dart';
import '../../../core/util/logger.dart';
import '../../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../database/sync/local_sync_service.dart';
import '../auto_connect/mdns_broadcast.dart';

final syncClientProvider = NotifierProvider<SyncClientNotifier, WebSocketChannel?>(() {
  return SyncClientNotifier();
});

// Because LocalSyncNotifier is symmetrical, SyncClientNotifier essentially just acts as the dialer.
// It picks up the phone (WebSocketChannel.connect), hands the receiver to LocalSyncNotifier,
// and says, "Here, you talk." From that point on, the batching and ACK logic starts
class SyncClientNotifier extends Notifier<WebSocketChannel?> {
  @override
  WebSocketChannel? build() {
    // When the provider is destroyed, close the connection cleanly and disconnect everything
    // 'state' is a built-in, special variable that holds the current data of your provider.
    ref.onDispose(disconnect);
    return null; // Null means disconnected
  }

  Future<void> connectToHost({
    required String ip,
    required int port,
    required String hostUuid,
    required String hostName,
    String? pin, // PIN stays nullable because fast auto-reconnects don't need a PIN
    required String devicePlatform,
    required int protocolVersion,
  }) async {


    // --- POLICE CODE: ENFORCE MUTUAL EXCLUSIVITY ---
    // If we are currently running a Host server, shut it down.
    final isHostActive = ref.read(syncServerProvider) != null;
    if (isHostActive) {
      AppLogger.d('SyncClientNotifier: Device is hosting. Shutting down server before connecting as Client...');
      ref.read(syncServerProvider.notifier).stopHosting();

      // Also ensure we stop shouting our presence on the network
      ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    }
    // -----------------------------------------------


    // Close any existing connection first
    disconnect();

    AppLogger.d('SyncClientNotifier: Attempting to connect to Host at $ip:$port');

    try {
      final String myUuid = ref.read(sharedPreferenceProvider).hostUuid;

      final BaseDeviceInfo info = await ref.read(deviceInfoProvider.future);
      final myDeviceName = info.extractName;
      final myPlatform = info.extractPlatform;

      final Map<String, dynamic> queryParams = {
        'host_uuid': hostUuid,
        'host_name': hostName,
        'client_uuid': myUuid,
        'client_name': myDeviceName,
        'client_platform': myPlatform,
        'v': AppConfig.syncProtocolVersion.toString(),
      };
      if (pin != null) {
        queryParams['pin'] = pin;
      }

      // Safely construct the URI with all parameters
      final finalUri = Uri(scheme: 'ws', host: ip, port: port, queryParameters: queryParams);

      // Initiate Connection
      final channel = WebSocketChannel.connect(finalUri);

      try {
        // Wait for connection with a strict 2-second timeout
        await channel.ready.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            // Close channel sink on timeout to release socket resources
            channel.sink.close();
            throw TimeoutException('Ghost IP or Host unreachable');
          },
        );

        AppLogger.d('SyncClientNotifier: Connection Confirmed!');

        // Ensure SyncEngine is set to local and SyncRole is client when connection succeeds
        ref.read(syncEngineProvider.notifier).setEngine(SyncEngine.local);
        ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.client);

        await ref.read(syncedDevicesDaoProvider).upsertDeviceAsHost(
          uuid: hostUuid,
          name: hostName,
          lastKnownIp: ip,
          lastKnownPort: port,
          deviceType: devicePlatform,
          protocolVersion: protocolVersion,
        );
        AppLogger.d('SyncClientNotifier: Saved Host $hostName to Drift DB.');

        // Save the connection to the state
        state = channel;

        // Pass to traffic controller
        ref.read(localSyncServiceProvider.notifier).setActiveConnection(channel);
      } catch (_) {
        // If connection setup failed before assigning state, ensure channel is closed
        if (state != channel) {
          channel.sink.close();
        }
        rethrow;
      }

    } on TimeoutException catch (e) {
      // Caught the Ghost IP timeout specifically
      AppLogger.w('SyncClientNotifier: Hit a Ghost IP or router blocked connection: $e');
      state = null;
      throw Exception('Host not found. Please try scanning the QR code.');

    } on WebSocketChannelException catch (e) {
      // Caught a rejection (like a wrong PIN)
      AppLogger.w('SyncClientNotifier: Connection rejected by host. Wrong PIN? Error: $e');
      state = null;
      throw Exception('Connection rejected. Please check the PIN and try again.');

    } catch (e, st) {
      // Caught any other random error
      AppLogger.e('SyncClientNotifier: Failed to connect to host', error: e, stack: st);
      state = null;
      throw Exception('Failed to connect to device.');
    }
  }

  void disconnect() {
    if (state != null) {
      AppLogger.d("SyncClientNotifier: Disconnecting from host...");
      // Make sure the central traffic controller also knows we are stopping
      ref.read(localSyncServiceProvider.notifier).stop();

      state?.sink.close();
      state = null;
    }
  }
}
