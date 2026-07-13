import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (_, c, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: c.online ? 0 : 32,
          color: Colors.red.shade600,
          alignment: Alignment.center,
          child: c.online
              ? const SizedBox.shrink()
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Voce esta offline. Algumas funcoes podem estar limitadas.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
