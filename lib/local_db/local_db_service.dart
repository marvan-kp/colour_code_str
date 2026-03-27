import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/paint_order.dart';

class LocalDbService {
  static const String _ordersBox = 'orders_box';
  static const String _productsBox = 'products_box';
  static const String _deletedBox = 'deleted_orders';
  
  static const String _productsKey = 'product_list';
  static const String _productBasesKey = 'product_bases_map_v1';
  static const String _productBasesUpdatedAtKey = 'product_bases_updated_at';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Secure Key Management
    const storage = FlutterSecureStorage();
    var encryptionKeyString = await storage.read(key: 'hive_encryption_key');
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await storage.write(key: 'hive_encryption_key', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }
    final encryptionKey = base64Url.decode(encryptionKeyString);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PaintOrderAdapter());
    }
    
    // Open Encrypted Boxes
    await Hive.openBox<PaintOrder>(_ordersBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<dynamic>(_productsBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<String>(_deletedBox, encryptionCipher: HiveAesCipher(encryptionKey));
    
    _seedDefaultProducts();
  }

  void _seedDefaultProducts() {
    final box = Hive.box<dynamic>(_productsBox);
    
    // Migration: Old list to New Map
    if (box.get(_productsKey) != null && box.get(_productBasesKey) == null) {
       final oldList = List<String>.from(box.get(_productsKey) as List);
       final newMap = <String, List<String>>{};
       for (var p in oldList) {
         newMap[p] = [];
       }
       box.put(_productBasesKey, newMap);
       box.put(_productBasesUpdatedAtKey, DateTime.now().toIso8601String());
    }

    if (box.get(_productBasesKey) == null) {
      box.put(_productBasesKey, <String, List<String>>{
        'Emulsion': [], 'Enamel': [], 'Primer': [], 'Distemper': [],
        'Texture': [], 'Wood Finish': [], 'Lustre': [], 'Exterior': []
      });
      // Set to an ancient date so that if a Cloud Backup exists, the app downloads and restores it
      // instead of aggressively wiping the Cloud because this device was just wiped.
      box.put(_productBasesUpdatedAtKey, "1970-01-01T00:00:00.000Z");
    }
  }

  // ─── Product & Base Management ───────────────────────────────────────────
  Map<String, List<String>> getProductBases() {
    final box = Hive.box<dynamic>(_productsBox);
    final raw = box.get(_productBasesKey);
    if (raw == null) return {};
    final map = raw as Map<dynamic, dynamic>;
    return map.map((key, value) => MapEntry(key.toString(), List<String>.from(value as List)));
  }

  String getProductBasesUpdatedAt() {
    final box = Hive.box<dynamic>(_productsBox);
    return box.get(_productBasesUpdatedAtKey, defaultValue: '') as String;
  }

  Future<void> updateProductBases(Map<String, List<String>> newMap, {String? timestamp}) async {
    final box = Hive.box<dynamic>(_productsBox);
    // Convert to dynamic Map for safe Hive serialization
    final safeMap = <dynamic, dynamic>{};
    newMap.forEach((key, list) {
      safeMap[key] = List<dynamic>.from(list);
    });
    await box.put(_productBasesKey, safeMap);
    await box.put(_productBasesUpdatedAtKey, timestamp ?? DateTime.now().toIso8601String());
  }

  List<String> getProducts() => getProductBases().keys.toList();

  Future<void> addProduct(String name) async {
    if (name.isEmpty) return;
    final map = getProductBases();
    if (!map.containsKey(name)) {
      map[name] = [];
      await updateProductBases(map);
    }
  }

  Future<void> deleteProduct(String name) async {
    final map = getProductBases();
    if (map.containsKey(name)) {
      map.remove(name);
      await updateProductBases(map);
    }
  }

  Future<void> addBaseToProduct(String product, String base) async {
    if (product.isEmpty || base.isEmpty) return;
    final map = getProductBases();
    
    // Auto-create product if it doesn't exist yet to prevent race conditions
    if (!map.containsKey(product)) {
      map[product] = [];
    }
    
    if (!map[product]!.contains(base)) {
      map[product]!.add(base);
      await updateProductBases(map);
    }
  }

  Future<void> deleteBaseFromProduct(String product, String base) async {
    final map = getProductBases();
    if (map.containsKey(product)) {
      if (map[product]!.contains(base)) {
        map[product]!.remove(base);
        await updateProductBases(map);
      }
    }
  }

  // ─── Order Management ────────────────────────────────────────────────────
  Box<PaintOrder> get _orders => Hive.box<PaintOrder>(_ordersBox);

  Future<void> saveOrder(PaintOrder order) async {
    await _orders.put(order.id, order);
  }

  Future<void> saveOrders(List<PaintOrder> orders) async {
    for (final order in orders) {
      await _orders.put(order.id, order);
    }
  }

  List<PaintOrder> getAllOrders() {
    final list = _orders.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<PaintOrder> getUnsyncedOrders() {
    return _orders.values.where((o) => !o.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final order = _orders.get(id);
    if (order != null) {
      order.isSynced = true;
      await order.save();
    }
  }

  Future<void> deleteOrder(String id) async {
    await _orders.delete(id);
    await Hive.box<String>(_deletedBox).add(id);
  }

  List<String> getDeletedOrderIds() {
    return Hive.box<String>(_deletedBox).values.toList();
  }

  Future<void> clearDeletedOrderId(String id) async {
    final box = Hive.box<String>(_deletedBox);
    final key = box.keys.firstWhere((k) => box.get(k) == id, orElse: () => null);
    if (key != null) {
      await box.delete(key);
    }
  }
}
