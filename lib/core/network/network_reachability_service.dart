import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';

/// Provider exposing the current internet reachability status (true = connected, false = no internet).
final networkReachabilityProvider = NotifierProvider<NetworkReachabilityNotifier, bool>(() {
  return NetworkReachabilityNotifier();
});

class NetworkReachabilityNotifier extends Notifier<bool> with WidgetsBindingObserver {
  Timer? _backoffTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _currentBackoffSeconds = 5;
  bool _isChecking = false;
  bool _isAppInForeground = true;

  static const String _targetHost = 'firestore.googleapis.com';
  static const int _targetPort = 443;
  static const Duration _pingTimeout = Duration(seconds: 3);

  @override
  bool build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _cancelTimer();
      _connectivitySubscription?.cancel();
    });

    _initHardwareListener();

    // Schedule initial check microtask
    Future.microtask(() => checkReachability());

    return true; // Assume online until verified
  }

  void _initHardwareListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      AppLogger.d('NetworkReachability: OS Connectivity hardware event: $results');
      // Hardware state change -> reset backoff and re-verify actual reachability immediately
      _resetBackoff();
      checkReachability();
    });
  }

  /// Manually force a reachability update (e.g. from CloudSyncService on stream error or sync success).
  void setConnected(bool isConnected) {
    if (state != isConnected) {
      AppLogger.d('NetworkReachability: State updated -> ${isConnected ? "Connected" : "No Internet"}');
      state = isConnected;
    }
    if (isConnected) {
      _resetBackoff();
      _cancelTimer();
    } else {
      _scheduleBackoff();
    }
  }

  /// Direct socket connection test to target host bypassing local DNS resolution caching.
  Future<bool> checkReachability() async {
    if (_isChecking) return state;
    _isChecking = true;

    bool isReachable = false;
    try {
      final socket = await Socket.connect(_targetHost, _targetPort, timeout: _pingTimeout);
      socket.destroy();
      isReachable = true;
    } catch (e) {
      isReachable = false;
    } finally {
      _isChecking = false;
    }

    setConnected(isReachable);
    return isReachable;
  }

  void _resetBackoff() {
    _currentBackoffSeconds = 5;
  }

  void _scheduleBackoff() {
    _cancelTimer();
    if (!_isAppInForeground) return;

    AppLogger.d('NetworkReachability: Scheduling reachability re-check in $_currentBackoffSeconds seconds...');
    _backoffTimer = Timer(Duration(seconds: _currentBackoffSeconds), () async {
      final reachable = await checkReachability();
      if (!reachable && _isAppInForeground) {
        // Double backoff duration up to 60 seconds
        _currentBackoffSeconds = (_currentBackoffSeconds * 2).clamp(5, 60);
      }
    });
  }

  void _cancelTimer() {
    _backoffTimer?.cancel();
    _backoffTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      AppLogger.d('NetworkReachability: App resumed. Triggering immediate reachability check.');
      _resetBackoff();
      checkReachability();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      AppLogger.d('NetworkReachability: App backgrounded. Suspending reachability timers.');
      _cancelTimer();
    }
  }
}
