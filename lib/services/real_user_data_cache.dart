import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data_model.dart';
import '../utils/enhanced_logger.dart';

class RealUserDataCache {
  static final RealUserDataCache _instance = RealUserDataCache._internal();
  factory RealUserDataCache() => _instance;
  RealUserDataCache._internal();

  final Map<String, UserData> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TTL padrão de 1 hora
  final Duration _defaultTtl = const Duration(hours: 1);

  /// Busca dados do usuário (cache first)
  Future<UserData> getUserData(String userId, {Duration? ttl}) async {
    try {
      final effectiveTtl = ttl ?? _defaultTtl;

      // Verifica se existe no cache e não expirou
      if (_cache.containsKey(userId) && !_isExpired(userId, effectiveTtl)) {
        EnhancedLogger.debug('Cache hit para usuário: $userId');
        return _cache[userId]!;
      }

      EnhancedLogger.info('Buscando dados do usuário no Firebase: $userId');

      // Busca no Firebase
      final userData = await _fetchUserFromFirebase(userId);

      // Armazena no cache
      _cache[userId] = userData;
      _cacheTimestamps[userId] = DateTime.now();

      EnhancedLogger.success(
          'Dados do usuário carregados e cacheados: ${userData.getDisplayName()}');

      return userData;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao buscar dados do usuário',
          error: e, stackTrace: stackTrace);

      // Retorna dados do cache mesmo se expirado, ou fallback
      if (_cache.containsKey(userId)) {
        EnhancedLogger.warning('Usando dados expirados do cache para: $userId');
        return _cache[userId]!;
      }

      EnhancedLogger.warning('Usando dados de fallback para: $userId');
      return UserData.fallback(userId);
    }
  }

  /// Pré-carrega dados de múltiplos usuários
  Future<Map<String, UserData>> preloadUsers(List<String> userIds,
      {Duration? ttl}) async {
    final Map<String, UserData> results = {};
    final List<String> usersToFetch = [];
    final effectiveTtl = ttl ?? _defaultTtl;

    // Verifica quais usuários precisam ser buscados
    for (final userId in userIds) {
      if (_cache.containsKey(userId) && !_isExpired(userId, effectiveTtl)) {
        results[userId] = _cache[userId]!;
      } else {
        usersToFetch.add(userId);
      }
    }

    EnhancedLogger.info(
        'Pré-carregando ${usersToFetch.length} usuários do Firebase');

    // Busca usuários em lote
    if (usersToFetch.isNotEmpty) {
      final batchResults = await _fetchUsersInBatch(usersToFetch);
      results.addAll(batchResults);

      // Adiciona ao cache
      for (final entry in batchResults.entries) {
        _cache[entry.key] = entry.value;
        _cacheTimestamps[entry.key] = DateTime.now();
      }
    }

    EnhancedLogger.success(
        'Pré-carregamento concluído: ${results.length} usuários');
    return results;
  }

  /// Força atualização de um usuário específico
  Future<UserData> refreshUser(String userId) async {
    EnhancedLogger.info('Forçando atualização do usuário: $userId');

    // Remove do cache
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);

    // Busca novamente
    return await getUserData(userId);
  }

  /// Limpa o cache
  void clearCache() {
    EnhancedLogger.info('Limpando cache de usuários');
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Limpa usuários expirados do cache
  void cleanupExpiredEntries({Duration? ttl}) {
    final effectiveTtl = ttl ?? _defaultTtl;
    final expiredUsers = <String>[];

    for (final userId in _cache.keys) {
      if (_isExpired(userId, effectiveTtl)) {
        expiredUsers.add(userId);
      }
    }

    for (final userId in expiredUsers) {
      _cache.remove(userId);
      _cacheTimestamps.remove(userId);
    }

    if (expiredUsers.isNotEmpty) {
      EnhancedLogger.info(
          'Removidos ${expiredUsers.length} usuários expirados do cache');
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    return {
      'totalUsers': _cache.length,
      'timestamps': _cacheTimestamps.length,
      'oldestEntry': _cacheTimestamps.values.isEmpty
          ? null
          : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b),
      'newestEntry': _cacheTimestamps.values.isEmpty
          ? null
          : _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// Verifica se um usuário está expirado no cache
  bool _isExpired(String userId, Duration ttl) {
    if (!_cacheTimestamps.containsKey(userId)) return true;

    final timestamp = _cacheTimestamps[userId]!;
    return DateTime.now().difference(timestamp) > ttl;
  }

  /// Busca um usuário específico no Firebase
  Future<UserData> _fetchUserFromFirebase(String userId) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(userId).get();

      if (doc.exists) {
        return UserData.fromFirestore(doc);
      } else {
        EnhancedLogger.warning('Usuário não encontrado no Firebase: $userId');
        return UserData.fallback(userId);
      }
    } catch (e) {
      EnhancedLogger.error('Erro ao buscar usuário no Firebase: $userId',
          error: e);
      return UserData.fallback(userId);
    }
  }

  /// Busca múltiplos usuários em lote
  Future<Map<String, UserData>> _fetchUsersInBatch(List<String> userIds) async {
    final Map<String, UserData> results = {};

    try {
      // Firebase tem limite de 10 documentos por consulta 'in'
      const batchSize = 10;

      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final query = _firestore
            .collection('usuarios')
            .where(FieldPath.documentId, whereIn: batch);

        final querySnapshot = await query.get();

        for (final doc in querySnapshot.docs) {
          results[doc.id] = UserData.fromFirestore(doc);
        }

        // Adiciona fallbacks para usuários não encontrados
        for (final userId in batch) {
          if (!results.containsKey(userId)) {
            results[userId] = UserData.fallback(userId);
          }
        }
      }
    } catch (e) {
      EnhancedLogger.error('Erro na busca em lote', error: e);

      // Fallback: busca individual
      for (final userId in userIds) {
        if (!results.containsKey(userId)) {
          results[userId] = await _fetchUserFromFirebase(userId);
        }
      }
    }

    return results;
  }

  /// Debug: lista todos os usuários no cache
  void debugCacheContents() {
    EnhancedLogger.debug('=== CACHE CONTENTS ===');
    EnhancedLogger.debug('Total usuários: ${_cache.length}');

    for (final entry in _cache.entries) {
      final timestamp = _cacheTimestamps[entry.key];
      final age = timestamp != null
          ? DateTime.now().difference(timestamp).inMinutes
          : -1;

      EnhancedLogger.debug(
          '${entry.key}: ${entry.value.getDisplayName()} (${age}min ago)');
    }
    EnhancedLogger.debug('=== END CACHE ===');
  }
}
