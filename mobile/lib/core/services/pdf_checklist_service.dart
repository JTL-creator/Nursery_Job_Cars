import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Servico de geracao de PDF dos check-lists com identidade GDM.
class PdfChecklistService {
  static const _gdmBlue = PdfColor.fromInt(0xFF092A3B);
  static const _gdmBlue2 = PdfColor.fromInt(0xFF0E3A52);
  static const _gdmLime = PdfColor.fromInt(0xFFB4BD00);
  static const _cinzaClaro = PdfColor.fromInt(0xFFF4F6F8);
  static const _cinzaMedio = PdfColor.fromInt(0xFF6B7280);

  /// Gera o PDF de um check-list a partir do detalhe completo.
  /// [checklist] vem do endpoint /checklists/:id e contem itens, ativo, usuario.
  static Future<Uint8List> gerar(Map<String, dynamic> checklist) async {
    final pdf = pw.Document(
      title: 'Check-list GDM Job Cars',
      author: 'GDM',
      creator: 'GDM Job Cars Mobile',
      producer: 'GDM',
    );

    // Carrega fontes para suportar caracteres especiais
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemi = await PdfGoogleFonts.interSemiBold();

    final tema = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final etapa = checklist['etapa']?.toString() ?? '';
    final tipoChecklist = checklist['tipo_checklist']?.toString() ?? '';
    final codigoInterno = checklist['codigo_interno']?.toString() ?? '—';
    final ativoDescricao = checklist['ativo_descricao']?.toString() ?? '';
    final usuarioNome = checklist['usuario_nome']?.toString() ?? '—';
    final local = checklist['local']?.toString();
    final responsavel = checklist['responsavel']?.toString();
    final observacoes = checklist['observacoes']?.toString();
    final dataEvento = checklist['data_hora_evento']?.toString();

    final itens = (checklist['itens'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          ((a['ordem'] as num?)?.toInt() ?? 0)
              .compareTo((b['ordem'] as num?)?.toInt() ?? 0));

    // Separa fotos (data:image/...) dos demais itens
    final fotos = <Map<String, dynamic>>[];
    final itensNormais = <Map<String, dynamic>>[];
    for (final it in itens) {
      final valTxt = it['valor_texto']?.toString() ?? '';
      if (valTxt.startsWith('data:image/')) {
        fotos.add(it);
      } else {
        itensNormais.add(it);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: tema,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
        header: (ctx) => _header(etapa, codigoInterno, fontBold, fontSemi),
        footer: (ctx) => _footer(ctx, fontRegular),
        build: (ctx) => [
          _dadosGerais(
            usuarioNome: usuarioNome,
            ativo: '$codigoInterno - $ativoDescricao',
            tipoChecklist: tipoChecklist,
            dataEvento: dataEvento,
            local: local,
            responsavel: responsavel,
            fontBold: fontBold,
            fontSemi: fontSemi,
          ),
          pw.SizedBox(height: 14),
          _tabelaItens(itensNormais, fontBold, fontSemi),
          if (observacoes != null && observacoes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _observacoes(observacoes, fontBold),
          ],
          if (fotos.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _secaoFotos(fotos, fontBold),
          ],
          pw.SizedBox(height: 30),
          _assinaturas(usuarioNome, fontSemi),
        ],
      ),
    );

    return pdf.save();
  }

  // ============ COMPONENTES ============

  static pw.Widget _header(String etapa, String codigo, pw.Font bold, pw.Font semi) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_gdmBlue, _gdmBlue2],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 38, height: 38,
            decoration: const pw.BoxDecoration(
              color: _gdmLime,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'G',
              style: pw.TextStyle(
                color: _gdmBlue, fontSize: 22, font: bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GDM JOB CARS',
                  style: pw.TextStyle(
                    color: _gdmLime, fontSize: 9, font: bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.Text(
                  'Check-list de ${etapa == "RETIRADA" ? "Retirada" : "Devolucao"}',
                  style: pw.TextStyle(
                    color: PdfColors.white, fontSize: 15, font: bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Ativo',
                  style: pw.TextStyle(
                      color: _gdmLime, fontSize: 8, font: semi)),
              pw.Text(codigo,
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 13, font: bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _dadosGerais({
    required String usuarioNome,
    required String ativo,
    required String tipoChecklist,
    String? dataEvento,
    String? local,
    String? responsavel,
    required pw.Font fontBold,
    required pw.Font fontSemi,
  }) {
    DateTime? dt;
    if (dataEvento != null) dt = DateTime.tryParse(dataEvento);
    final fmt = dt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal())
        : '—';

    final linhas = [
      ['Operador', usuarioNome],
      ['Ativo', ativo],
      ['Tipo', tipoChecklist.replaceAll('_', ' ')],
      ['Data/Hora', fmt],
      if (local != null && local.isNotEmpty) ['Local', local],
      if (responsavel != null && responsavel.isNotEmpty)
        ['Responsavel', responsavel],
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _cinzaClaro,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACOES DA OPERACAO',
            style: pw.TextStyle(
                font: fontBold, fontSize: 9, color: _gdmBlue,
                letterSpacing: 1.5),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 14, runSpacing: 6,
            children: linhas.map((p) {
              return pw.SizedBox(
                width: 240,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 78,
                      child: pw.Text(
                        '${p[0]}:',
                        style: pw.TextStyle(
                            font: fontSemi,
                            fontSize: 9,
                            color: _cinzaMedio),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        p[1],
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tabelaItens(
      List<Map<String, dynamic>> itens, pw.Font bold, pw.Font semi) {
    if (itens.isEmpty) {
      return pw.Text('Nenhum item registrado',
          style: const pw.TextStyle(fontSize: 10, color: _cinzaMedio));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: const pw.BoxDecoration(color: _gdmLime),
          child: pw.Text(
            'ITENS DO CHECK-LIST',
            style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: _gdmBlue,
                letterSpacing: 1.5),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(3.5),
            2: pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _gdmBlue),
              children: [
                _th('#', bold),
                _th('Item', bold),
                _th('Valor', bold),
              ],
            ),
            ...itens.asMap().entries.map((entry) {
              final i = entry.key;
              final it = entry.value;
              final obrig = it['obrigatorio'] == true;
              final valor = _formatarValor(it);
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i % 2 == 0 ? PdfColors.white : _cinzaClaro,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 4),
                    child: pw.Text('${i + 1}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 6),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        text: it['descricao_item']?.toString() ??
                            it['chave_item']?.toString() ??
                            '—',
                        style: const pw.TextStyle(fontSize: 9),
                        children: obrig
                            ? [
                                pw.TextSpan(
                                    text: ' *',
                                    style: pw.TextStyle(
                                        color: PdfColors.red, font: bold)),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 6),
                    child: pw.Text(valor,
                        style: pw.TextStyle(font: semi, fontSize: 9)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _th(String t, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: pw.Text(t,
          style: pw.TextStyle(
              font: bold, fontSize: 9, color: PdfColors.white)),
    );
  }

  static String _formatarValor(Map<String, dynamic> it) {
    if (it['valor_numero'] != null) {
      final n = it['valor_numero'] as num;
      // Coordenadas GPS tipicas?
      final chave = it['chave_item']?.toString() ?? '';
      if (chave.startsWith('gps_')) {
        return n.toStringAsFixed(6);
      }
      return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
    }
    if (it['valor_booleano'] != null) {
      return it['valor_booleano'] == true ? 'Sim' : 'Nao';
    }
    final txt = it['valor_texto']?.toString();
    if (txt == null || txt.isEmpty) return '—';
    if (txt.length > 60) return '${txt.substring(0, 57)}...';
    return txt;
  }

  static pw.Widget _observacoes(String obs, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('OBSERVACOES GERAIS',
              style: pw.TextStyle(
                  font: bold, fontSize: 9, color: _gdmBlue,
                  letterSpacing: 1.5)),
          pw.SizedBox(height: 4),
          pw.Text(obs, style: const pw.TextStyle(fontSize: 9.5)),
        ],
      ),
    );
  }

  static pw.Widget _secaoFotos(
      List<Map<String, dynamic>> fotos, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: const pw.BoxDecoration(color: _gdmLime),
          child: pw.Text(
            'EVIDENCIAS FOTOGRAFICAS',
            style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: _gdmBlue,
                letterSpacing: 1.5),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8, runSpacing: 8,
          children: fotos.map((f) {
            final raw = f['valor_texto']?.toString() ?? '';
            try {
              final b64 = raw.split(',').last;
              final bytes = base64Decode(b64);
              return pw.Container(
                width: 240,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: PdfColors.grey400, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4)),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(
                          pw.MemoryImage(bytes),
                          width: 240,
                          height: 160,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      f['descricao_item']?.toString() ?? '',
                      style: const pw.TextStyle(
                          fontSize: 8, color: _cinzaMedio),
                    ),
                  ],
                ),
              );
            } catch (_) {
              return pw.SizedBox.shrink();
            }
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _assinaturas(String usuario, pw.Font semi) {
    return pw.Row(
      children: [
        pw.Expanded(child: _campoAssinatura(usuario, semi)),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _campoAssinatura('Responsavel pelo recebimento', semi)),
      ],
    );
  }

  static pw.Widget _campoAssinatura(String label, pw.Font semi) {
    return pw.Column(
      children: [
        pw.Container(
          height: 1,
          color: PdfColors.grey700,
        ),
        pw.SizedBox(height: 3),
        pw.Text(label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                font: semi, fontSize: 9, color: _cinzaMedio)),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx, pw.Font reg) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GDM Job Cars - Documento gerado automaticamente',
            style: pw.TextStyle(
                font: reg, fontSize: 7, color: _cinzaMedio),
          ),
          pw.Text(
            'Pagina ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(
                font: reg, fontSize: 7, color: _cinzaMedio),
          ),
        ],
      ),
    );
  }

  /// Abre o dialogo de impressao/compartilhamento.
  static Future<void> imprimirOuCompartilhar(
      Map<String, dynamic> checklist) async {
    final bytes = await gerar(checklist);
    final etapa = checklist['etapa']?.toString() ?? 'check';
    final codigo = checklist['codigo_interno']?.toString() ?? 'ativo';
    final filename =
        'checklist_${codigo}_${etapa.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: filename,
    );
  }
}
