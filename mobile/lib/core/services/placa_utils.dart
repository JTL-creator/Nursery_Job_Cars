/// Utilitarios para reconhecimento e normalizacao de placas de veiculos (Brasil).
class PlacaUtils {
  PlacaUtils._();

  /// Placa antiga (AAA0000) ou Mercosul (AAA0A00).
  /// 4o caractere sempre numero; 5o caractere letra (Mercosul) ou numero (antiga).
  static final RegExp _regex = RegExp(r'[A-Z]{3}[0-9][0-9A-Z][0-9]{2}');

  /// Remove separadores e coloca em maiusculas (ex.: "abc-1d23" -> "ABC1D23").
  static String normalizar(String? placa) =>
      (placa ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Valida se a string corresponde ao formato de uma placa brasileira.
  static bool valida(String? placa) {
    final n = normalizar(placa);
    return n.length == 7 && _regex.hasMatch(n);
  }

  /// Formata para exibicao com hifen (ABC-1D23).
  static String formatar(String? placa) {
    final n = normalizar(placa);
    if (n.length != 7) return n;
    return '${n.substring(0, 3)}-${n.substring(3)}';
  }

  /// Extrai a primeira placa valida encontrada em uma lista de linhas de texto
  /// (tipicamente as linhas reconhecidas pelo OCR). Retorna null se nao achar.
  static String? extrairDeLinhas(Iterable<String> linhas) {
    for (final linha in linhas) {
      final n = normalizar(linha);
      final m = _regex.firstMatch(n);
      if (m != null) return m.group(0);
    }
    return null;
  }

  /// Extrai a primeira placa valida de um texto livre.
  static String? extrair(String texto) => extrairDeLinhas(texto.split('\n'));
}
