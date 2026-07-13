import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/pdf_checklist_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/checklist_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gdm_card.dart';
import '../../widgets/loading_indicator.dart';

class ChecklistsScreen extends StatefulWidget {
  const ChecklistsScreen({super.key});

  @override
  State<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

class _ChecklistsScreenState extends State<ChecklistsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _carregando = true;
  String? _baixandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      setState(() => _carregando = true);
      final list = await ChecklistService.minhasChecklists();
      setState(() => _items = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _exportarPdf(Map<String, dynamic> chk) async {
    final id = chk['id']?.toString();
    if (id == null) return;
    try {
      setState(() => _baixandoId = id);
      // Busca detalhe completo (com itens)
      final detalhe = await ChecklistService.obterDetalhe(id);
      if (!mounted) return;
      await PdfChecklistService.imprimirOuCompartilhar(detalhe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Erro ao gerar PDF: ${ApiClient.extractMessage(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _baixandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: LoadingIndicator());
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.checklist,
                  title: 'Nenhum check-list ainda',
                  description:
                      'Quando voce fizer retiradas e devolucoes, eles aparecerao aqui.',
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final c = _items[i];
                return _ChecklistTile(
                  checklist: c,
                  baixando: _baixandoId == c['id']?.toString(),
                  onPdf: () => _exportarPdf(c),
                );
              },
            ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final Map<String, dynamic> checklist;
  final bool baixando;
  final VoidCallback onPdf;

  const _ChecklistTile({
    required this.checklist,
    required this.baixando,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final etapa = checklist['etapa']?.toString() ?? '';
    final codigo = checklist['codigo_interno']?.toString() ?? '—';
    final desc = checklist['ativo_descricao']?.toString() ?? '';
    final dtRaw = checklist['data_hora_evento']?.toString();
    final dt = dtRaw != null ? DateTime.tryParse(dtRaw) : null;
    final fmt = dt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal())
        : '—';

    final ehRetirada = etapa == 'RETIRADA';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GdmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ehRetirada
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    ehRetirada ? Icons.upload_outlined : Icons.download_outlined,
                    color: ehRetirada
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        codigo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(desc,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${ehRetirada ? "Retirada" : "Devolucao"} em $fmt',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ehRetirada
                        ? Colors.blue.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ehRetirada ? 'Retirada' : 'Devolucao',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ehRetirada
                          ? Colors.blue.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: baixando ? null : onPdf,
                    icon: baixando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.gdmBlue),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(
                      baixando ? 'Gerando PDF...' : 'Exportar PDF',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gdmBlue,
                      side: const BorderSide(color: AppColors.gdmBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
