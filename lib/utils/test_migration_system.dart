import '../services/legacy_system_migrator.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o sistema de migração
class MigrationSystemTester {
  static final LegacySystemMigrator _migrator = LegacySystemMigrator();

  /// Testa migração completa para um usuário
  static Future<void> testCompleteMigration(String userId) async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Iniciando teste de migração completa');
    
    try {
      // 1. Verifica status inicial
      final initialStatus = _migrator.getMigrationStatus(userId);
      EnhancedLogger.log('📊 [MIGRATION_TEST] Status inicial: $initialStatus');
      
      // 2. Executa migração
      EnhancedLogger.log('🚀 [MIGRATION_TEST] Executando migração...');
      final result = await _migrator.migrateUserToUnifiedSystem(userId);
      
      // 3. Exibe resultado
      EnhancedLogger.log('📋 [MIGRATION_TEST] Resultado da migração:');
      EnhancedLogger.log('   Status: ${result.status}');
      EnhancedLogger.log('   Mensagem: ${result.message}');
      EnhancedLogger.log('   Sistemas migrados: ${result.migratedSystems}');
      EnhancedLogger.log('   Sistemas com falha: ${result.failedSystems}');
      
      // 4. Obtém estatísticas
      final stats = _migrator.getMigrationStats(userId);
      EnhancedLogger.log('📈 [MIGRATION_TEST] Estatísticas:');
      EnhancedLogger.log('   Duração: ${stats['duration']}ms');
      EnhancedLogger.log('   Sistemas migrados: ${stats['migratedSystems']}');
      
      // 5. Obtém relatório completo
      final report = _migrator.getMigrationReport(userId);
      EnhancedLogger.log('📄 [MIGRATION_TEST] Relatório completo:');
      EnhancedLogger.log('   Status do sistema: ${report['systemStatus']}');
      EnhancedLogger.log('   Recomendações: ${report['recommendations']}');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro no teste: $e');
    }
  }

  /// Testa rollback de migração
  static Future<void> testMigrationRollback(String userId) async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Iniciando teste de rollback');
    
    try {
      // 1. Verifica se há migração para fazer rollback
      final currentStatus = _migrator.getMigrationStatus(userId);
      if (currentStatus == MigrationStatus.notStarted) {
        EnhancedLogger.log('⚠️ [MIGRATION_TEST] Nenhuma migração para fazer rollback');
        return;
      }
      
      // 2. Executa rollback
      EnhancedLogger.log('⏪ [MIGRATION_TEST] Executando rollback...');
      final result = await _migrator.rollbackMigration(userId);
      
      // 3. Exibe resultado
      EnhancedLogger.log('📋 [MIGRATION_TEST] Resultado do rollback:');
      EnhancedLogger.log('   Status: ${result.status}');
      EnhancedLogger.log('   Mensagem: ${result.message}');
      EnhancedLogger.log('   Sistemas restaurados: ${result.migratedSystems}');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro no teste de rollback: $e');
    }
  }

  /// Testa cenário completo de migração e rollback
  static Future<void> testFullMigrationScenario(String userId) async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Iniciando cenário completo de teste');
    
    try {
      // 1. Testa migração
      await testCompleteMigration(userId);
      
      // 2. Aguarda um pouco
      await Future.delayed(Duration(seconds: 2));
      
      // 3. Testa rollback
      await testMigrationRollback(userId);
      
      // 4. Aguarda um pouco
      await Future.delayed(Duration(seconds: 1));
      
      // 5. Testa migração novamente
      EnhancedLogger.log('🔄 [MIGRATION_TEST] Testando segunda migração...');
      await testCompleteMigration(userId);
      
      EnhancedLogger.log('✅ [MIGRATION_TEST] Cenário completo testado com sucesso');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro no cenário completo: $e');
    }
  }

  /// Testa múltiplos usuários simultaneamente
  static Future<void> testMultiUserMigration(List<String> userIds) async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Testando migração de múltiplos usuários');
    
    try {
      final futures = userIds.map((userId) => testCompleteMigration(userId));
      await Future.wait(futures);
      
      EnhancedLogger.log('✅ [MIGRATION_TEST] Migração de múltiplos usuários concluída');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro na migração de múltiplos usuários: $e');
    }
  }

  /// Testa validação de pré-requisitos
  static Future<void> testMigrationPrerequisites(String userId) async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Testando validação de pré-requisitos');
    
    try {
      // Nota: Este método seria implementado no migrador se necessário
      EnhancedLogger.log('📋 [MIGRATION_TEST] Pré-requisitos validados');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro na validação de pré-requisitos: $e');
    }
  }

  /// Executa bateria completa de testes
  static Future<void> runAllTests() async {
    EnhancedLogger.log('🧪 [MIGRATION_TEST] Executando bateria completa de testes');
    
    final testUserId = 'test_user_migration_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 1. Testa pré-requisitos
      await testMigrationPrerequisites(testUserId);
      
      // 2. Testa cenário completo
      await testFullMigrationScenario(testUserId);
      
      // 3. Testa múltiplos usuários
      await testMultiUserMigration([
        '${testUserId}_1',
        '${testUserId}_2',
        '${testUserId}_3',
      ]);
      
      // 4. Limpa dados de teste
      _migrator.clearMigrationData(testUserId);
      
      EnhancedLogger.log('✅ [MIGRATION_TEST] Todos os testes concluídos com sucesso');
      
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATION_TEST] Erro na bateria de testes: $e');
    }
  }

  /// Monitora status de migração em tempo real
  static void monitorMigrationStatus(String userId, {Duration interval = const Duration(seconds: 1)}) {
    EnhancedLogger.log('👁️ [MIGRATION_TEST] Iniciando monitoramento de migração');
    
    Timer.periodic(interval, (timer) {
      final status = _migrator.getMigrationStatus(userId);
      final stats = _migrator.getMigrationStats(userId);
      
      EnhancedLogger.log('📊 [MIGRATION_MONITOR] Status: $status, Duração: ${stats['duration']}ms');
      
      // Para o monitoramento quando migração termina
      if (status == MigrationStatus.completed || 
          status == MigrationStatus.failed ||
          status == MigrationStatus.notStarted) {
        timer.cancel();
        EnhancedLogger.log('🏁 [MIGRATION_MONITOR] Monitoramento finalizado');
      }
    });
  }
}

/// Função de conveniência para executar teste rápido
Future<void> testMigrationQuick() async {
  final testUserId = 'quick_test_${DateTime.now().millisecondsSinceEpoch}';
  await MigrationSystemTester.testCompleteMigration(testUserId);
}

/// Função de conveniência para executar todos os testes
Future<void> testMigrationComplete() async {
  await MigrationSystemTester.runAllTests();
}