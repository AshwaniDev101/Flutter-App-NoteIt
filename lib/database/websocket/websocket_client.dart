import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/websocket/sync_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


final webSocketClientProvider = Provider((ref) => WebSocketClient());

class WebSocketClient {
  final String myDeviceId = "android_client_${DateTime.now().millisecondsSinceEpoch}";

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  // Feeds incoming data to the Riverpod Coordinator
  final _incomingStreamController = StreamController<SyncMessage>.broadcast();
  Stream<SyncMessage> get incomingMessages => _incomingStreamController.stream;

  /// Connects to the host URL provided by mDNS (e.g., ws://192.168.1.5:4040)
  Future<void> connectToHost(String wsUrl) async {
    try {
      print("WebSocket Client: Connecting to $wsUrl...");

      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      // Wait for the connection to establish (throws if it fails)
      await _channel!.ready;
      print("WebSocket Client: Connected successfully!");

      // Start listening to the server
      _channelSubscription = _channel!.stream.listen(
            (rawMessage) => _onRawMessageReceived(rawMessage),
        onDone: () => _handleDisconnect(),
        onError: (e) => print("WebSocket Client Error: $e"),
      );
    } catch (e) {
      print("WebSocket Client: Failed to connect -> $e");
      // TODO: Trigger a retry logic after 5 seconds
    }
  }

  /// Called by the Riverpod Coordinator to send data to Windows
  void sendMessage(SyncMessage message) {
    if (_channel == null || message.deviceId != myDeviceId) return;

    final jsonString = jsonEncode(message.toJson());
    _channel!.sink.add(jsonString);
    print("WebSocket Client: Sent message -> ${message.action}");
  }

  /// Internal: Decode incoming strings into SyncMessage objects
  void _onRawMessageReceived(String rawJson) {
    try {
      final msg = SyncMessage.fromJson(jsonDecode(rawJson));
      _incomingStreamController.add(msg);
    } catch (e) {
      print("WebSocket Client: Failed to parse incoming message -> $e");
    }
  }

  void _handleDisconnect() {
    print("WebSocket Client: Disconnected from host.");
    _channelSubscription?.cancel();
    _channel = null;
    // TODO: Trigger auto-reconnect loop here
  }

  void disconnect() {
    _channel?.sink.close();
    _channelSubscription?.cancel();
  }
}