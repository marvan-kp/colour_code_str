import 'dart:async';
import '../local_db/local_db_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';

class SyncService {
  final LocalDbService _localDb;
  final FirestoreService _firestore;
  final ConnectivityService _connectivity;

  final _syncStatusController = StreamController<bool>.broadcast();
  final _detailedStatusController = StreamController<SyncMetrics>.broadcast();
  
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  Stream<SyncMetrics> get detailedStatusStream => _detailedStatusController.stream;

  bool _isSyncing = false;
  SyncMetrics _currentMetrics = SyncMetrics();

  SyncService(this._localDb, this._firestore, this._connectivity) {
    _connectivity.statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        syncData();
      }
    });
    // Debounce initial sync to allow UI entrance animations to finish smoothly
    Future.delayed(const Duration(seconds: 2), syncData);
  }

  void _updateMetrics(SyncMetrics Function(SyncMetrics) update) {
    _currentMetrics = update(_currentMetrics);
    _detailedStatusController.add(_currentMetrics);
  }

  bool _syncRequested = false;

  Future<void> syncData({bool isFullSync = false, String? deviceId}) async {
    if (_isSyncing) {
      _syncRequested = true;
      return;
    }
    _isSyncing = true;
    _syncStatusController.add(true);
    _updateMetrics((m) => m.copyWith(isSyncing: true, lastError: null));

    try {
      final unsynced = _localDb.getUnsyncedOrders();
      _updateMetrics((m) => m.copyWith(unsyncedCount: unsynced.isNotEmpty ? unsynced.length : 0));

      // Upload unsynced local orders to Firestore
      if (unsynced.isNotEmpty) {
        await _firestore.uploadOrdersBatch(unsynced);
        for (final order in unsynced) {
          await _localDb.markAsSynced(order.id);
        }
        _updateMetrics((m) => m.copyWith(unsyncedCount: 0));
      }

      // Sync deletions to Firestore
      final deletedIds = _localDb.getDeletedOrderIds();
      for (final id in deletedIds) {
        await _firestore.deleteOrder(id);
        await _localDb.clearDeletedOrderId(id);
      }

      // Pull remote changes
      // Full sync goes back 30 days, normal sync 7 days
      final since = DateTime.now().subtract(Duration(days: isFullSync ? 30 : 7));
      final remoteOrders = await _firestore.fetchLatestOrders(since);

      if (remoteOrders.isNotEmpty) {
        final locals = _localDb.getAllOrders();
        final localMap = {for (var o in locals) o.id: o};

        for (final remote in remoteOrders) {
          final local = localMap[remote.id];
          if (local == null) {
            await _localDb.saveOrder(remote..isSynced = true);
          } else if (remote.updatedAt.isAfter(local.updatedAt)) {
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

      // Heartbeat
      if (deviceId != null) {
        await _firestore.updateDeviceStatus(deviceId, {
          'lastSync': DateTime.now().toIso8601String(),
          'orderCount': _localDb.getAllOrders().length,
        });
      }

      _updateMetrics((m) => m.copyWith(lastSyncTime: DateTime.now()));
    } catch (e) {
      _updateMetrics((m) => m.copyWith(lastError: e.toString()));
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      _updateMetrics((m) => m.copyWith(isSyncing: false));
      
      if (_syncRequested) {
        _syncRequested = false;
        syncData(isFullSync: isFullSync, deviceId: deviceId);
      }
    }
  }

  void dispose() {
    _syncStatusController.close();
    _detailedStatusController.close();
  }
}

class SyncMetrics {
  final DateTime? lastSyncTime;
  final int unsyncedCount;
  final bool isSyncing;
  final String? lastError;

  SyncMetrics({
    this.lastSyncTime,
    this.unsyncedCount = 0,
    this.isSyncing = false,
    this.lastError,
  });

  SyncMetrics copyWith({
    DateTime? lastSyncTime,
    int? unsyncedCount,
    bool? isSyncing,
    String? lastError,
  }) {
    return SyncMetrics(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError ?? this.lastError,
    );
  }
}
