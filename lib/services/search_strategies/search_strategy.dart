import '../../models/spiritual_profile_model.dart';
import '../../models/search_filters.dart';
import '../../models/search_result.dart';

/// Interface abstrata para estratégias de busca de perfis
///
/// Define o contrato que todas as estratégias de busca devem implementar.
/// Permite implementar diferentes abordagens de busca com fallback automático.
abstract class SearchStrategy {
  /// Nome identificador da estratégia
  String get name;

  /// Prioridade da estratégia (menor número = maior prioridade)
  int get priority;

  /// Indica se a estratégia está disponível para uso
  bool get isAvailable;

  /// Executa a busca usando esta estratégia
  ///
  /// [query] - Termo de busca
  /// [filters] - Filtros a serem aplicados
  /// [limit] - Número máximo de resultados
  ///
  /// Retorna [SearchResult] com os perfis encontrados e metadados
  Future<SearchResult> search({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  });

  /// Verifica se a estratégia pode lidar com os filtros fornecidos
  ///
  /// Algumas estratégias podem não suportar todos os tipos de filtros
  bool canHandleFilters(SearchFilters? filters);

  /// Estima o tempo de execução da busca em milissegundos
  ///
  /// Usado para escolher a estratégia mais eficiente
  int estimateExecutionTime(String query, SearchFilters? filters);

  /// Limpa qualquer cache específico desta estratégia
  void clearCache();

  /// Retorna estatísticas de uso desta estratégia
  Map<String, dynamic> getStats();
}

/// Classe base para implementações de SearchStrategy
///
/// Fornece funcionalidades comuns e estrutura básica
abstract class BaseSearchStrategy implements SearchStrategy {
  final String _name;
  final int _priority;

  // Estatísticas de uso
  int _attempts = 0;
  int _successes = 0;
  int _failures = 0;
  int _totalExecutionTime = 0;
  DateTime? _lastUsed;

  BaseSearchStrategy({
    required String name,
    required int priority,
  })  : _name = name,
        _priority = priority;

  @override
  String get name => _name;

  @override
  int get priority => _priority;

  @override
  bool get isAvailable => true; // Pode ser sobrescrito pelas implementações

  @override
  Future<SearchResult> search({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    _attempts++;
    _lastUsed = DateTime.now();

    final stopwatch = Stopwatch()..start();

    try {
      final result = await executeSearch(
        query: query,
        filters: filters,
        limit: limit,
      );

      stopwatch.stop();
      _totalExecutionTime += stopwatch.elapsedMilliseconds;
      _successes++;

      return result.copyWith(
        searchTime: Duration(milliseconds: stopwatch.elapsedMilliseconds),
        fromCache: false,
      );
    } catch (e) {
      stopwatch.stop();
      _failures++;
      rethrow;
    }
  }

  /// Método abstrato que deve ser implementado pelas estratégias concretas
  Future<SearchResult> executeSearch({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  });

  @override
  bool canHandleFilters(SearchFilters? filters) {
    // Implementação padrão - pode ser sobrescrita
    return true;
  }

  @override
  int estimateExecutionTime(String query, SearchFilters? filters) {
    // Estimativa baseada no histórico
    if (_successes > 0) {
      return (_totalExecutionTime / _successes).round();
    }

    // Estimativa padrão baseada na prioridade
    return priority * 100;
  }

  @override
  void clearCache() {
    // Implementação padrão vazia - pode ser sobrescrita
  }

  @override
  Map<String, dynamic> getStats() {
    return {
      'name': name,
      'priority': priority,
      'attempts': _attempts,
      'successes': _successes,
      'failures': _failures,
      'successRate': _attempts > 0
          ? (_successes / _attempts * 100).toStringAsFixed(1)
          : '0.0',
      'averageExecutionTime':
          _successes > 0 ? (_totalExecutionTime / _successes).round() : 0,
      'totalExecutionTime': _totalExecutionTime,
      'lastUsed': _lastUsed?.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }
}

/// Exceção específica para erros de estratégia de busca
class SearchStrategyException implements Exception {
  final String message;
  final String strategyName;
  final dynamic originalError;

  const SearchStrategyException({
    required this.message,
    required this.strategyName,
    this.originalError,
  });

  @override
  String toString() {
    return 'SearchStrategyException [$strategyName]: $message';
  }
}
