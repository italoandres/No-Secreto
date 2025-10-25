import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weekly_recommendation.dart';
import '../models/scored_profile.dart';
import '../models/interest.dart';
import '../models/match.dart';
import '../models/search_filters_model.dart';
import '../utils/enhanced_logger.dart';
import 'score_calculator.dart';

/// Serviço para gerenciar recomendações semanais de perfis
class WeeklyRecommendationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtém recomendações da semana atual para o usuário
  static Future<List<ScoredProfile>> getWeeklyRecommendations(
    String userId,
  ) async {
    try {
      EnhancedLogger.info(
        'Loading weekly recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'userId': userId},
      );

      final weekKey = _getCurrentWeekKey();
      final cached = await _getCachedRecommendations(userId, weekKey);

      if (cached != null && cached.profileIds.isNotEmpty) {
        EnhancedLogger.success(
          'Using cached recommendations',
          tag: 'WEEKLY_RECOMMENDATIONS',
          data: {'weekKey': weekKey, 'count': cached.profileIds.length},
        );
        return await _loadScoredProfiles(cached.profileIds);
      }

      // Gerar novas recomendações
      EnhancedLogger.info(
        'Generating new recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'weekKey': weekKey},
      );

      final recommendations = await _generateRecommendations(userId);
      await _cacheRecommendations(userId, weekKey, recommendations);

      EnhancedLogger.success(
        'Weekly recommendations generated',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'count': recommendations.length},
      );

      return recommendations;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get weekly recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return [];
    }
  }

  /// Gera novas recomendações baseadas no matching
  static Future<List<ScoredProfile>> _generateRecommendations(
    String userId,
  ) async {
    try {
      // 1. Buscar perfil e filtros do usuário
      final userProfile = await _getUserProfile(userId);
      final userFilters = await _getUserFilters(userId);

      if (userProfile == null) {
        EnhancedLogger.warning(
          'User profile not found',
          tag: 'WEEKLY_RECOMMENDATIONS',
          data: {'userId': userId},
        );
        return [];
      }

      // 2. Buscar perfis candidatos
      final candidates = await _getCandidateProfiles(userId);

      EnhancedLogger.info(
        'Candidates found',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'count': candidates.length},
      );

      if (candidates.isEmpty) {
        return [];
      }

      // 3. Calcular scores
      final scored = <ScoredProfile>[];
      for (final candidate in candidates) {
        try {
          final score = ScoreCalculator().calculateScore(
            profileData: candidate,
            filters: userFilters,
            distance: _calculateDistance(userProfile, candidate),
          );

          scored.add(ScoredProfile(
            userId: candidate['userId'] as String,
            profileData: candidate,
            score: score,
            distance: _calculateDistance(userProfile, candidate),
          ));
        } catch (e) {
          EnhancedLogger.warning(
            'Failed to score profile: $e',
            tag: 'WEEKLY_RECOMMENDATIONS',
          );
        }
      }

      // 4. Ordenar por score e selecionar top 14 (2 por dia)
      scored.sort((a, b) => b.score.totalScore.compareTo(a.score.totalScore));
      final top14 = scored.take(14).toList();

      EnhancedLogger.info(
        'Recommendations scored and sorted',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {
          'total': scored.length,
          'selected': top14.length,
          'topScore': top14.isNotEmpty ? top14.first.score.totalScore : 0,
        },
      );

      return top14;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to generate recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return [];
    }
  }

  /// Busca perfis candidatos (excluindo já visualizados, bloqueados, matches)
  static Future<List<Map<String, dynamic>>> _getCandidateProfiles(
    String userId,
  ) async {
    try {
      // Buscar perfis excluídos (já visualizados, bloqueados, matches)
      final excludedIds = await _getExcludedProfileIds(userId);

      // Buscar perfis completos e ativos
      final query = await _firestore
          .collection('profiles')
          .where('isComplete', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(50) // Buscar mais para ter opções após filtrar
          .get();

      final candidates = <Map<String, dynamic>>[];
      for (final doc in query.docs) {
        final data = doc.data();
        final profileUserId = data['userId'] as String?;

        // Excluir próprio perfil e perfis já excluídos
        if (profileUserId != null &&
            profileUserId != userId &&
            !excludedIds.contains(profileUserId)) {
          data['userId'] = profileUserId;
          candidates.add(data);
        }
      }

      return candidates;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get candidate profiles',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return [];
    }
  }

  /// Obtém IDs de perfis que devem ser excluídos
  static Future<Set<String>> _getExcludedProfileIds(String userId) async {
    final excluded = <String>{};

    try {
      // 1. Perfis já visualizados nas últimas 4 semanas
      final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
      final recentRecommendations = await _firestore
          .collection('weeklyRecommendations')
          .where('userId', isEqualTo: userId)
          .where('generatedAt', isGreaterThan: Timestamp.fromDate(fourWeeksAgo))
          .get();

      for (final doc in recentRecommendations.docs) {
        final data = doc.data();
        final viewedProfiles = List<String>.from(data['viewedProfiles'] ?? []);
        excluded.addAll(viewedProfiles);
      }

      // 2. Perfis com matches existentes
      final matches = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      for (final doc in matches.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        for (final user in users) {
          if (user != userId) {
            excluded.add(user);
          }
        }
      }

      // 3. Perfis bloqueados
      final blocks = await _firestore
          .collection('blocks')
          .where('blockedBy', isEqualTo: userId)
          .get();

      for (final doc in blocks.docs) {
        final data = doc.data();
        final blockedUserId = data['blockedUserId'] as String?;
        if (blockedUserId != null) {
          excluded.add(blockedUserId);
        }
      }

      EnhancedLogger.info(
        'Excluded profiles loaded',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'count': excluded.length},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get excluded profiles',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }

    return excluded;
  }

  /// Busca perfil do usuário
  static Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          data['userId'] = userId;
          return data;
        }
      }
      return null;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get user profile',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return null;
    }
  }

  /// Busca filtros do usuário
  static Future<SearchFilters> _getUserFilters(String userId) async {
    try {
      final doc =
          await _firestore.collection('searchFilters').doc(userId).get();
      if (doc.exists) {
        return SearchFilters.fromFirestore(doc);
      }
      // Retornar filtros padrão se não existir
      return SearchFilters.defaultFilters();
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get user filters',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return SearchFilters.defaultFilters();
    }
  }

  /// Calcula distância entre dois perfis (simplificado)
  static double _calculateDistance(
    Map<String, dynamic> profile1,
    Map<String, dynamic> profile2,
  ) {
    // TODO: Implementar cálculo real de distância usando lat/lng
    // Por enquanto, retornar distância padrão
    return 10.0;
  }

  /// Carrega perfis pontuados a partir de IDs
  static Future<List<ScoredProfile>> _loadScoredProfiles(
    List<String> profileIds,
  ) async {
    final profiles = <ScoredProfile>[];

    for (final profileId in profileIds) {
      try {
        final doc =
            await _firestore.collection('profiles').doc(profileId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            data['userId'] = profileId;
            // Criar score básico (será recalculado se necessário)
            final score = ScoreCalculator().calculateScore(
              profileData: data,
              filters: SearchFilters.defaultFilters(),
              distance: 10.0,
            );

            profiles.add(ScoredProfile(
              userId: profileId,
              profileData: data,
              score: score,
              distance: 10.0,
            ));
          }
        }
      } catch (e) {
        EnhancedLogger.warning(
          'Failed to load profile: $e',
          tag: 'WEEKLY_RECOMMENDATIONS',
          data: {'profileId': profileId},
        );
      }
    }

    return profiles;
  }

  /// Obtém recomendações em cache
  static Future<WeeklyRecommendation?> _getCachedRecommendations(
    String userId,
    String weekKey,
  ) async {
    try {
      final doc = await _firestore
          .collection('weeklyRecommendations')
          .doc('${userId}_$weekKey')
          .get();

      if (doc.exists) {
        return WeeklyRecommendation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get cached recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return null;
    }
  }

  /// Salva recomendações em cache
  static Future<void> _cacheRecommendations(
    String userId,
    String weekKey,
    List<ScoredProfile> recommendations,
  ) async {
    try {
      final profileIds = recommendations.map((p) => p.userId).toList();

      final weeklyRec = WeeklyRecommendation(
        userId: userId,
        weekKey: weekKey,
        profileIds: profileIds,
        generatedAt: DateTime.now(),
      );

      await _firestore
          .collection('weeklyRecommendations')
          .doc('${userId}_$weekKey')
          .set(weeklyRec.toFirestore());

      EnhancedLogger.success(
        'Recommendations cached',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'weekKey': weekKey, 'count': profileIds.length},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to cache recommendations',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Obtém chave da semana atual (formato: "2025-W42")
  static String _getCurrentWeekKey() {
    final now = DateTime.now();
    final monday = _getLastMonday(now);
    final weekNumber = _getWeekNumber(monday);
    return '${monday.year}-W$weekNumber';
  }

  /// Obtém a segunda-feira mais recente
  static DateTime _getLastMonday(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Calcula número da semana no ano
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Verifica se precisa renovar recomendações
  static bool needsRefresh(DateTime lastRefresh) {
    final now = DateTime.now();
    final lastMonday = _getLastMonday(lastRefresh);
    final currentMonday = _getLastMonday(now);

    return currentMonday.isAfter(lastMonday);
  }

  // ==================== SISTEMA DE INTERESSES ====================

  /// Registra interesse em um perfil
  static Future<bool> registerInterest(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      EnhancedLogger.info(
        'Registering interest',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'from': fromUserId, 'to': toUserId},
      );

      // Criar documento de interesse
      await _firestore.collection('interests').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Verificar interesse mútuo
      final hasMutualInterest =
          await _checkMutualInterest(fromUserId, toUserId);

      if (hasMutualInterest) {
        EnhancedLogger.success(
          'Mutual interest detected!',
          tag: 'WEEKLY_RECOMMENDATIONS',
          data: {'user1': fromUserId, 'user2': toUserId},
        );
        await _createMatch(fromUserId, toUserId);
        return true; // Retorna true se criou match
      }

      EnhancedLogger.success(
        'Interest registered',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'from': fromUserId, 'to': toUserId},
      );

      return false; // Retorna false se apenas registrou interesse
    } catch (e) {
      EnhancedLogger.error(
        'Failed to register interest',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return false;
    }
  }

  /// Verifica se há interesse mútuo entre dois usuários
  static Future<bool> _checkMutualInterest(
    String user1Id,
    String user2Id,
  ) async {
    try {
      // Verificar se user2 já demonstrou interesse em user1
      final query = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: user2Id)
          .where('toUserId', isEqualTo: user1Id)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      EnhancedLogger.error(
        'Failed to check mutual interest',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return false;
    }
  }

  /// Cria match quando há interesse mútuo
  static Future<void> _createMatch(String user1Id, String user2Id) async {
    try {
      final matchId = _generateMatchId(user1Id, user2Id);

      // Criar documento de match
      await _firestore.collection('matches').doc(matchId).set({
        'users': [user1Id, user2Id],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'viewedByUser1': false,
        'viewedByUser2': false,
      });

      // Atualizar status dos interesses para 'matched'
      await _updateInterestStatus(user1Id, user2Id, 'matched');

      // Enviar notificações
      await _sendMatchNotifications(user1Id, user2Id);

      EnhancedLogger.success(
        'Match created successfully',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {
          'matchId': matchId,
          'users': [user1Id, user2Id]
        },
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to create match',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Gera ID único para o match (ordenado alfabeticamente)
  static String _generateMatchId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Atualiza status dos interesses para 'matched'
  static Future<void> _updateInterestStatus(
    String user1Id,
    String user2Id,
    String newStatus,
  ) async {
    try {
      // Atualizar interesse de user1 para user2
      final query1 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: user1Id)
          .where('toUserId', isEqualTo: user2Id)
          .get();

      for (final doc in query1.docs) {
        await doc.reference.update({'status': newStatus});
      }

      // Atualizar interesse de user2 para user1
      final query2 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: user2Id)
          .where('toUserId', isEqualTo: user1Id)
          .get();

      for (final doc in query2.docs) {
        await doc.reference.update({'status': newStatus});
      }

      EnhancedLogger.info(
        'Interest status updated',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'newStatus': newStatus},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to update interest status',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Envia notificações de match para ambos usuários
  static Future<void> _sendMatchNotifications(
    String user1Id,
    String user2Id,
  ) async {
    try {
      // TODO: Integrar com sistema de notificações existente
      // Por enquanto, apenas registrar no log
      EnhancedLogger.info(
        'Match notifications sent',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {
          'users': [user1Id, user2Id]
        },
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to send match notifications',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Obtém lista de interesses pendentes do usuário
  static Future<List<Interest>> getPendingInterests(String userId) async {
    try {
      final query = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) => Interest.fromFirestore(doc)).toList();
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get pending interests',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return [];
    }
  }

  /// Obtém lista de matches do usuário
  static Future<List<Match>> getUserMatches(String userId) async {
    try {
      final query = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Match.fromFirestore(doc)).toList();
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get user matches',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return [];
    }
  }

  /// Marca perfil como visualizado
  static Future<void> markProfileAsViewed(
    String userId,
    String profileId,
  ) async {
    try {
      final weekKey = _getCurrentWeekKey();
      final docId = '${userId}_$weekKey';

      await _firestore.collection('weeklyRecommendations').doc(docId).update({
        'viewedProfiles': FieldValue.arrayUnion([profileId]),
      });

      EnhancedLogger.info(
        'Profile marked as viewed',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'profileId': profileId},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to mark profile as viewed',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Marca perfil como passado (não interessou)
  static Future<void> markProfileAsPassed(
    String userId,
    String profileId,
  ) async {
    try {
      final weekKey = _getCurrentWeekKey();
      final docId = '${userId}_$weekKey';

      await _firestore.collection('weeklyRecommendations').doc(docId).update({
        'passedProfiles': FieldValue.arrayUnion([profileId]),
        'viewedProfiles': FieldValue.arrayUnion([profileId]),
      });

      EnhancedLogger.info(
        'Profile marked as passed',
        tag: 'WEEKLY_RECOMMENDATIONS',
        data: {'profileId': profileId},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to mark profile as passed',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
    }
  }

  /// Busca perfil completo com score de um usuário específico
  static Future<ScoredProfile?> getProfileWithScore(
    String userId,
    String targetUserId,
  ) async {
    try {
      // Buscar perfil do usuário
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) return null;

      // Buscar perfil do target
      final targetProfile = await _getUserProfile(targetUserId);
      if (targetProfile == null) return null;

      // Buscar filtros do usuário
      final userFilters = await _getUserFilters(userId);

      // Calcular distância
      final distance = _calculateDistance(userProfile, targetProfile);

      // Calcular score usando o ScoreCalculator
      final calculator = ScoreCalculator();
      final score = calculator.calculateScore(
        profileData: targetProfile,
        filters: userFilters,
        distance: distance,
      );

      return ScoredProfile(
        userId: targetUserId,
        profileData: targetProfile,
        score: score,
        distance: distance,
      );
    } catch (e) {
      EnhancedLogger.error(
        'Failed to get profile with score',
        tag: 'WEEKLY_RECOMMENDATIONS',
        error: e,
      );
      return null;
    }
  }

  /// Busca perfis completos com scores para uma lista de interesses
  static Future<Map<String, ScoredProfile>> getProfilesForInterests(
    String userId,
    List<Interest> interests,
  ) async {
    final profiles = <String, ScoredProfile>{};

    for (final interest in interests) {
      final profile = await getProfileWithScore(userId, interest.fromUserId);
      if (profile != null) {
        profiles[interest.fromUserId] = profile;
      }
    }

    return profiles;
  }

  /// Busca perfis completos com scores para uma lista de matches
  static Future<Map<String, ScoredProfile>> getProfilesForMatches(
    String userId,
    List<Match> matches,
  ) async {
    final profiles = <String, ScoredProfile>{};

    for (final match in matches) {
      final otherUserId = match.getOtherUserId(userId);
      if (otherUserId.isEmpty) continue;

      final profile = await getProfileWithScore(userId, otherUserId);
      if (profile != null) {
        profiles[otherUserId] = profile;
      }
    }

    return profiles;
  }
}
