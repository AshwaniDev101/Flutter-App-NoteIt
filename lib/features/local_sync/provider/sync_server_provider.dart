import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../../database/drift/device_pairs/synced_devices_dao.dart';
import '../../../database/sync/local_sync_service.dart';

final syncServerProvider = NotifierProvider<SyncServerNotifier, HttpServer?>(() {
  return SyncServerNotifier();
});

class SyncServerNotifier extends Notifier<HttpServer?> {
  String? _currentPin;
  bool _isBusy = false; // the lock state

  @override
  HttpServer? build() {
    ref.onDispose(() => state?.close(force: true));
    return null;
  }

  void updatePin(String? pin) {
    _currentPin = pin;
  }

  Future<int> startHosting({
    required String ip,
    VoidCallback? onClientConnected,
    VoidCallback? onClientDisconnected,
  }) async {
    // // If a PIN is provided (e.g., UI screen generated one), update it.
    // // If it's null (e.g., background auto-start), keep whatever the last PIN was.
    // if (expectedPin != null) {
    //   _currentPin = expectedPin;
    // }

    if (state != null) {
      // Server is already running, just hand back its existing port
      // Dart's state!.address.host might format differently, so we check both
      // IP-change check : If the app goes to the background, the user walks into a new network, and the app resumes,
      // it will currently hit if (state != null) { return state!.port; } and completely ignore the new Wi-Fi IP.
      if (state!.address.host != ip && state!.address.address != ip) {
        print('Wi-Fi IP changed! Restarting server...');
        stopHosting(); // Shut down the old server automatic will start a new one below
      } else {
        print('Server already running on $ip');
        return state!.port;
      }
    }

    print('--- Starting Host Server ---');

    // 'webSocketHandler' acts as a bouncer that intercepts the client's connection.
    // When a client sends an HTTP "Upgrade" request, this bouncer decides whether
    // to upgrade them from a temporary HTTP connection to a permanent WebSocket connection.

    // The callback inside webSocketHandler() triggers at the exact moment a client
    // successfully connects and the WebSocket handshake is complete.

    // Parameter 1 (webSocketChannel): The live, permanent "pipe" to the client device.
    // This is the two-way radio we use to stream sync data back and forth.

    // Parameter 2 (_): The requested "sub-protocol" string (e.g., 'graphql' or 'chat-v1').
    // We use '_' to ignore it because we are just sending standard text/bytes and
    // don't need to negotiate a specific data format protocol.
    var wsHandler = webSocketHandler((webSocketChannel, _) {
      print('A Client has connected to the Host!');
      _isBusy = true; // LOCK THE DOOR: Host is now occupied

      // second a client connects, the receptionist grabs the live, open data pipeline (webSocketChannel) and hands it over to our localSyncServiceProvider
      ref.read(localSyncServiceProvider.notifier).setActiveConnection(webSocketChannel);

      // Trigger the connect callback!
      onClientConnected?.call();

      // Listen for disconnection via the stream or sink done future
      webSocketChannel.sink.done
          .then((_) {
            print('Client disconnected');
            ref.read(localSyncServiceProvider.notifier).stop();
            onClientDisconnected?.call(); // Trigger disconnect callback!
            _isBusy = false; // UNLOCK THE DOOR: Host is free again
          })
          .catchError((_) {
            ref.read(localSyncServiceProvider.notifier).stop();
            onClientDisconnected?.call(); // Trigger disconnect callback!
            _isBusy = false; // UNLOCK THE DOOR: Host is free again
          });
    });

    // We wrap the wsHandler inside our authHandler (The Front Door Bouncer).
    // Every incoming connection must pass through _createAuthHandler FIRST.
    // If the PIN/UUID is valid, the authHandler passes the request to the wsHandler.
    // If invalid, the authHandler rejects the request and the wsHandler is never triggered.
    final authHandler = _createAuthHandler(wsHandler);

    // 8080 is common for web servers testing, 0 to let the OS pick a port
    final HttpServer server = await shelf_io.serve(authHandler, ip, 0);
    print('Sync server hosting at ws://${server.address.host}:${server.port}');

    state = server;
    return state!.port;
  }

  /// Middleware that checks the PIN and Database before allowing WebSocket access
  Handler _createAuthHandler(Handler wsHandler) {
    return (Request request) async {
      if (_isBusy) {
        print("Host: Connection rejected. Host is currently busy syncing.");
        return Response.forbidden('Host is currently busy syncing with another device.');
      }

      final queryParams = request.requestedUri.queryParameters;
      final clientUuid = queryParams['client_uuid'];
      final clientName = queryParams['client_name'];
      final clientPin = queryParams['pin'];

      if (clientUuid == null) {
        return Response.badRequest(body: 'Missing client_uuid');
      }

      final syncedDevicesDao = ref.read(syncedDevicesDaoProvider);
      final isKnown = await syncedDevicesDao.isDeviceKnown(clientUuid);

      if (!isKnown) {
        // if client is known don't check the pin
        // Verify PIN
        if (_currentPin == null || clientPin != _currentPin) {
          print("Host: Connection rejected. Invalid PIN or QR screen is closed. $clientName");
          return Response.forbidden('Invalid PIN');
        } else {
          // PIN matched! Whitelist them for next time
          print("Host: PIN matched! Trusting $clientName...");
          await syncedDevicesDao.upsertDeviceAsClient(uuid: clientUuid, name: clientName ?? 'Unknown Device');
        }
      } else {
        print("Host: Known device connecting ($clientName)");
      }

      // Authorization passed, hand off to the WebSocket handler
      return wsHandler(request);
    };
  }

  void stopHosting() {
    ref.read(localSyncServiceProvider.notifier).stop();
    state?.close(force: true);
    state = null;
    _isBusy = false;
  }
}
