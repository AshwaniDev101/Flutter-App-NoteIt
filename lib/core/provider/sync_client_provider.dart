import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../database/local_sync_service.dart';

final syncClientProvider = NotifierProvider<SyncClientNotifier, WebSocketChannel?>(() {
  return SyncClientNotifier();
});

class SyncClientNotifier extends Notifier<WebSocketChannel?> {
  @override
  WebSocketChannel? build() {
    // When the provider is destroyed, close the connection cleanly
    // 'state' is a built-in, special variable that holds the current data of your provider.
    ref.onDispose(() => state?.sink.close());
    return null; // Null means disconnected
  }

  void connectToHost(String wsUrl) {
    // Close any existing connection first
    state?.sink.close();

    print('Connecting to Host: $wsUrl');
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    // Save the connection to the state
    state = channel;

    // Listen for incoming sync payloads from the PC/Host

    ref.read(localSyncServiceProvider).setActiveConnection(channel);

    // channel.stream.listen(
    //   (message) {
    //     print('Received from Host: $message');
    //     // TODO: We will add the Drift JSON parsing here next
    //   },
    //   onDone: () {
    //     print('Disconnected from Host');
    //     state = null; // Update UI to show disconnected status
    //   },
    //   onError: (error) {
    //     print('WebSocket Error: $error');
    //     state = null;
    //   },
    // );

    // Send an initial handshake payload to prove the connection works
    channel.sink.add('Hello from Client! Ready to sync.');
  }

  void disconnect() {
    state?.sink.close();
    state = null;
  }
}
