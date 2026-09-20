import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../database/local_sync_service.dart';

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

  void connectToHost(String wsUrl) {
    // Close any existing connection first
    disconnect();

    print('Connecting to Host: $wsUrl');
    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Save the connection to the state
      state = channel;

      // Listen for incoming sync payloads from the PC/Host
      // We pass the channel to the traffic controller, which handles all the listening,
      // batching, and database saving automatically.
      ref.read(localSyncServiceProvider.notifier).setActiveConnection(channel);
    } catch (e) {
      print('Failed to connect to host: $e');
      state = null;
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
