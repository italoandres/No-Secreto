import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interest_model.dart';
import '../models/user_data_model.dart';
import '../utils/enhanced_logger.dart';

/// Repository robusto para interações reais com retry e validação
class EnhancedRealInterestsRepository {
  static EnhancedRealInterestsRepository? _instance;
  static EnhancedRealInterestsRepository get instance =>
      _instance ??= EnhancedRealInterestsRepository._();

  EnhancedRealInterestsRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<Interest>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Configurações de retry
  final int _maxRetries = 3;
  final Duration _baseDelay = const Duration(seconds: 1);

  /// Busca interesses com retry automático e validação
  Future<List<Interest>> getInterestsWithRetry(String userId) async {
    EnhancedLogger.info(
        '🔍 [ENHANCED_REPOSITORY] Buscando interesses com retry',
        tag: 'ENHANCED_REAL_INTERESTS_REPOSITORY',
        data: {'userId': userId});

    // Verifica cache primeiro
    if (_isCacheValid(userId)) {
      EnhancedLogger.info('📱 [ENHANCED_REPOSITORY] Usando dados do cache',
          data: {'userId': userId, 'cacheSize': _cache[userId]?.length ?? 0});
      return _cache[userId] ?? [];
    }

    // Busca com retry
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        EnhancedLogger.info(
            '🔄 [ENHANCED_REPOSITORY] Tentativa $attempt de $_maxRetries',
            data: {'userId': userId, 'attempt': attempt});

        final interests = await _fetchInterestsFromFirebase(userId);
        final validInterests = _validateAndFilterInterests(interests);

        // Atualiza cache
        _updateCache(userId, validInterests);

        EnhancedLogger.success(
            '✅ [ENHANCED_REPOSITORY] Interesses obtidos com sucesso',
            data: {
              'userId': userId,
              'totalInterests': interests.length,
              'validInterests': validInterests.length,
              'attempt': attempt
            });

        return validInterests;
      } catch (e) {
        EnhancedLogger.error(
            '❌ [ENHANCED_REPOSITORY] Erro na tentativa $attempt',
            error: e,
            data: {'userId': userId, 'attempt': attempt});

        if (attempt == _maxRetries) {
          // Última tentativa falhou, tenta usar cache expirado
          final cachedData = _cache[userId];
          if (cachedData != null) {
            EnhancedLogger.warning(
                '⚠️ [ENHANCED_REPOSITORY] Usando cache expirado como fallback',
                data: {'userId': userId, 'cacheSize': cachedData.length});
            return cachedData;
          }

          // Se não há cache, retorna lista vazia
          EnhancedLogger.error(
              '💥 [ENHANCED_REPOSITORY] Todas as tentativas falharam',
              error: e,
              data: {'userId': userId});
          return [];
        }

        // Aguarda antes da próxima tentativa
        await _waitForRetry(attempt);
      }
    }

    return [];
  }

  /// Busca interesses diretamente do Firebase
  Future<List<Interest>> _fetchInterestsFromFirebase(String userId) async {
    final List<Interest> allInterests = [];

    try {
      // Busca em múltiplas coleções
      final collections = [
        'interests',
        'likes',
        'matches',
        'user_interactions'
      ];

      for (final collection in collections) {
        try {
          final interests = await _fetchFromCollection(collection, userId);
          allInterests.addAll(interests);

          EnhancedLogger.info(
              '📊 [ENHANCED_REPOSITORY] Coleção $collection processada',
              data: {
                'collection': collection,
                'userId': userId,
                'interestsFound': interests.length
              });
        } catch (e) {
          EnhancedLogger.error(
              '❌ [ENHANCED_REPOSITORY] Erro na coleção $collection',
              error: e,
              data: {'collection': collection, 'userId': userId});
          // Continua com outras coleções mesmo se uma falhar
        }
      }

      return allInterests;
    } catch (e) {
      EnhancedLogger.error(
          '❌ [ENHANCED_REPOSITORY] Erro geral na busca Firebase',
          error: e,
          data: {'userId': userId});
      rethrow;
    }
  }

  /// Busca interesses de uma coleção específica
  Future<List<Interest>> _fetchFromCollection(
      String collection, String userId) async {
    try {
      final query = _firestore
          .collection(collection)
          .where('toUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50); // Limita para evitar sobrecarga

      final snapshot = await query.get();
      final interests = <Interest>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (validateInteractionData(data)) {
            final interest = Interest.fromFirestore(doc);
            interests.add(interest);
          } else {
            EnhancedLogger.warning(
                '⚠️ [ENHANCED_REPOSITORY] Dados inválidos ignorados',
                data: {
                  'collection': collection,
                  'docId': doc.id,
                  'userId': userId
                });
          }
        } catch (e) {
          EnhancedLogger.error(
              '❌ [ENHANCED_REPOSITORY] Erro ao processar documento',
              error: e,
              data: {
                'collection': collection,
                'docId': doc.id,
                'userId': userId
              });
          // Continua processando outros documentos
        }
      }

      return interests;
    } catch (e) {
      EnhancedLogger.error('❌ [ENHANCED_REPOSITORY] Erro na query da coleção',
          error: e, data: {'collection': collection, 'userId': userId});
      rethrow;
    }
  }

  /// Valida dados de interação antes do processamento
  bool validateInteractionData(Map<String, dynamic> data) {
    try {
      // Validações essenciais
      if (data['toUserId'] == null || data['toUserId'].toString().isEmpty) {
        return false;
      }

      if (data['fromUserId'] == null || data['fromUserId'].toString().isEmpty) {
        return false;
      }

      if (data['timestamp'] == null) {
        return false;
      }

      // Validação de timestamp
      if (data['timestamp'] is! Timestamp) {
        return false;
      }

      // Validação de IDs (não podem ser iguais)
      if (data['toUserId'] == data['fromUserId']) {
        return false;
      }

      // Validação de data (não pode ser muito antiga)
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      if (timestamp.isBefore(thirtyDaysAgo)) {
        return false;
      }

      return true;
    } catch (e) {
      EnhancedLogger.error('❌ [ENHANCED_REPOSITORY] Erro na validação de dados',
          error: e, data: data);
      return false;
    }
  }

  /// Valida e filtra lista de interesses
  List<Interest> _validateAndFilterInterests(List<Interest> interests) {
    final validInterests = <Interest>[];
    final seenInteractions = <String>{};

    for (final interest in interests) {
      try {
        // Cria chave única para detectar duplicatas
        final key =
            '${interest.from}_${interest.to}_${interest.timestamp.millisecondsSinceEpoch}';

        if (seenInteractions.contains(key)) {
          EnhancedLogger.info(
              '🔄 [ENHANCED_REPOSITORY] Interação duplicada ignorada',
              data: {
                'fromUserId': interest.from,
                'toUserId': interest.to,
                'key': key
              });
          continue;
        }

        // Validações específicas do interesse
        if (_validateInterest(interest)) {
          validInterests.add(interest);
          seenInteractions.add(key);
        }
      } catch (e) {
        EnhancedLogger.error(
            '❌ [ENHANCED_REPOSITORY] Erro ao validar interesse',
            error: e,
            data: {'interestId': interest.id, 'fromUserId': interest.from});
      }
    }

    EnhancedLogger.info('✅ [ENHANCED_REPOSITORY] Validação concluída', data: {
      'totalInterests': interests.length,
      'validInterests': validInterests.length,
      'duplicatesRemoved': interests.length - validInterests.length
    });

    return validInterests;
  }

  /// Valida um interesse específico
  bool _validateInterest(Interest interest) {
    try {
      // Validações básicas
      if (interest.id.isEmpty) return false;
      if (interest.from.isEmpty) return false;
      if (interest.to.isEmpty) return false;

      // Validação de timestamp
      final now = DateTime.now();
      if (interest.timestamp.isAfter(now)) return false;

      // Validação de idade da interação (máximo 30 dias)
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      if (interest.timestamp.isBefore(thirtyDaysAgo)) return false;

      return true;
    } catch (e) {
      EnhancedLogger.error(
          '❌ [ENHANCED_REPOSITORY] Erro na validação específica',
          error: e,
          data: {'interestId': interest.id});
      return false;
    }
  }

  /// Atualiza cache com novos dados
  void _updateCache(String userId, List<Interest> interests) {
    _cache[userId] = interests;
    _cacheTimestamps[userId] = DateTime.now();

    EnhancedLogger.info('💾 [ENHANCED_REPOSITORY] Cache atualizado', data: {
      'userId': userId,
      'interestsCount': interests.length,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  /// Verifica se o cache é válido
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _cacheTTL && _cache[userId] != null;
  }

  /// Aguarda antes de tentar novamente
  Future<void> _waitForRetry(int attempt) async {
    final delay = Duration(
        milliseconds: _baseDelay.inMilliseconds * (1 << (attempt - 1)));

    EnhancedLogger.info(
        '⏳ [ENHANCED_REPOSITORY] Aguardando antes da próxima tentativa',
        data: {'attempt': attempt, 'delayMs': delay.inMilliseconds});

    await Future.delayed(delay);
  }

  /// Stream com recovery automático para dados em tempo real
  Stream<List<Interest>> getInterestsStreamWithRecovery(String userId) {
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        EnhancedLogger.info('📡 [ENHANCED_REPOSITORY] Buscando interesses',
            data: {'userId': userId});

        // Busca de múltiplas coleções
        final futures = ['interests', 'likes', 'matches', 'user_interactions']
            .map((collection) => _firestore
                .collection(collection)
                .where('to', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .limit(20)
                .get())
            .toList();

        final snapshots = await Future.wait(futures);
        final allInterests = <Interest>[];

        for (final snapshot in snapshots) {
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (validateInteractionData(data)) {
                final interest = Interest.fromFirestore(doc);
                allInterests.add(interest);
              }
            } catch (e) {
              EnhancedLogger.error(
                  '❌ [ENHANCED_REPOSITORY] Erro ao processar doc',
                  error: e,
                  data: {'docId': doc.id});
            }
          }
        }

        final validInterests = _validateAndFilterInterests(allInterests);
        _updateCache(userId, validInterests);

        EnhancedLogger.info('📊 [ENHANCED_REPOSITORY] Stream atualizado',
            data: {
              'userId': userId,
              'totalInterests': allInterests.length,
              'validInterests': validInterests.length
            });

        return validInterests;
      } catch (e) {
        EnhancedLogger.error('❌ [ENHANCED_REPOSITORY] Erro no stream',
            error: e, data: {'userId': userId});

        // Retorna dados do cache como fallback
        final cachedData = _cache[userId];
        return cachedData ?? <Interest>[];
      }
    });
  }

  /// Limpa cache expirado
  void clearExpiredCache() {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in _cacheTimestamps.entries) {
        final age = now.difference(entry.value);
        if (age > _cacheTTL) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }

      EnhancedLogger.info('🧹 [ENHANCED_REPOSITORY] Cache limpo',
          data: {'expiredKeys': expiredKeys.length});
    } catch (e) {
      EnhancedLogger.error('❌ [ENHANCED_REPOSITORY] Erro ao limpar cache',
          error: e);
    }
  }

  /// Obtém estatísticas do repositório
  Map<String, dynamic> getStatistics() {
    return {
      'cacheSize': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'cacheTTL': _cacheTTL.inMinutes,
      'maxRetries': _maxRetries,
      'baseDelay': _baseDelay.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
