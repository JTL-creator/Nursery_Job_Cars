import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Stream de status online/offline.
class ConnectivityService {
  ConnectivityService._() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _controller.add(online);
    });
    _bootstrap();
  }

  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription? _sub;

  Stream<bool> get onChange => _controller.stream;

  Future<void> _bootstrap() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    _controller.add(online);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
