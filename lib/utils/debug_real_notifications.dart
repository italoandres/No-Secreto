import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/real_interest_notification_service.dart';
import '../repositories/real_interests_repository.dart';
import '../services/real_user_data_cache.dart';
import '../utils/enhanced_logger.dart';

class DebugRealNotifications {
  static final RealInterestNotificationService _service =
      RealInterestNotificationService();
  static final RealInterestsRepository _repository = RealInterestsRepository();
  static final RealUserDataCache _cache = RealUserDataCache();

  /// Executa debug completo do sistema
  static Future<void> runCompleteDebug(String userId) async {
    EnhancedLogger.info('🔍 INICIANDO DEBUG COMPLETO PARA: $userId');
    EnhancedLogger.info('=' * 50);

    try {
      // 1. Testa conexão com Firebase
      await _testFirebaseConnection();

      // 2. Debug da coleção interests
      await _debugInterestsCollection(userId);

      // 3. Debug do cache de usuários
      await _debugUserCache(userId);

      // 4. Debug do serviço completo
      await _debugCompleteService(userId);

      // 5. Testa busca em tempo real
      await _testRealTimeStream(userId);

      EnhancedLogger.success('✅ DEBUG COMPLETO FINALIZADO');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ ERRO NO DEBUG COMPLETO',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Testa conexão com Firebase
  static Future<void> _testFirebaseConnection() async {
    EnhancedLogger.info('🔥 Testando conexão com Firebase...');

    try {
      final firestore = FirebaseFirestore.instance;

      // Testa acesso básico
      final testDoc = await firestore.collection('test').limit(1).get();
      EnhancedLogger.success('✅ Conexão com Firebase OK');

      // Lista coleções disponíveis
      EnhancedLogger.info('📋 Testando coleções principais...');

      final collections = ['interests', 'usuarios', 'likes', 'matches'];
      for (final collection in collections) {
        try {
          final snapshot =
              await firestore.collection(collection).limit(1).get();
          EnhancedLogger.info(
              '   ✅ $collection: ${snapshot.docs.length} docs (sample)');
        } catch (e) {
          EnhancedLogger.warning('   ❌ $collection: erro - $e');
        }
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro na conexão Firebase',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Debug específico da coleção interests
  static Future<void> _debugInterestsCollection(String userId) async {
    EnhancedLogger.info('💕 Debug da coleção INTERESTS...');

    try {
      // 1. Busca todos os interesses para debug
      final allInterests = await _repository.getAllInterestsForDebug();
      EnhancedLogger.info(
          '📊 Total de interesses na coleção: ${allInterests.length}');

      // 2. Filtra interesses para o usuário específico
      final userInterests = allInterests.where((i) => i.to == userId).toList();
      EnhancedLogger.info(
          '🎯 Interesses para $userId: ${userInterests.length}');

      // 3. Mostra detalhes dos interesses do usuário
      if (userInterests.isNotEmpty) {
        EnhancedLogger.info('📋 DETALHES DOS INTERESSES:');
        for (final interest in userInterests) {
          EnhancedLogger.info('   📧 ID: ${interest.id}');
          EnhancedLogger.info('      From: ${interest.from}');
          EnhancedLogger.info('      To: ${interest.to}');
          EnhancedLogger.info('      Timestamp: ${interest.timestamp}');
          EnhancedLogger.info('      Valid: ${interest.isValid()}');
        }
      } else {
        EnhancedLogger.warning('❌ Nenhum interesse encontrado para o usuário');

        // Mostra alguns exemplos da coleção
        EnhancedLogger.info('📋 EXEMPLOS DA COLEÇÃO (primeiros 5):');
        for (final interest in allInterests.take(5)) {
          EnhancedLogger.info(
              '   📧 ${interest.from} → ${interest.to} (${interest.timestamp})');
        }
      }

      // 4. Testa query específica
      EnhancedLogger.info('🔍 Testando query específica...');
      final queryResult = await _repository.getInterestsForUser(userId);
      EnhancedLogger.info('📊 Query result: ${queryResult.length} interesses');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro no debug da coleção interests',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Debug do cache de usuários
  static Future<void> _debugUserCache(String userId) async {
    EnhancedLogger.info('👥 Debug do cache de usuários...');

    try {
      // 1. Limpa cache para teste limpo
      _cache.clearCache();
      EnhancedLogger.info('🧹 Cache limpo');

      // 2. Busca dados do usuário atual
      final currentUser = await _cache.getUserData(userId);
      EnhancedLogger.info('👤 Usuário atual: ${currentUser.getDisplayName()}');

      // 3. Testa busca de usuários que demonstraram interesse
      final interests = await _repository.getInterestsForUser(userId);
      if (interests.isNotEmpty) {
        final userIds = interests.map((i) => i.from).toSet().toList();
        EnhancedLogger.info(
            '🔍 Buscando dados de ${userIds.length} usuários...');

        final usersData = await _cache.preloadUsers(userIds);
        EnhancedLogger.info(
            '✅ Dados carregados para ${usersData.length} usuários');

        for (final entry in usersData.entries) {
          EnhancedLogger.info(
              '   👤 ${entry.key}: ${entry.value.getDisplayName()}');
        }
      }

      // 4. Mostra estatísticas do cache
      final stats = _cache.getCacheStats();
      EnhancedLogger.info('📊 Estatísticas do cache: $stats');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro no debug do cache',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Debug do serviço completo
  static Future<void> _debugCompleteService(String userId) async {
    EnhancedLogger.info('🔧 Debug do serviço completo...');

    try {
      // 1. Executa debug interno do serviço
      await _service.debugFullSearch(userId);

      // 2. Testa busca de notificações
      EnhancedLogger.info('🔍 Testando busca de notificações...');
      final notifications = await _service.getRealInterestNotifications(userId);
      EnhancedLogger.info(
          '📧 Notificações encontradas: ${notifications.length}');

      for (final notification in notifications) {
        EnhancedLogger.info(
            '   📧 ${notification.fromUserName}: ${notification.message}');
      }

      // 3. Testa notificações recentes
      EnhancedLogger.info('⏰ Testando notificações recentes...');
      final recent = await _service.getRecentNotifications(userId);
      EnhancedLogger.info('📧 Notificações recentes: ${recent.length}');

      // 4. Mostra estatísticas do serviço
      final serviceStats = _service.getServiceStats();
      EnhancedLogger.info('📊 Estatísticas do serviço: $serviceStats');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro no debug do serviço',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Testa stream em tempo real
  static Future<void> _testRealTimeStream(String userId) async {
    EnhancedLogger.info('📡 Testando stream em tempo real...');

    try {
      final stream = _service.subscribeToRealTimeUpdates(userId);

      // Escuta por 5 segundos
      final subscription = stream.listen(
        (notifications) {
          EnhancedLogger.info(
              '📡 Stream update: ${notifications.length} notificações');
          for (final notification in notifications) {
            EnhancedLogger.info(
                '   📧 ${notification.fromUserName}: ${notification.message}');
          }
        },
        onError: (error) {
          EnhancedLogger.error('❌ Erro no stream', error: error);
        },
      );

      // Aguarda 5 segundos
      await Future.delayed(const Duration(seconds: 5));

      // Para o stream
      await subscription.cancel();
      _service.stopRealTimeUpdates();

      EnhancedLogger.info('✅ Teste de stream concluído');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro no teste de stream',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Cria dados de teste para interests
  static Future<void> createTestInterest(
      String fromUserId, String toUserId) async {
    EnhancedLogger.info(
        '🧪 Criando interesse de teste: $fromUserId → $toUserId');

    try {
      final firestore = FirebaseFirestore.instance;

      final interestData = {
        'from': fromUserId,
        'to': toUserId,
        'timestamp': Timestamp.now(),
        'message': 'Interesse de teste',
      };

      final docRef = await firestore.collection('interests').add(interestData);
      EnhancedLogger.success('✅ Interesse de teste criado: ${docRef.id}');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro ao criar interesse de teste',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Limpa dados de teste
  static Future<void> cleanupTestData() async {
    EnhancedLogger.info('🧹 Limpando dados de teste...');

    try {
      final firestore = FirebaseFirestore.instance;

      // Busca interesses de teste
      final testInterests = await firestore
          .collection('interests')
          .where('message', isEqualTo: 'Interesse de teste')
          .get();

      // Remove interesses de teste
      for (final doc in testInterests.docs) {
        await doc.reference.delete();
        EnhancedLogger.info('🗑️ Removido interesse de teste: ${doc.id}');
      }

      EnhancedLogger.success('✅ Limpeza concluída');
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro na limpeza',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Executa teste rápido
  static Future<void> quickTest(String userId) async {
    EnhancedLogger.info('⚡ TESTE RÁPIDO PARA: $userId');

    try {
      final notifications = await _service.getRealInterestNotifications(userId);

      if (notifications.isNotEmpty) {
        EnhancedLogger.success(
            '✅ SUCESSO: ${notifications.length} notificações encontradas');
        for (final notification in notifications) {
          EnhancedLogger.info(
              '   📧 ${notification.fromUserName}: ${notification.message}');
        }
      } else {
        EnhancedLogger.warning('⚠️ Nenhuma notificação encontrada');

        // Verifica se há interesses na coleção
        final allInterests = await _repository.getAllInterestsForDebug();
        EnhancedLogger.info(
            '📊 Total de interesses na coleção: ${allInterests.length}');

        final userInterests =
            allInterests.where((i) => i.to == userId).toList();
        EnhancedLogger.info(
            '🎯 Interesses para este usuário: ${userInterests.length}');
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ ERRO NO TESTE RÁPIDO',
          error: e, stackTrace: stackTrace);
    }
  }
}
