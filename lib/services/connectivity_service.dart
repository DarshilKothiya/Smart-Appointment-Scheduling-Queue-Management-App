import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription? _subscription;

  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isConnected = _isOnline(results);
    _connectionStreamController.add(_isConnected);

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = _isOnline(results);
      if (wasConnected != _isConnected) {
        _connectionStreamController.add(_isConnected);
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStreamController.close();
  }
}
