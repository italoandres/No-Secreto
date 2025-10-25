import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/certification_request_model.dart';

/// Serviço de busca para certificações
///
/// Fornece funcionalidades avançadas de busca incluindo:
/// - Busca em tempo real com debounce
/// - Histórico de buscas
/// - Sugestões automáticas
/// - Busca em múltiplos campos
class CertificationSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Chave para armazenar histórico de buscas
  static const String _searchHistoryKey = 'certification_search_history';
  static const int _maxHistoryItems = 10;

  // Timer para debounce
  Timer? _debounceTimer;

  /// Busca certificações por termo
  ///
  /// Busca em: nome do usuário, email, email de compra
  Future<List<CertificationRequestModel>> searchCertifications({
    required String searchTerm,
    String? status,
    int limit = 50,
  }) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    try {
      final searchLower = searchTerm.toLowerCase().trim();

      // Buscar todas as certificações (com filtro de status se fornecido)
      Query query = _firestore.collection('spiritual_certifications');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();

      // Filtrar no cliente por múltiplos campos
      final results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).where((cert) {
        final userName = (cert.userName ?? '').toLowerCase();
        final userEmail = (cert.userEmail ?? '').toLowerCase();
        final purchaseEmail = (cert.purchaseEmail ?? '').toLowerCase();

        return userName.contains(searchLower) ||
            userEmail.contains(searchLower) ||
            purchaseEmail.contains(searchLower);
      }).toList();

      // Salvar no histórico se houver resultados
      if (results.isNotEmpty) {
        await _saveToHistory(searchTerm);
      }

      return results;
    } catch (e) {
      print('Erro ao buscar certificações: $e');
      return [];
    }
  }

  /// Busca com debounce para evitar muitas requisições
  Future<List<CertificationRequestModel>> searchWithDebounce({
    required String searchTerm,
    String? status,
    Duration debounceTime = const Duration(milliseconds: 500),
    required Function(List<CertificationRequestModel>) onResults,
  }) async {
    // Cancelar timer anterior
    _debounceTimer?.cancel();

    // Criar novo timer
    final completer = Completer<List<CertificationRequestModel>>();

    _debounceTimer = Timer(debounceTime, () async {
      final results = await searchCertifications(
        searchTerm: searchTerm,
        status: status,
      );
      onResults(results);
      completer.complete(results);
    });

    return completer.future;
  }

  /// Salva termo de busca no histórico
  Future<void> _saveToHistory(String searchTerm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();

      // Remover se já existe
      history.remove(searchTerm);

      // Adicionar no início
      history.insert(0, searchTerm);

      // Limitar tamanho
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Salvar
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      print('Erro ao salvar histórico de busca: $e');
    }
  }

  /// Obtém histórico de buscas
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      print('Erro ao obter histórico de busca: $e');
      return [];
    }
  }

  /// Limpa histórico de buscas
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      print('Erro ao limpar histórico de busca: $e');
    }
  }

  /// Remove um item específico do histórico
  Future<void> removeFromHistory(String searchTerm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      history.remove(searchTerm);
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      print('Erro ao remover do histórico: $e');
    }
  }

  /// Obtém sugestões baseadas no histórico e termo parcial
  Future<List<String>> getSuggestions(String partialTerm) async {
    if (partialTerm.trim().isEmpty) {
      return await getSearchHistory();
    }

    final history = await getSearchHistory();
    final lowerTerm = partialTerm.toLowerCase();

    return history
        .where((term) => term.toLowerCase().contains(lowerTerm))
        .toList();
  }

  /// Cancela operações pendentes
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Resultado de busca com informações adicionais
class CertificationSearchResult {
  final List<CertificationRequestModel> certifications;
  final String searchTerm;
  final int totalFound;
  final Duration searchDuration;

  CertificationSearchResult({
    required this.certifications,
    required this.searchTerm,
    required this.totalFound,
    required this.searchDuration,
  });
}
