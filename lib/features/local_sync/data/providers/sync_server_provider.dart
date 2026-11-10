import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../../workspace/providers/active_workspace_provider.dart';

final syncServerProvider = NotifierProvider<SyncServerNotifier, HttpServer?>(() {
  return SyncServerNotifier();
});

class SyncServerNotifier extends Notifier<HttpServer?> {
  String? _currentPin;
  bool _isBusy = false; // the lock state

  String? _connectingClientUuid;
  String? _connectingClientName;
  String? _connectingClientPlatform;

  bool get isBusy => _isBusy;

  @override
  HttpServer? build() {
    ref.onDispose(() => state?.close(force: true));
    return null;
  }

  void updatePin(String? pin) {
    if (_currentPin == pin) return;
    _currentPin = pin;
  }

  void resetBusyLock() {
    AppLogger.d("SyncServerNotifier: Resetting busy lock manually.");
    _isBusy = false;
    ref.read(localSyncServiceProvider.notifier).stop();
  }

  Future<int> startHosting({
    required String ip,
    VoidCallback? onClientConnected,
    VoidCallback? onClientDisconnected,
  }) async {
    // --- POLICE CODE: ENFORCE MUTUAL EXCLUSIVITY ---
    // If we are currently connected as a Client, kill it before hosting.
    final isClientActive = ref.read(syncClientProvider) != null;
    if (isClientActive) {
      AppLogger.d('SyncServerNotifier: Device is acting as Client. Disconnecting before starting Host...');
      ref.read(syncClientProvider.notifier).disconnect();
    }
    // -----------------------------------------------

    if (state != null) {
      if (state!.address.host != ip && state!.address.address != ip) {
        AppLogger.d('SyncServerNotifier: Wi-Fi IP changed! Restarting server...');
        stopHosting(); // Shut down the old server automatic will start a new one below
      } else {
        AppLogger.d('SyncServerNotifier: Server already running on $ip');
        return state!.port;
      }
    }

    AppLogger.d('SyncServerNotifier: Starting Host Server...');

    var wsHandler = webSocketHandler((webSocketChannel, _) {
      AppLogger.d('SyncServerNotifier: A Client has connected to the Host!');
      _isBusy = true; // LOCK THE DOOR: Host is now occupied

      ref.read(localSyncSessionProvider.notifier).establishSession(
        channel: webSocketChannel,
        role: SyncRole.host,
        peerUuid: _connectingClientUuid ?? 'unknown-client',
        peerName: _connectingClientName ?? 'Client Device',
        peerPlatform: _connectingClientPlatform ?? 'unknown',
      );

      onClientConnected?.call();

      webSocketChannel.sink.done
          .then((_) {
            AppLogger.d('SyncServerNotifier: Client disconnected');
            ref.read(localSyncServiceProvider.notifier).stop();
            onClientDisconnected?.call();
            _isBusy = false;
          })
          .catchError((e) {
            AppLogger.w('SyncServerNotifier: Client connection error: $e');
            ref.read(localSyncServiceProvider.notifier).stop();
            onClientDisconnected?.call();
            _isBusy = false;
          });
    });

    final authHandler = _createAuthHandler(wsHandler);

    HttpServer server;
    try {
      server = await shelf_io.serve(authHandler, ip, AppConfig.defaultSyncPort);
    } catch (e) {
      AppLogger.w('SyncServerNotifier: Default port ${AppConfig.defaultSyncPort} in use ($e). Falling back to dynamic port...');
      server = await shelf_io.serve(authHandler, ip, 0);
    }
    AppLogger.d('SyncServerNotifier: Sync server hosting at ws://${server.address.host}:${server.port}');

    state = server;

    await ref.read(syncModeProvider.notifier).setMode(SyncMode.localHost);
    return state!.port;
  }

  /// Middleware that checks the PIN and Database before allowing WebSocket access
  Handler _createAuthHandler(Handler wsHandler) {
    return (Request request) async {
      if (_isBusy) {
        AppLogger.d("SyncServerNotifier: Connection rejected. Host is currently busy syncing.");
        return Response.forbidden('Host is currently busy syncing with another device.');
      }

      final queryParams = request.requestedUri.queryParameters;

      final clientUuid = queryParams['client_uuid'];
      final clientName = queryParams['client_name'];
      final clientPin = queryParams['pin'];
      final clientProfileName = queryParams['profile_name'];
      final clientAuthEmail = queryParams['auth_email'];

      final String clientPlatform = queryParams['client_platform'] ?? 'unknown';

      final String? clientVersionStr = queryParams['v'];
      final int clientVersion = clientVersionStr != null ? (int.tryParse(clientVersionStr) ?? 0) : 0;

      if (clientUuid == null) {
        return Response.badRequest(body: 'Missing client_uuid');
      }

      // --- PROTOCOL SAFETY CHECK ---
      if (clientVersion != AppConfig.syncProtocolVersion) {
        AppLogger.d("SyncServerNotifier: Connection rejected. Client is v$clientVersion, Host is v${AppConfig.syncProtocolVersion}.");
        return Response.forbidden('Version mismatch. Please update NoteIt.');
      }

      // --- STRICT GOOGLE ACCOUNT & WORKSPACE MATCHING CHECK ---
      final activeWorkspace = ref.read(activeWorkspaceProvider);
      final hostProfileNameNorm = activeWorkspace.name.trim().toLowerCase();
      final clientProfileNameNorm = clientProfileName?.trim().toLowerCase();

      final authUser = ref.read(authStateProvider).value;
      final hostEmailNorm = authUser?.email?.trim().toLowerCase();
      final clientEmailNorm = clientAuthEmail?.trim().toLowerCase();

      final bool isNameMatched = clientProfileNameNorm != null && clientProfileNameNorm == hostProfileNameNorm;
      final bool isEmailMatched = hostEmailNorm != null && clientEmailNorm != null && hostEmailNorm == clientEmailNorm;

      if (!isNameMatched && !isEmailMatched) {
        AppLogger.d("SyncServerNotifier: Connection rejected. Client workspace '$clientProfileName' ($clientAuthEmail) does not match host workspace '${activeWorkspace.name}' ($hostEmailNorm).");
        return Response.forbidden('Workspace/Account mismatch: $clientProfileName');
      }
      // -------------------------------------

      _connectingClientUuid = clientUuid;
      _connectingClientName = clientName ?? 'Unknown Device';
      _connectingClientPlatform = clientPlatform;

      final syncedDevicesDao = ref.read(syncedDevicesDaoProvider);
      final isKnown = await syncedDevicesDao.isDeviceKnown(clientUuid);

      if (!isKnown) {
        // Verify PIN
        if (_currentPin == null || clientPin != _currentPin) {
          AppLogger.d("SyncServerNotifier: Connection rejected. Invalid PIN or QR screen is closed. $clientName");
          return Response.forbidden('Invalid PIN');
        } else {
          // PIN matched! Whitelist them for next time
          AppLogger.d("SyncServerNotifier: PIN matched! Trusting $clientName...");

          await syncedDevicesDao.upsertDeviceAsClient(
            uuid: clientUuid,
            name: clientName ?? 'Unknown Device',
            deviceType: clientPlatform,
            protocolVersion: clientVersion,
          );
        }
      } else {
        AppLogger.d("SyncServerNotifier: Known device connecting ($clientName)");
      }

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
