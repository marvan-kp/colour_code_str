import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paint_order.dart';

class FirestoreService {
  static const String _collection = 'paint_orders';

  FirebaseFirestore? _instance;

  FirebaseFirestore? get _db {
    try {
      _instance ??= FirebaseFirestore.instance;
      return _instance;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _db != null;

  Future<void> uploadOrdersBatch(List<PaintOrder> orders) async {
    final db = _db;
    if (db == null || orders.isEmpty) return;

    final batch = db.batch();
    for (final order in orders) {
      final ref = db.collection(_collection).doc(order.id);
      batch.set(ref, order.toMap());
    }
    await batch.commit();
  }

  Future<List<PaintOrder>> fetchLatestOrders(DateTime since) async {
    final db = _db;
    if (db == null) return [];

    try {
      final snapshot = await db
          .collection(_collection)
          .where('updatedAt', isGreaterThan: since.toIso8601String())
          .get();

      return snapshot.docs
          .where((doc) => doc.id != 'CONFIG_product_bases')
          .map((doc) => PaintOrder.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteOrder(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_collection).doc(id).delete();
    } catch (_) {}
  }

  Future<void> syncProductBases(Map<String, dynamic> localData, String updatedAt, Function(Map<String, dynamic>, String) onRemoteNewer) async {
    final db = _db;
    if (db == null) return;
    try {
      final docRef = db.collection(_collection).doc('CONFIG_product_bases');
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final remoteData = snapshot.data()!;
        final remoteUpdatedAt = remoteData['updatedAt'] as String? ?? '';
        if (remoteUpdatedAt.compareTo(updatedAt) > 0) {
           onRemoteNewer(remoteData['bases'] as Map<String, dynamic>, remoteUpdatedAt);
           return;
        } else if (remoteUpdatedAt == updatedAt) {
           return; 
        }
      }
      await docRef.set({
        'bases': localData,
        'updatedAt': updatedAt,
      });
    } catch (_) {}
  }

  Future<void> updateDeviceStatus(String deviceId, Map<String, dynamic> status) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('devices').doc(deviceId).set({
        ...status,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAllDevicesStatus() async {
    final db = _db;
    if (db == null) return [];
    try {
      final snapshot = await db.collection('devices').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
