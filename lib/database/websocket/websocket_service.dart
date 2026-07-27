import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_message.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService {
  final String myDeviceId = "windows_host_${DateTime.now().millisecondsSinceEpoch}";

  HttpServer? _server;
  final List<WebSocket> _activeSockets = [];

  // Exposes incoming data to the Riverpod Coordinator
  final _incomingStreamController = StreamController<SyncMessage>.broadcast();
  Stream<SyncMessage> get incomingMessages => _incomingStreamController.stream;

  /// Starts the server on the Windows machine
  Future<void> startHostServer({int port = 4040}) async {
    try {
      // Bind to anyIPv4 so devices on the same local Wi-Fi router can see it
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print("WebSocket Host running on: ${_server!.address.address}:$port");

      // Listen for incoming connection attempts
      _server!.listen(_handleConnectionRequest);
    } catch (e) {
      print("Failed to start WebSocket server: $e");
    }
  }

  /// Upgrades a standard HTTP connection to a WebSocket
  Future<void> _handleConnectionRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _activeSockets.add(socket);
      print("New client connected to Host!");

      // Listen for incoming messages from the Android app
      socket.listen(
            (dynamic rawMessage) {
          if (rawMessage is String) {
            _onRawMessageReceived(rawMessage);
          }
        },
        onDone: () {
          print("Client disconnected.");
          _activeSockets.remove(socket);
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _activeSockets.remove(socket);
        },
      );
    } else {
      // If a web browser tries to hit this IP normally, reject it
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket connections only')
        ..close();
    }
  }

  /// Pushed by the Coordinator to send data over the wire
  void sendMessage(SyncMessage message) {
    // Don't send our own messages back to ourselves
    if (message.deviceId != myDeviceId) return;

    final jsonString = jsonEncode(message.toJson());

    // Broadcast the message to all connected clients (the Android phone)
    for (final socket in _activeSockets) {
      socket.add(jsonString);
    }
    print("WebSocket: Sent message -> ${message.action}");
  }

  /// Internal method to decode Wi-Fi data and pass it up to Riverpod
  void _onRawMessageReceived(String rawJson) {
    try {
      final jsonMap = jsonDecode(rawJson);
      final msg = SyncMessage.fromJson(jsonMap);

      // Pass the fully typed object to the Coordinator
      _incomingStreamController.add(msg);
    } catch (e) {
      print("Failed to parse incoming WebSocket message: $e");
    }
  }

  /// Call this when the app closes
  void stopServer() {
    for (final socket in _activeSockets) {
      socket.close();
    }
    _server?.close();
  }
}