import 'dart:async';
import '../local_db/local_db_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';

class SyncService {
  final LocalDbService _localDb;
  final FirestoreService _firestore;
  final ConnectivityService _connectivity;

  final _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  bool _isSyncing = false;

  SyncService(this._localDb, this._firestore, this._connectivity) {
    _connectivity.statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        syncData();
      }
    });
    // Debounce initial sync to allow UI entrance animations to finish smoothly
    Future.delayed(const Duration(seconds: 2), syncData);
  }

  bool _syncRequested = false;

  Future<void> syncData() async {
    if (_isSyncing) {
      _syncRequested = true;
      return;
    }
    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      // Upload unsynced local orders to Firestore
      final unsynced = _localDb.getUnsyncedOrders();
      if (unsynced.isNotEmpty) {
        await _firestore.uploadOrdersBatch(unsynced);
        for (final order in unsynced) {
          await _localDb.markAsSynced(order.id);
        }
      }

      // Sync deletions to Firestore
      final deletedIds = _localDb.getDeletedOrderIds();
      for (final id in deletedIds) {
        await _firestore.deleteOrder(id);
        await _localDb.clearDeletedOrderId(id);
      }

      // Pull remote changes from last 7 days
      final since = DateTime.now().subtract(const Duration(days: 7));
      final remoteOrders = await _firestore.fetchLatestOrders(since);

      if (remoteOrders.isNotEmpty) {
        // PERF: Fetch local orders once and use a Map for O(1) matching
        final locals = _localDb.getAllOrders();
        final localMap = {for (var o in locals) o.id: o};

        for (final remote in remoteOrders) {
          final local = localMap[remote.id];

          if (local == null) {
            // New order from another device
            await _localDb.saveOrder(remote..isSynced = true);
          } else if (remote.updatedAt.isAfter(local.updatedAt)) {
            // Remote is newer: update local
            await _localDb.saveOrder(remote..isSynced = true);
          }
        }
      }

      // Sync Product Bases
      final localBases = _localDb.getProductBases();
      final localUpdatedAt = _localDb.getProductBasesUpdatedAt();
      await _firestore.syncProductBases(
        localBases, 
        localUpdatedAt.isEmpty ? DateTime.now().toIso8601String() : localUpdatedAt, 
        (remoteBases, remoteUpdatedAt) async {
          final parsed = remoteBases.map((k, v) => MapEntry(k.toString(), List<String>.from(v as List)));
          await _localDb.updateProductBases(parsed, timestamp: remoteUpdatedAt);
        }
      );
    } catch (e) {
      // Silently fail — data is safe locally
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      
      if (_syncRequested) {
        _syncRequested = false;
        syncData();
      }
    }
  }

  void dispose() {
    _syncStatusController.close();
  }
}
