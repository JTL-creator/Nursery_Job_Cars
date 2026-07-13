import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Map<String, Color> _cores() {
    switch (status) {
      case 'PENDENTE':
        return {'bg': Colors.amber.shade100, 'fg': Colors.amber.shade900};
      case 'CONFIRMADA':
        return {'bg': Colors.blue.shade100, 'fg': Colors.blue.shade900};
      case 'EM_USO':
        return {'bg': Colors.purple.shade100, 'fg': Colors.purple.shade900};
      case 'CONCLUIDA':
        return {'bg': Colors.green.shade100, 'fg': Colors.green.shade900};
      case 'CANCELADA':
        return {'bg': Colors.red.shade100, 'fg': Colors.red.shade900};
      case 'REJEITADA':
        return {
          'bg': Colors.deepOrange.shade100,
          'fg': Colors.deepOrange.shade900
        };
      case 'EXPIRADA':
        return {'bg': Colors.grey.shade300, 'fg': Colors.grey.shade800};
      default:
        return {'bg': Colors.grey.shade200, 'fg': Colors.grey.shade700};
    }
  }

  String _label() {
    switch (status) {
      case 'PENDENTE':
        return 'Pendente';
      case 'CONFIRMADA':
        return 'Confirmada';
      case 'EM_USO':
        return 'Em uso';
      case 'CONCLUIDA':
        return 'Concluida';
      case 'CANCELADA':
        return 'Cancelada';
      case 'REJEITADA':
        return 'Rejeitada';
      case 'EXPIRADA':
        return 'Expirada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _cores();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c['bg'],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: c['fg'],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
