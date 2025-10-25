import 'dart:async';
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';

/// Gerenciador avançado de paginação para otimizar performance
/// com pre-loading, cache de páginas e otimizações de memória
class SearchPaginationManager {
  static SearchPaginationManager? _instance;
  static SearchPaginationManager get instance =>
      _instance ??= SearchPaginationManager._();

  SearchPaginationManager._();

  /// Cache de páginas por query
  final Map<String, PaginatedSearchSession> _sessions = {};

  /// Configurações de paginação
  static const int defaultPageSize = 20;
  static const int maxCachedPages = 10;
  static const int preloadThreshold =
      3; // Páginas restantes para iniciar preload
  static const Duration sessionTimeout = Duration(minutes: 15);

  /// Timer para limpeza de sessões expiradas
  Timer? _cleanupTimer;

  /// Inicializa o gerenciador
  void initialize() {
    _startCleanupTimer();

    EnhancedLogger.info('Search pagination manager initialized',
        tag: 'SEARCH_PAGINATION_MANAGER',
        data: {
          'defaultPageSize': defaultPageSize,
          'maxCachedPages': maxCachedPages,
          'preloadThreshold': preloadThreshold,
          'sessionTimeout': sessionTimeout.inMinutes,
        });
  }

  /// Cria ou obtém uma sessão de busca paginada
  Future<PaginatedSearchResult> startPaginatedSearch({
    required String query,
    SearchFilters? filters,
    int pageSize = defaultPageSize,
    required Future<SearchResult> Function(
            String query, SearchFilters? filters, int limit, int offset)
        searchFunction,
  }) async {
    final sessionKey = _generateSessionKey(query, filters, pageSize);

    // Verificar se já existe uma sessão ativa
    var session = _sessions[sessionKey];
    if (session != null && !session.isExpired) {
      EnhancedLogger.debug('Reusing existing pagination session',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'sessionKey': sessionKey,
            'currentPage': session.currentPage,
            'totalPages': session.totalPages,
            'cachedPages': session.cachedPages.length,
          });

      return _buildPaginatedResult(session, 0);
    }

    // Criar nova sessão
    session = PaginatedSearchSession(
      sessionKey: sessionKey,
      query: query,
      filters: filters,
      pageSize: pageSize,
      searchFunction: searchFunction,
      createdAt: DateTime.now(),
    );

    _sessions[sessionKey] = session;

    EnhancedLogger.info('Starting new paginated search session',
        tag: 'SEARCH_PAGINATION_MANAGER',
        data: {
          'sessionKey': sessionKey,
          'query': query,
          'hasFilters': filters != null,
          'pageSize': pageSize,
        });

    // Carregar primeira página
    return await _loadPage(session, 0);
  }

  /// Carrega uma página específica
  Future<PaginatedSearchResult> loadPage({
    required String query,
    SearchFilters? filters,
    required int pageNumber,
    int pageSize = defaultPageSize,
  }) async {
    final sessionKey = _generateSessionKey(query, filters, pageSize);
    final session = _sessions[sessionKey];

    if (session == null || session.isExpired) {
      throw Exception(
          'Pagination session not found or expired. Start a new search first.');
    }

    return await _loadPage(session, pageNumber);
  }

  /// Carrega próxima página
  Future<PaginatedSearchResult?> loadNextPage({
    required String query,
    SearchFilters? filters,
    int pageSize = defaultPageSize,
  }) async {
    final sessionKey = _generateSessionKey(query, filters, pageSize);
    final session = _sessions[sessionKey];

    if (session == null || session.isExpired) {
      return null;
    }

    if (!session.hasNextPage) {
      return null;
    }

    return await _loadPage(session, session.currentPage + 1);
  }

  /// Carrega página anterior
  Future<PaginatedSearchResult?> loadPreviousPage({
    required String query,
    SearchFilters? filters,
    int pageSize = defaultPageSize,
  }) async {
    final sessionKey = _generateSessionKey(query, filters, pageSize);
    final session = _sessions[sessionKey];

    if (session == null || session.isExpired || session.currentPage <= 0) {
      return null;
    }

    return await _loadPage(session, session.currentPage - 1);
  }

  /// Implementação interna para carregar uma página
  Future<PaginatedSearchResult> _loadPage(
      PaginatedSearchSession session, int pageNumber) async {
    final startTime = DateTime.now();

    // Verificar se a página já está em cache
    if (session.cachedPages.containsKey(pageNumber)) {
      session.currentPage = pageNumber;
      session.lastAccessedAt = DateTime.now();

      EnhancedLogger.debug('Page loaded from cache',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'sessionKey': session.sessionKey,
            'pageNumber': pageNumber,
            'cacheHit': true,
          });

      // Verificar se precisa fazer preload
      _checkPreloadNeeds(session, pageNumber);

      return _buildPaginatedResult(session, pageNumber);
    }

    // Carregar página do servidor
    try {
      final offset = pageNumber * session.pageSize;
      final result = await session.searchFunction(
        session.query,
        session.filters,
        session.pageSize,
        offset,
      );

      // Atualizar informações da sessão
      if (session.totalResults == null) {
        session.totalResults = result.profiles.length < session.pageSize
            ? offset + result.profiles.length
            : null; // Não sabemos o total ainda
        session.totalPages = session.totalResults != null
            ? (session.totalResults! / session.pageSize).ceil()
            : null;
      }

      // Cachear a página
      session.cachedPages[pageNumber] = CachedPage(
        pageNumber: pageNumber,
        profiles: result.profiles,
        cachedAt: DateTime.now(),
        fromCache: result.fromCache,
      );

      // Limitar cache se necessário
      _limitCacheSize(session);

      session.currentPage = pageNumber;
      session.lastAccessedAt = DateTime.now();

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      EnhancedLogger.info('Page loaded from server',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'sessionKey': session.sessionKey,
            'pageNumber': pageNumber,
            'profilesCount': result.profiles.length,
            'executionTime': executionTime,
            'cacheHit': false,
            'fromCache': result.fromCache,
          });

      // Verificar se precisa fazer preload
      _checkPreloadNeeds(session, pageNumber);

      return _buildPaginatedResult(session, pageNumber);
    } catch (e) {
      EnhancedLogger.error('Failed to load page',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'sessionKey': session.sessionKey,
            'pageNumber': pageNumber,
            'error': e.toString(),
          });
      rethrow;
    }
  }

  /// Constrói resultado paginado
  PaginatedSearchResult _buildPaginatedResult(
      PaginatedSearchSession session, int pageNumber) {
    final cachedPage = session.cachedPages[pageNumber];
    if (cachedPage == null) {
      throw Exception('Page $pageNumber not found in cache');
    }

    return PaginatedSearchResult(
      profiles: cachedPage.profiles,
      currentPage: pageNumber,
      pageSize: session.pageSize,
      totalPages: session.totalPages,
      totalResults: session.totalResults,
      hasNextPage: session.hasNextPage,
      hasPreviousPage: pageNumber > 0,
      fromCache: cachedPage.fromCache,
      sessionKey: session.sessionKey,
      query: session.query,
      filters: session.filters,
    );
  }

  /// Verifica se precisa fazer preload de páginas
  void _checkPreloadNeeds(PaginatedSearchSession session, int currentPage) {
    if (session.totalPages == null) return;

    final remainingPages = session.totalPages! - currentPage - 1;

    if (remainingPages <= preloadThreshold && remainingPages > 0) {
      // Fazer preload das próximas páginas em background
      _preloadPages(session, currentPage + 1,
          math.min(currentPage + preloadThreshold, session.totalPages! - 1));
    }
  }

  /// Faz preload de páginas em background
  void _preloadPages(
      PaginatedSearchSession session, int startPage, int endPage) {
    for (int page = startPage; page <= endPage; page++) {
      if (!session.cachedPages.containsKey(page)) {
        // Preload em background sem bloquear
        _loadPage(session, page).catchError((error) {
          EnhancedLogger.warning('Preload failed for page $page',
              tag: 'SEARCH_PAGINATION_MANAGER',
              data: {
                'sessionKey': session.sessionKey,
                'page': page,
                'error': error.toString(),
              });
        });
      }
    }
  }

  /// Limita o tamanho do cache removendo páginas mais antigas
  void _limitCacheSize(PaginatedSearchSession session) {
    if (session.cachedPages.length <= maxCachedPages) return;

    // Ordenar páginas por tempo de cache (mais antigas primeiro)
    final sortedPages = session.cachedPages.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

    // Remover páginas mais antigas
    final pagesToRemove = session.cachedPages.length - maxCachedPages;
    for (int i = 0; i < pagesToRemove; i++) {
      final pageToRemove = sortedPages[i].key;
      session.cachedPages.remove(pageToRemove);

      EnhancedLogger.debug('Removed cached page due to size limit',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'sessionKey': session.sessionKey,
            'removedPage': pageToRemove,
            'remainingPages': session.cachedPages.length,
          });
    }
  }

  /// Gera chave única para a sessão
  String _generateSessionKey(
      String query, SearchFilters? filters, int pageSize) {
    final buffer = StringBuffer();
    buffer.write('q:${query.toLowerCase()}');
    buffer.write('|ps:$pageSize');

    if (filters != null) {
      if (filters.minAge != null) buffer.write('|minAge:${filters.minAge}');
      if (filters.maxAge != null) buffer.write('|maxAge:${filters.maxAge}');
      if (filters.city != null && filters.city!.isNotEmpty) {
        buffer.write('|city:${filters.city!.toLowerCase()}');
      }
      if (filters.state != null && filters.state!.isNotEmpty) {
        buffer.write('|state:${filters.state!.toLowerCase()}');
      }
      if (filters.interests != null && filters.interests!.isNotEmpty) {
        final sortedInterests = List<String>.from(filters.interests!)
          ..sort()
          ..map((i) => i.toLowerCase());
        buffer.write('|interests:${sortedInterests.join(',')}');
      }
      if (filters.isVerified != null) {
        buffer.write('|verified:${filters.isVerified}');
      }
      if (filters.hasCompletedCourse != null) {
        buffer.write('|course:${filters.hasCompletedCourse}');
      }
    }

    return buffer.toString();
  }

  /// Inicia timer de limpeza de sessões expiradas
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredSessions();
    });
  }

  /// Remove sessões expiradas
  void _cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _sessions.forEach((key, session) {
      if (session.isExpired) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _sessions.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.info('Cleaned up expired pagination sessions',
          tag: 'SEARCH_PAGINATION_MANAGER',
          data: {
            'expiredSessions': expiredKeys.length,
            'activeSessions': _sessions.length,
          });
    }
  }

  /// Obtém estatísticas de paginação
  Map<String, dynamic> getPaginationStats() {
    final now = DateTime.now();
    int totalCachedPages = 0;
    int totalSessions = _sessions.length;

    final sessionStats = <String, Map<String, dynamic>>{};

    _sessions.forEach((key, session) {
      totalCachedPages += session.cachedPages.length;

      sessionStats[key] = {
        'query': session.query,
        'currentPage': session.currentPage,
        'totalPages': session.totalPages,
        'cachedPages': session.cachedPages.length,
        'createdAt': session.createdAt.toIso8601String(),
        'lastAccessedAt': session.lastAccessedAt.toIso8601String(),
        'ageMinutes': now.difference(session.createdAt).inMinutes,
        'isExpired': session.isExpired,
      };
    });

    return {
      'timestamp': now.toIso8601String(),
      'totalSessions': totalSessions,
      'totalCachedPages': totalCachedPages,
      'averageCachedPagesPerSession':
          totalSessions > 0 ? totalCachedPages / totalSessions : 0.0,
      'configuration': {
        'defaultPageSize': defaultPageSize,
        'maxCachedPages': maxCachedPages,
        'preloadThreshold': preloadThreshold,
        'sessionTimeoutMinutes': sessionTimeout.inMinutes,
      },
      'sessions': sessionStats,
    };
  }

  /// Limpa uma sessão específica
  void clearSession({
    required String query,
    SearchFilters? filters,
    int pageSize = defaultPageSize,
  }) {
    final sessionKey = _generateSessionKey(query, filters, pageSize);
    _sessions.remove(sessionKey);

    EnhancedLogger.info('Pagination session cleared',
        tag: 'SEARCH_PAGINATION_MANAGER', data: {'sessionKey': sessionKey});
  }

  /// Limpa todas as sessões
  void clearAllSessions() {
    final sessionCount = _sessions.length;
    _sessions.clear();

    EnhancedLogger.info('All pagination sessions cleared',
        tag: 'SEARCH_PAGINATION_MANAGER',
        data: {'clearedSessions': sessionCount});
  }

  /// Para o gerenciador
  void dispose() {
    _cleanupTimer?.cancel();
    _sessions.clear();

    EnhancedLogger.info('Search pagination manager disposed',
        tag: 'SEARCH_PAGINATION_MANAGER');
  }
}

/// Sessão de busca paginada
class PaginatedSearchSession {
  final String sessionKey;
  final String query;
  final SearchFilters? filters;
  final int pageSize;
  final Future<SearchResult> Function(
          String query, SearchFilters? filters, int limit, int offset)
      searchFunction;
  final DateTime createdAt;

  int currentPage = 0;
  int? totalResults;
  int? totalPages;
  DateTime lastAccessedAt;
  final Map<int, CachedPage> cachedPages = {};

  PaginatedSearchSession({
    required this.sessionKey,
    required this.query,
    required this.filters,
    required this.pageSize,
    required this.searchFunction,
    required this.createdAt,
  }) : lastAccessedAt = createdAt;

  bool get isExpired =>
      DateTime.now().difference(lastAccessedAt) >
      SearchPaginationManager.sessionTimeout;

  bool get hasNextPage {
    if (totalPages == null) {
      // Se não sabemos o total, assumir que há próxima página se a atual tem resultados completos
      final currentPageData = cachedPages[currentPage];
      return currentPageData != null &&
          currentPageData.profiles.length == pageSize;
    }
    return currentPage < totalPages! - 1;
  }
}

/// Página em cache
class CachedPage {
  final int pageNumber;
  final List<SpiritualProfileModel> profiles;
  final DateTime cachedAt;
  final bool fromCache;

  const CachedPage({
    required this.pageNumber,
    required this.profiles,
    required this.cachedAt,
    required this.fromCache,
  });
}

/// Resultado de busca paginada
class PaginatedSearchResult {
  final List<SpiritualProfileModel> profiles;
  final int currentPage;
  final int pageSize;
  final int? totalPages;
  final int? totalResults;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool fromCache;
  final String sessionKey;
  final String query;
  final SearchFilters? filters;

  const PaginatedSearchResult({
    required this.profiles,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalResults,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.fromCache,
    required this.sessionKey,
    required this.query,
    required this.filters,
  });

  Map<String, dynamic> toJson() {
    return {
      'profilesCount': profiles.length,
      'currentPage': currentPage,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'totalResults': totalResults,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'fromCache': fromCache,
      'sessionKey': sessionKey,
      'query': query,
      'hasFilters': filters != null,
    };
  }
}
