import 'package:flutter/material.dart';
import '../models/paint_order.dart';
import '../local_db/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

class OrderProvider with ChangeNotifier {
  final LocalDbService _localDb;
  final SyncService _syncService;
  final ConnectivityService _connectivity;

  List<PaintOrder> _allOrders = [];
  List<String> _products = [];
  Map<String, List<String>> _productBases = {};
  String _searchQuery = '';
  bool _isSyncing = false;
  NetworkStatus _networkStatus = NetworkStatus.offline;
  String deviceId;

  OrderProvider({
    required LocalDbService localDb,
    required SyncService syncService,
    required ConnectivityService connectivity,
    required this.deviceId,
  })  : _localDb = localDb,
        _syncService = syncService,
        _connectivity = connectivity {
    _init();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isSyncing => _isSyncing;
  NetworkStatus get networkStatus => _networkStatus;
  List<String> get products => _products;
  Map<String, List<String>> get productBases => _productBases;

  List<PaintOrder> get orders {
    if (_searchQuery.isEmpty) return _allOrders;
    final q = _searchQuery.toLowerCase();
    return _allOrders.where((o) =>
      o.product.toLowerCase().contains(q) ||
      o.colorCode.toLowerCase().contains(q) ||
      o.base.toLowerCase().contains(q)
    ).toList();
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  void _init() {
    _loadAll();

    _syncService.syncStatusStream.listen((syncing) {
      _isSyncing = syncing;
      if (!syncing) _loadAll();
      notifyListeners();
    });

    _connectivity.statusStream.listen((status) {
      _networkStatus = status;
      notifyListeners();
    });
    _networkStatus = _connectivity.current;
  }

  void _loadAll() {
    _allOrders = _localDb.getAllOrders();
    _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _products = _localDb.getProducts();
    _productBases = _localDb.getProductBases();
    notifyListeners();
  }

  // ─── Public Actions ───────────────────────────────────────────────────────
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> addOrder(PaintOrder order) async {
    await _localDb.saveOrder(order);
    await _localDb.addProduct(order.product);
    _loadAll();
    _syncService.syncData(); // Fire and forget
  }

  Future<void> deleteOrder(String id) async {
    await _localDb.deleteOrder(id);
    _loadAll();
    _syncService.syncData(); // Propagate delete to cloud
  }

  Future<void> addProduct(String name) async {
    await _localDb.addProduct(name);
    _loadAll();
    _syncService.syncData();
  }

  Future<void> deleteProduct(String name) async {
    await _localDb.deleteProduct(name);
    _loadAll();
    _syncService.syncData();
  }

  Future<void> addBaseToProduct(String product, String base) async {
    await _localDb.addBaseToProduct(product, base);
    _loadAll();
    _syncService.syncData();
  }

  Future<void> deleteBaseFromProduct(String product, String base) async {
    await _localDb.deleteBaseFromProduct(product, base);
    _loadAll();
    _syncService.syncData();
  }

  Future<void> refresh() async {
    _isSyncing = true;
    notifyListeners();
    await _syncService.syncData();
    _loadAll();
    _isSyncing = false;
    notifyListeners();
  }
}
