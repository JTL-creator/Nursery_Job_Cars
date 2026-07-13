import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _online = true;
  bool get online => _online;
  StreamSubscription<bool>? _sub;

  ConnectivityProvider() {
    _sub = ConnectivityService.instance.onChange.listen((v) {
      _online = v;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
