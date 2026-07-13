import 'package:flutter/material.dart';
import 'plate_scanner.dart';

/// Abre uma folha inferior com o leitor de placa (OCR) e retorna a placa
/// normalizada lida (ou null se o usuario fechar sem ler).
///
/// Reutilizado na area de reservas e no check-list para identificar/conferir
/// o veiculo pela placa.
Future<String?> showLeitorPlacaSheet(
  BuildContext context, {
  String titulo = 'Ler placa do veiculo',
  String legenda = 'Aponte a camera para a placa do veiculo',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              PlateScanner(
                onPlaca: (placa) => Navigator.pop(ctx, placa),
                legenda: legenda,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
