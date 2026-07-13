import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modulos do app: uma parte para Veiculos, outra para Maquinas.
enum AppModule { veiculos, maquinas }

/// Guarda o modulo selecionado apos o login (Veiculos ou Maquinas).
/// Persiste a escolha em SharedPreferences.
class ModuleProvider extends ChangeNotifier {
  static const _key = 'modulo_selecionado';

  AppModule? _modulo;
  AppModule? get modulo => _modulo;
  bool get temModulo => _modulo != null;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v == 'veiculos') {
        _modulo = AppModule.veiculos;
      } else if (v == 'maquinas') {
        _modulo = AppModule.maquinas;
      }
    } catch (_) {/* ignora */}
    notifyListeners();
  }

  Future<void> selecionar(AppModule m) async {
    _modulo = m;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        m == AppModule.veiculos ? 'veiculos' : 'maquinas',
      );
    } catch (_) {/* ignora */}
  }

  Future<void> limpar() async {
    _modulo = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {/* ignora */}
  }

  /// Categoria enviada para a API (veiculos | maquinas).
  String get categoria =>
      _modulo == AppModule.veiculos ? 'veiculos' : 'maquinas';

  /// Tipos de ativo do modulo (maquinas inclui IMPLEMENTO).
  List<String> get tiposAtivo => _modulo == AppModule.veiculos
      ? const ['VEICULO']
      : const ['MAQUINA_AGRICOLA', 'IMPLEMENTO'];

  String get label => _modulo == AppModule.veiculos ? 'Veiculos' : 'Maquinas';

  IconData get icone =>
      _modulo == AppModule.veiculos ? Icons.directions_car : Icons.agriculture;
}
