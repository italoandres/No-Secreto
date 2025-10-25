import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interest_model.dart';
import '../utils/enhanced_logger.dart';

class RealInterestsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca todos os interesses onde o usuário é o destinatário
  Future<List<Interest>> getInterestsForUser(String userId) async {
    try {
      EnhancedLogger.info('Buscando interesses para usuário: $userId');

      final query = _firestore
          .collection('interests')
          .where('to', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50);

      final querySnapshot = await query.get();

      final interests = querySnapshot.docs
          .map((doc) => Interest.fromFirestore(doc))
          .where((interest) => interest.isValid())
          .toList();

      EnhancedLogger.success(
          'Encontrados ${interests.length} interesses válidos');

      return interests;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao buscar interesses',
          error: e, stackTrace: stackTrace);

      // Fallback: tentar busca simples sem orderBy
      return await _getInterestsSimpleFallback(userId);
    }
  }

  /// Stream de interesses em tempo real
  Stream<List<Interest>> streamInterestsForUser(String userId) {
    try {
      EnhancedLogger.info(
          'Iniciando stream de interesses para usuário: $userId');

      return _firestore
          .collection('interests')
          .where('to', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final interests = snapshot.docs
            .map((doc) => Interest.fromFirestore(doc))
            .where((interest) => interest.isValid())
            .toList();

        EnhancedLogger.info(
            'Stream atualizado: ${interests.length} interesses');
        return interests;
      });
    } catch (e) {
      EnhancedLogger.error('Erro no stream de interesses', error: e);

      // Fallback: stream simples sem orderBy
      return _streamInterestsSimpleFallback(userId);
    }
  }

  /// Busca interesse específico por ID
  Future<Interest?> getInterestById(String interestId) async {
    try {
      EnhancedLogger.info('Buscando interesse por ID: $interestId');

      final doc =
          await _firestore.collection('interests').doc(interestId).get();

      if (doc.exists) {
        final interest = Interest.fromFirestore(doc);
        EnhancedLogger.success('Interesse encontrado: ${interest.toString()}');
        return interest;
      } else {
        EnhancedLogger.warning('Interesse não encontrado: $interestId');
        return null;
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao buscar interesse por ID',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Busca interesses recentes (últimas 24h)
  Future<List<Interest>> getRecentInterestsForUser(String userId) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      EnhancedLogger.info('Buscando interesses recentes para usuário: $userId');

      final query = _firestore
          .collection('interests')
          .where('to', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('timestamp', descending: true);

      final querySnapshot = await query.get();

      final interests = querySnapshot.docs
          .map((doc) => Interest.fromFirestore(doc))
          .where((interest) => interest.isValid())
          .toList();

      EnhancedLogger.success(
          'Encontrados ${interests.length} interesses recentes');

      return interests;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao buscar interesses recentes',
          error: e, stackTrace: stackTrace);

      // Fallback para busca geral
      return await getInterestsForUser(userId);
    }
  }

  /// Verifica se existe interesse entre dois usuários
  Future<bool> hasInterestBetween(String fromUserId, String toUserId) async {
    try {
      final query = _firestore
          .collection('interests')
          .where('from', isEqualTo: fromUserId)
          .where('to', isEqualTo: toUserId)
          .limit(1);

      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar interesse entre usuários',
          error: e);
      return false;
    }
  }

  /// Fallback: busca simples sem orderBy (para casos onde o índice não existe)
  Future<List<Interest>> _getInterestsSimpleFallback(String userId) async {
    try {
      EnhancedLogger.warning('Usando fallback para busca de interesses');

      final query = _firestore
          .collection('interests')
          .where('to', isEqualTo: userId)
          .limit(50);

      final querySnapshot = await query.get();

      final interests = querySnapshot.docs
          .map((doc) => Interest.fromFirestore(doc))
          .where((interest) => interest.isValid())
          .toList();

      // Ordenar manualmente por timestamp
      interests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      EnhancedLogger.info(
          'Fallback: encontrados ${interests.length} interesses');

      return interests;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro no fallback de busca',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Fallback: stream simples sem orderBy
  Stream<List<Interest>> _streamInterestsSimpleFallback(String userId) {
    EnhancedLogger.warning('Usando fallback para stream de interesses');

    return _firestore
        .collection('interests')
        .where('to', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final interests = snapshot.docs
          .map((doc) => Interest.fromFirestore(doc))
          .where((interest) => interest.isValid())
          .toList();

      // Ordenar manualmente por timestamp
      interests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      EnhancedLogger.info('Fallback stream: ${interests.length} interesses');
      return interests;
    });
  }

  /// Debug: busca todos os interesses para análise
  Future<List<Interest>> getAllInterestsForDebug() async {
    try {
      EnhancedLogger.info('Buscando TODOS os interesses para debug');

      final querySnapshot =
          await _firestore.collection('interests').limit(100).get();

      final interests =
          querySnapshot.docs.map((doc) => Interest.fromFirestore(doc)).toList();

      EnhancedLogger.info(
          'Debug: encontrados ${interests.length} interesses totais');

      for (final interest in interests) {
        EnhancedLogger.debug('Interest: ${interest.toString()}');
      }

      return interests;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro no debug de interesses',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
