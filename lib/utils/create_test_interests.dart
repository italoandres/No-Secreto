import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para criar dados de teste na coleção interests
class CreateTestInterests {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria interesses de teste para o usuário itala
  static Future<void> createTestInterestsForItala() async {
    try {
      EnhancedLogger.info('🔧 [CREATE_TEST] Criando interesses de teste para itala...');
      
      final italaUserId = 'St2kw3cgX2MMPxlLRmBDjYm2nO22';
      final now = Timestamp.now();
      
      // Lista de usuários fictícios que vão demonstrar interesse por itala
      final testUsers = [
        {
          'id': 'test_user_1',
          'name': 'João Silva',
          'username': 'joao123'
        },
        {
          'id': 'test_user_2', 
          'name': 'Pedro Santos',
          'username': 'pedro456'
        },
        {
          'id': 'test_user_3',
          'name': 'Carlos Lima', 
          'username': 'carlos789'
        }
      ];

      // Criar interesses de teste
      for (int i = 0; i < testUsers.length; i++) {
        final user = testUsers[i];
        final interestData = {
          'from': user['id'], // Quem demonstrou interesse
          'to': italaUserId,   // Para quem (itala)
          'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(Duration(hours: i + 1))
          ),
          'type': 'like',
          'status': 'active',
          'fromUserName': user['name'],
          'fromUsername': user['username'],
          'toUserName': 'itala',
          'toUsername': 'itala',
          'createdAt': now,
          'updatedAt': now,
        };

        // Adicionar à coleção interests
        await _firestore.collection('interests').add(interestData);
        
        EnhancedLogger.success('✅ [CREATE_TEST] Interesse criado: ${user['name']} → itala');
      }

      EnhancedLogger.success('🎉 [CREATE_TEST] ${testUsers.length} interesses de teste criados com sucesso!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [CREATE_TEST] Erro ao criar interesses de teste', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Verifica se existem interesses na coleção
  static Future<void> checkExistingInterests() async {
    try {
      EnhancedLogger.info('🔍 [CHECK_INTERESTS] Verificando interesses existentes...');
      
      // Buscar todos os interesses
      final allInterests = await _firestore.collection('interests').get();
      EnhancedLogger.info('📊 [CHECK_INTERESTS] Total de interesses: ${allInterests.docs.length}');
      
      if (allInterests.docs.isEmpty) {
        EnhancedLogger.warning('⚠️ [CHECK_INTERESTS] Nenhum interesse encontrado na coleção!');
        EnhancedLogger.info('💡 [CHECK_INTERESTS] Execute createTestInterestsForItala() para criar dados de teste');
        return;
      }

      // Buscar interesses para itala especificamente
      final italaUserId = 'St2kw3cgX2MMPxlLRmBDjYm2nO22';
      final italaInterests = await _firestore
          .collection('interests')
          .where('to', isEqualTo: italaUserId)
          .get();
      
      EnhancedLogger.info('👤 [CHECK_INTERESTS] Interesses para itala: ${italaInterests.docs.length}');
      
      // Mostrar detalhes dos interesses para itala
      for (final doc in italaInterests.docs) {
        final data = doc.data();
        EnhancedLogger.info('📋 [CHECK_INTERESTS] Interesse: ${data['fromUserName'] ?? data['from']} → ${data['toUserName'] ?? data['to']}');
      }
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [CHECK_INTERESTS] Erro ao verificar interesses', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Limpa todos os interesses de teste
  static Future<void> clearTestInterests() async {
    try {
      EnhancedLogger.info('🧹 [CLEAR_TEST] Limpando interesses de teste...');
      
      final testInterests = await _firestore
          .collection('interests')
          .where('from', whereIn: ['test_user_1', 'test_user_2', 'test_user_3'])
          .get();
      
      final batch = _firestore.batch();
      for (final doc in testInterests.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      EnhancedLogger.success('✅ [CLEAR_TEST] ${testInterests.docs.length} interesses de teste removidos');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [CLEAR_TEST] Erro ao limpar interesses de teste', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Execução completa: verifica, cria se necessário, e testa
  static Future<void> setupCompleteTest() async {
    EnhancedLogger.info('🚀 [SETUP_TEST] Iniciando configuração completa de teste...');
    
    // 1. Verificar estado atual
    await checkExistingInterests();
    
    // 2. Criar interesses de teste
    await createTestInterestsForItala();
    
    // 3. Verificar novamente
    await checkExistingInterests();
    
    EnhancedLogger.success('🎉 [SETUP_TEST] Configuração completa finalizada!');
    EnhancedLogger.info('💡 [SETUP_TEST] Agora teste as notificações reais no app');
  }
}

/// Função global para fácil acesso no console
Future<void> createTestInterests() async {
  await CreateTestInterests.setupCompleteTest();
}

/// Função global para verificar interesses
Future<void> checkInterests() async {
  await CreateTestInterests.checkExistingInterests();
}

/// Função global para limpar testes
Future<void> clearTestInterests() async {
  await CreateTestInterests.clearTestInterests();
}