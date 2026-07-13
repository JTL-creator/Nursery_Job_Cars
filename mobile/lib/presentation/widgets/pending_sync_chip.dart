import 'package:flutter/material.dart';

/// Selo compacto que indica que um item foi criado/alterado offline e
/// ainda aguarda sincronizacao com o servidor.
class PendingSyncChip extends StatelessWidget {
  final bool compact;

  const PendingSyncChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cor = Colors.orange.shade800;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: compact ? 12 : 14, color: cor),
          const SizedBox(width: 4),
          Text(
            compact ? 'Pendente' : 'Aguardando sincronizacao',
            style: TextStyle(
              color: cor,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
