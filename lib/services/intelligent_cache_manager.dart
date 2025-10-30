import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/diagnostic_logger.dart';
import '../utils/enhanced_logger.dart';

/// Resultado de operação de cache
class CacheResult<T> {
  final T? data;
  final bool isFromCache;
  final DateTime? cacheTime;
  final bool isExpired;

  CacheResult({
    this.data,
    required this.isFromCache,
    this.cacheTime,
    required this.isExpired,
  });

  bool get isValid => data != null && !isExpired;
}

/// Configuração de cache para diferentes tipos de dados
class CacheConfig {
  final Duration ttl; // Time to live
  final int maxSize; // Máximo de itens no cache
  final bool enableCompression;
  final bool enableEncryption;

  const CacheConfig({
    required this.ttl,
    this.maxSize = 1000,
    this.enableCompression = false,
    this.enableEncryption = false,
  });

  static const CacheConfig notifications = CacheConfig(
    ttl: Duration(minutes: 15),
    maxSize: 500,
    enableCompression: true,
  );

  static const CacheConfig userProfiles = CacheConfig(
    ttl: Duration(hours: 1),
    maxSize: 200,
    enableCompression: true,
  );

  static const CacheConfig systemData = CacheConfig(
    ttl: Duration(minutes: 5),
    maxSize: 100,
  );

  static const CacheConfig temporaryData = CacheConfig(
    ttl: Duration(minutes: 2),
    maxSize: 50,
  );
}

/// Entry de cache com metadados
class CacheEntry<T> {
  final String key;
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int accessCount;
  final DateTime lastAccessed;
  final int size;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    this.accessCount = 0,
    DateTime? lastAccessed,
    this.size = 0,
  }) : lastAccessed = lastAccessed ?? createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get age => DateTime.now().difference(createdAt);

  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);

  CacheEntry<T> copyWithAccess() {
    return CacheEntry<T>(
      key: key,
      data: data,
      createdAt: createdAt,
      expiresAt: expiresAt,
      accessCount: accessCount + 1,
      lastAccessed: DateTime.now(),
      size: size,
    );
  }
}

/// Gerenciador de cache inteligente com invalidação automática
class IntelligentCacheManager {
  static final IntelligentCacheManager _instance =
      IntelligentCacheManager._internal();
  factory IntelligentCacheManager() => _instance;
  IntelligentCacheManager._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, CacheConfig> _cacheConfigs = {};
  final DiagnosticLogger _logger = DiagnosticLogger();

  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  Timer? _persistenceTimer;

  static const String _persistentCacheKey = 'intelligent_cache_data';
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _persistenceInterval = Duration(minutes: 10);

  /// Inicializa o gerenciador de cache
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistentCache();
      _startPeriodicCleanup();
      _startPeriodicPersistence();

      _logger.info(
        DiagnosticLogCategory.system,
        'Cache inteligente inicializado',
        data: {
          'memoryEntries': _memoryCache.length,
          'cleanupInterval': _cleanupInterval.inMinutes,
          'persistenceInterval': _persistenceInterval.inMinutes,
        },
      );

      EnhancedLogger.log(
          '🧠 [INTELLIGENT_CACHE] Cache inicializado com ${_memoryCache.length} entradas');
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.system,
        'Erro na inicialização do cache',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );

      EnhancedLogger.log('❌ [INTELLIGENT_CACHE] Erro na inicialização: $e');
    }
  }

  /// Registra configuração de cache para um tipo específico
  void registerCacheConfig(String type, CacheConfig config) {
    _cacheConfigs[type] = config;

    _logger.debug(
      DiagnosticLogCategory.system,
      'Configuração de cache registrada',
      data: {
        'type': type,
        'ttl': config.ttl.inMinutes,
        'maxSize': config.maxSize,
      },
    );
  }

  /// Obtém dados do cache ou executa função para buscar
  Future<CacheResult<T>> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFunction, {
    String cacheType = 'default',
    Duration? customTtl,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Tenta obter do cache primeiro
      final cached = await get<T>(key, cacheType: cacheType);

      if (cached.isValid) {
        stopwatch.stop();

        _logger.debug(
          DiagnosticLogCategory.performance,
          'Cache hit',
          data: {
            'key': key,
            'cacheType': cacheType,
            'age': cached.cacheTime != null
                ? DateTime.now().difference(cached.cacheTime!).inSeconds
                : 0,
          },
          executionTime: stopwatch.elapsed,
        );

        return cached;
      }

      // Cache miss - busca dados
      _logger.debug(
        DiagnosticLogCategory.performance,
        'Cache miss - buscando dados',
        data: {'key': key, 'cacheType': cacheType},
      );

      final data = await fetchFunction();

      // Armazena no cache
      await set(key, data, cacheType: cacheType, customTtl: customTtl);

      stopwatch.stop();

      _logger.info(
        DiagnosticLogCategory.performance,
        'Dados buscados e armazenados no cache',
        data: {
          'key': key,
          'cacheType': cacheType,
          'dataSize': _estimateSize(data),
        },
        executionTime: stopwatch.elapsed,
      );

      return CacheResult<T>(
        data: data,
        isFromCache: false,
        cacheTime: DateTime.now(),
        isExpired: false,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro ao buscar dados com cache',
        data: {
          'key': key,
          'cacheType': cacheType,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
        executionTime: stopwatch.elapsed,
      );

      rethrow;
    }
  }

  /// Obtém dados do cache
  Future<CacheResult<T>> get<T>(String key,
      {String cacheType = 'default'}) async {
    final fullKey = _buildKey(cacheType, key);
    final entry = _memoryCache[fullKey];

    if (entry == null) {
      return CacheResult<T>(
        data: null,
        isFromCache: false,
        isExpired: false,
      );
    }

    // Atualiza estatísticas de acesso
    _memoryCache[fullKey] = entry.copyWithAccess();

    if (entry.isExpired) {
      _memoryCache.remove(fullKey);

      _logger.debug(
        DiagnosticLogCategory.performance,
        'Cache entry expirado removido',
        data: {'key': key, 'cacheType': cacheType},
      );

      return CacheResult<T>(
        data: null,
        isFromCache: true,
        cacheTime: entry.createdAt,
        isExpired: true,
      );
    }

    return CacheResult<T>(
      data: entry.data as T,
      isFromCache: true,
      cacheTime: entry.createdAt,
      isExpired: false,
    );
  }

  /// Armazena dados no cache
  Future<void> set<T>(
    String key,
    T data, {
    String cacheType = 'default',
    Duration? customTtl,
  }) async {
    final config = _cacheConfigs[cacheType] ?? CacheConfig.temporaryData;
    final ttl = customTtl ?? config.ttl;
    final fullKey = _buildKey(cacheType, key);

    final now = DateTime.now();
    final entry = CacheEntry<T>(
      key: fullKey,
      data: data,
      createdAt: now,
      expiresAt: now.add(ttl),
      size: _estimateSize(data),
    );

    _memoryCache[fullKey] = entry;

    // Verifica se precisa fazer limpeza por tamanho
    await _enforceMaxSize(cacheType, config);

    _logger.debug(
      DiagnosticLogCategory.performance,
      'Dados armazenados no cache',
      data: {
        'key': key,
        'cacheType': cacheType,
        'ttl': ttl.inMinutes,
        'size': entry.size,
        'totalEntries': _memoryCache.length,
      },
    );
  }

  /// Remove entrada específica do cache
  Future<void> remove(String key, {String cacheType = 'default'}) async {
    final fullKey = _buildKey(cacheType, key);
    final removed = _memoryCache.remove(fullKey);

    if (removed != null) {
      _logger.debug(
        DiagnosticLogCategory.performance,
        'Entrada removida do cache',
        data: {'key': key, 'cacheType': cacheType},
      );
    }
  }

  /// Invalida cache por padrão de chave
  Future<void> invalidatePattern(String pattern, {String? cacheType}) async {
    final keysToRemove = <String>[];

    for (final key in _memoryCache.keys) {
      if (cacheType != null && !key.startsWith('${cacheType}:')) continue;

      final actualKey = key.contains(':') ? key.split(':').last : key;
      if (actualKey.contains(pattern)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    _logger.info(
      DiagnosticLogCategory.performance,
      'Cache invalidado por padrão',
      data: {
        'pattern': pattern,
        'cacheType': cacheType,
        'removedEntries': keysToRemove.length,
      },
    );

    EnhancedLogger.log(
        '🧹 [INTELLIGENT_CACHE] ${keysToRemove.length} entradas invalidadas por padrão: $pattern');
  }

  /// Invalida todo cache de um tipo
  Future<void> invalidateType(String cacheType) async {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.startsWith('${cacheType}:'))
        .toList();

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    _logger.info(
      DiagnosticLogCategory.performance,
      'Cache de tipo invalidado',
      data: {
        'cacheType': cacheType,
        'removedEntries': keysToRemove.length,
      },
    );

    EnhancedLogger.log(
        '🧹 [INTELLIGENT_CACHE] Cache tipo "$cacheType" invalidado (${keysToRemove.length} entradas)');
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    final entriesCount = _memoryCache.length;
    _memoryCache.clear();

    _logger.info(
      DiagnosticLogCategory.performance,
      'Cache completamente limpo',
      data: {'removedEntries': entriesCount},
    );

    EnhancedLogger.log(
        '🧹 [INTELLIGENT_CACHE] Cache limpo ($entriesCount entradas removidas)');
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final typeStats = <String, Map<String, dynamic>>{};

    int totalSize = 0;
    int expiredCount = 0;
    int totalAccesses = 0;

    for (final entry in _memoryCache.values) {
      final type =
          entry.key.contains(':') ? entry.key.split(':').first : 'default';

      typeStats[type] ??= {
        'count': 0,
        'size': 0,
        'expired': 0,
        'accesses': 0,
        'avgAge': 0.0,
      };

      typeStats[type]!['count'] = (typeStats[type]!['count'] as int) + 1;
      typeStats[type]!['size'] = (typeStats[type]!['size'] as int) + entry.size;
      typeStats[type]!['accesses'] =
          (typeStats[type]!['accesses'] as int) + entry.accessCount;

      if (entry.isExpired) {
        expiredCount++;
        typeStats[type]!['expired'] = (typeStats[type]!['expired'] as int) + 1;
      }

      totalSize += entry.size;
      totalAccesses += entry.accessCount;
    }

    // Calcula idade média por tipo
    for (final type in typeStats.keys) {
      final entries = _memoryCache.values.where((e) => e.key.contains(':')
          ? e.key.split(':').first == type
          : type == 'default');

      if (entries.isNotEmpty) {
        final avgAge =
            entries.map((e) => e.age.inSeconds).reduce((a, b) => a + b) /
                entries.length;
        typeStats[type]!['avgAge'] = avgAge;
      }
    }

    return {
      'totalEntries': _memoryCache.length,
      'totalSize': totalSize,
      'expiredEntries': expiredCount,
      'totalAccesses': totalAccesses,
      'hitRate':
          totalAccesses > 0 ? (_memoryCache.length / totalAccesses) : 0.0,
      'typeStatistics': typeStats,
      'memoryUsage': _estimateMemoryUsage(),
      'lastCleanup': _lastCleanupTime?.toIso8601String(),
      'configuredTypes': _cacheConfigs.keys.toList(),
    };
  }

  /// Força limpeza do cache
  Future<void> forceCleanup() async {
    await _performCleanup();

    _logger.info(
      DiagnosticLogCategory.performance,
      'Limpeza forçada do cache executada',
      data: {'remainingEntries': _memoryCache.length},
    );
  }

  /// Constrói chave completa do cache
  String _buildKey(String cacheType, String key) {
    return '${cacheType}:${key}';
  }

  /// Estima tamanho dos dados
  int _estimateSize(dynamic data) {
    try {
      if (data == null) return 0;

      if (data is String) return data.length * 2; // UTF-16
      if (data is int) return 8;
      if (data is double) return 8;
      if (data is bool) return 1;
      if (data is List) return data.length * 50; // Estimativa
      if (data is Map) return data.length * 100; // Estimativa

      // Para objetos complexos, tenta serializar
      final json = jsonEncode(data);
      return json.length * 2;
    } catch (e) {
      return 1000; // Estimativa padrão
    }
  }

  /// Estima uso de memória total
  int _estimateMemoryUsage() {
    return _memoryCache.values
        .map((entry) => entry.size + 200) // Overhead por entrada
        .fold(0, (sum, size) => sum + size);
  }

  /// Aplica limite máximo de tamanho por tipo
  Future<void> _enforceMaxSize(String cacheType, CacheConfig config) async {
    final typeEntries = _memoryCache.entries
        .where((entry) => entry.key.startsWith('${cacheType}:'))
        .toList();

    if (typeEntries.length <= config.maxSize) return;

    // Ordena por LRU (Least Recently Used)
    typeEntries
        .sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    final toRemove = typeEntries.length - config.maxSize;
    for (int i = 0; i < toRemove; i++) {
      _memoryCache.remove(typeEntries[i].key);
    }

    _logger.debug(
      DiagnosticLogCategory.performance,
      'Cache LRU cleanup executado',
      data: {
        'cacheType': cacheType,
        'removedEntries': toRemove,
        'remainingEntries': config.maxSize,
      },
    );
  }

  DateTime? _lastCleanupTime;

  /// Inicia limpeza periódica
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Executa limpeza do cache
  Future<void> _performCleanup() async {
    final initialCount = _memoryCache.length;
    final expiredKeys = <String>[];

    // Remove entradas expiradas
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    _lastCleanupTime = DateTime.now();

    if (expiredKeys.isNotEmpty) {
      _logger.debug(
        DiagnosticLogCategory.performance,
        'Limpeza automática do cache executada',
        data: {
          'initialEntries': initialCount,
          'expiredRemoved': expiredKeys.length,
          'remainingEntries': _memoryCache.length,
        },
      );

      EnhancedLogger.log(
          '🧹 [INTELLIGENT_CACHE] Limpeza automática: ${expiredKeys.length} entradas expiradas removidas');
    }
  }

  /// Inicia persistência periódica
  void _startPeriodicPersistence() {
    _persistenceTimer = Timer.periodic(_persistenceInterval, (_) {
      _persistCache();
    });
  }

  /// Persiste cache importante
  Future<void> _persistCache() async {
    try {
      final importantEntries = _memoryCache.entries
          .where(
              (entry) => !entry.value.isExpired && entry.value.accessCount > 1)
          .take(100) // Limita a 100 entradas mais importantes
          .map((entry) => {
                'key': entry.key,
                'data': entry.value.data,
                'createdAt': entry.value.createdAt.toIso8601String(),
                'expiresAt': entry.value.expiresAt.toIso8601String(),
                'accessCount': entry.value.accessCount,
              })
          .toList();

      if (importantEntries.isNotEmpty) {
        final json = jsonEncode(importantEntries);
        await _prefs?.setString(_persistentCacheKey, json);

        _logger.debug(
          DiagnosticLogCategory.performance,
          'Cache persistido',
          data: {'persistedEntries': importantEntries.length},
        );
      }
    } catch (e) {
      _logger.warning(
        DiagnosticLogCategory.performance,
        'Erro ao persistir cache',
        data: {'error': e.toString()},
      );
    }
  }

  /// Carrega cache persistido
  Future<void> _loadPersistentCache() async {
    try {
      final json = _prefs?.getString(_persistentCacheKey);
      if (json == null) return;

      final List<dynamic> entries = jsonDecode(json);
      int loadedCount = 0;

      for (final entryData in entries) {
        try {
          final key = entryData['key'] as String;
          final createdAt = DateTime.parse(entryData['createdAt']);
          final expiresAt = DateTime.parse(entryData['expiresAt']);

          // Só carrega se ainda não expirou
          if (DateTime.now().isBefore(expiresAt)) {
            final entry = CacheEntry(
              key: key,
              data: entryData['data'],
              createdAt: createdAt,
              expiresAt: expiresAt,
              accessCount: entryData['accessCount'] ?? 0,
            );

            _memoryCache[key] = entry;
            loadedCount++;
          }
        } catch (e) {
          // Ignora entradas corrompidas
          continue;
        }
      }

      if (loadedCount > 0) {
        _logger.info(
          DiagnosticLogCategory.performance,
          'Cache persistido carregado',
          data: {'loadedEntries': loadedCount},
        );

        EnhancedLogger.log(
            '💾 [INTELLIGENT_CACHE] $loadedCount entradas carregadas do cache persistido');
      }
    } catch (e) {
      _logger.warning(
        DiagnosticLogCategory.performance,
        'Erro ao carregar cache persistido',
        data: {'error': e.toString()},
      );
    }
  }

  /// Dispose dos recursos
  void dispose() {
    _cleanupTimer?.cancel();
    _persistenceTimer?.cancel();
    _persistCache();

    _logger.info(
      DiagnosticLogCategory.system,
      'Cache inteligente finalizado',
      data: {'finalEntries': _memoryCache.length},
    );

    EnhancedLogger.log('🧠 [INTELLIGENT_CACHE] Cache finalizado');
  }
}
