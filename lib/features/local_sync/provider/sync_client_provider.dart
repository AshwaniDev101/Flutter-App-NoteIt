import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/local_sync/provider/sync_session_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../database/drift/device_pairs/synced_devices_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../database/sync/local_sync_service.dart';
import '../view/qr/qr_page.dart';

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
    String? pin,
  }) async {
    // Close any existing connection first
    disconnect();

    print('Client: Attempting to connect to Host at $ip:$port');

    try {
      final String myUuid = ref.read(sharedPreferenceProvider).hostUuid;

      final BaseDeviceInfo info = await ref.read(deviceInfoProvider.future);
      final myDeviceName = info.extractName;

      final Map<String, dynamic> queryParams = {
        'host_uuid': hostUuid,
        'host_name': hostName,
        'client_uuid': myUuid,
        'client_name': myDeviceName,
      };

      if (pin != null) {
        queryParams['pin'] = pin;
      }

      // Safely construct the URI with all parameters
      // We pass our own UUID and Name to the Host so they can save us!
      final finalUri = Uri(
        scheme: 'ws',
        host: ip,
        port: port,
        queryParameters: queryParams,
      );

      //Initiate Connection
      final channel = WebSocketChannel.connect(finalUri);

      // This pauses execution until the socket is officially OPEN!
      // If the host is offline, this throws an error and drops into the catch block.
      // This throws if the host rejects us (e.g., wrong PIN)
      await channel.ready;

      print('Client: Connection Confirmed!');

      await ref.read(syncedDevicesDaoProvider).upsertDeviceAsHost(uuid: hostUuid, name: hostName);
      print('Client: Saved Host $hostName to Drift DB.');

      // Save the connection to the state
      state = channel;

      // Listen for incoming sync payloads from the PC/Host
      // We pass the channel to the traffic controller, which handles all the listening,
      // batching, and database saving automatically.
      ref.read(localSyncServiceProvider.notifier).setActiveConnection(channel);
    } on WebSocketChannelException catch(e){
      print('Connection rejected by host. Wrong PIN? Error: $e');
      state = null;
      // can catch it and show a Snackbar saying "Wrong PIN, try again!"
      throw Exception('Connection rejected. Please check the PIN and try again.');

    }catch (e) {
      print('Failed to connect to host: $e');
      state = null;
      throw Exception('Failed to connect to device.');
    }
  }

  void disconnect() {
    if (state != null) {
      print("Client: Disconnecting from host...");
      // Make sure the central traffic controller also knows we are stopping
      ref.read(localSyncServiceProvider.notifier).stop();

      state?.sink.close();
      state = null;
    }
  }
}
