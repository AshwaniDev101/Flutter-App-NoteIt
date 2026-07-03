import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/provider/provider.dart';
import 'drift/drift_database.dart';
import 'firebase/firebase_database.dart';
import 'shared_preference/shared_preference_manager.dart';

final syncNotifierProvider = NotifierProvider<SyncNotifier, bool>(SyncNotifier.new);

class SyncNotifier extends Notifier<bool> with WidgetsBindingObserver {
  late final NoteDriftDatabase _driftDb;
  NoteFirestoreDatabase? _firebaseDb;
  late final SharedPreferenceManager _prefs;

  StreamSubscription? _remoteSubscription;

  @override
  bool build() {
    _driftDb = ref.watch(noteDriftDatabaseProvider);
    _prefs = ref.watch(sharedPreferenceProvider);

    // Fetch the initial database state without triggering constant rebuilds
    _firebaseDb = ref.read(noteFirebaseDatabaseProvider);

    _remoteSubscription?.cancel();
    WidgetsBinding.instance.addObserver(this);

    // Listen directly to auth state to trigger sync exactly when login completes
    ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;

      if (prevUser == null && nextUser != null) {
        print("SyncManager: User logged in. Initializing database and triggering sync...");

        // Grab the fresh database instance now that we have a valid UID
        _firebaseDb = ref.read(noteFirebaseDatabaseProvider);

        _startActiveSessionListener();
        executeFullSync();
      } else if (nextUser == null) {
        print("SyncManager: User logged out. Stopping listeners.");
        _firebaseDb = null;
        _remoteSubscription?.cancel();
      }
    });

    // Start listening immediately if already logged in on app boot
    if (_firebaseDb != null) {
      _startActiveSessionListener();
    }

    ref.onDispose(() {
      _remoteSubscription?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    return false; // state represents 'isSyncing'
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("SyncManager: App resumed. Triggering Delta Sync...");
      executeFullSync();
    }
  }

  void _startActiveSessionListener() {
    final sessionStartTime = DateTime.now().toUtc().millisecondsSinceEpoch;

    _remoteSubscription = _firebaseDb!.watchForRemoteChanges(sessionStartTime).listen((newDocs) async {
      if (newDocs.isEmpty) return;

      print("SyncManager: Real-time remote changes detected!");
      for (final doc in newDocs) {
        await _driftDb.upsertNoteFromCloud(doc.data()!, doc.id);
      }

      await _prefs.setLastSyncTime(DateTime.now().toUtc().millisecondsSinceEpoch);
    });
  }

  Future<void> executeFullSync() async {
    // Prevent overlapping syncs
    if (state) return;

    if (_firebaseDb == null) {
      print("SyncManager: Aborted sync (User not logged in).");
      return;
    }

    state = true;

    try {
      final int lastSyncTime = _prefs.lastSyncTime;
      final int newSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;

      // --- PULL ---
      final remoteChanges = await _firebaseDb!.pullChanges(lastSyncTime);
      for (final doc in remoteChanges) {
        await _driftDb.upsertNoteFromCloud(doc.data(), doc.id);
      }

      // --- PUSH ---
      final pendingNotes = await _driftDb.getPendingNotes();
      if (pendingNotes.isNotEmpty) {
        final newIds = await _firebaseDb!.pushBatch(pendingNotes);
        await _driftDb.markAsSynced(pendingNotes.map((n) => n.id), newIds);
        print("SyncManager: Pushed ${pendingNotes.length} notes.");
      }

      // --- BOOKMARK ---
      await _prefs.setLastSyncTime(newSyncTime);
      print("SyncManager: Sync Complete. Bookmark: $newSyncTime");

    } catch (e) {
      print("SyncManager: Sync Failed -> $e");
    } finally {
      state = false;
    }
  }
}