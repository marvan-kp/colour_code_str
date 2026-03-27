import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _controller.stream;

  NetworkStatus _current = NetworkStatus.offline;
  NetworkStatus get current => _current;

  late StreamSubscription _subscription;

  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      final status = isOnline ? NetworkStatus.online : NetworkStatus.offline;
      if (status != _current) {
        _current = status;
        _controller.add(status);
      }
    });
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    _current = isOnline ? NetworkStatus.online : NetworkStatus.offline;
    _controller.add(_current);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
