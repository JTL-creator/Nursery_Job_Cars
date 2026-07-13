import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/sync_provider.dart';

/// Badge no AppBar mostrando quantidade de pendentes.
/// Clicavel: abre a tela de sincronizacao.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (_, sync, __) {
        if (sync.pendentes == 0 && !sync.sincronizando) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () => context.push('/sync'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sync.sincronizando
                  ? Colors.blue.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sync.sincronizando
                    ? Colors.blue.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sync.sincronizando)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gdmBlue,
                    ),
                  )
                else
                  Icon(Icons.cloud_upload_outlined,
                      size: 14, color: Colors.orange.shade800),
                const SizedBox(width: 5),
                Text(
                  sync.sincronizando
                      ? 'Enviando...'
                      : '${sync.pendentes} pend.',
                  style: TextStyle(
                    color: sync.sincronizando
                        ? Colors.blue.shade900
                        : Colors.orange.shade900,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
