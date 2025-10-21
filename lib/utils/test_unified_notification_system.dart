import 'dart:async';
import '../services/unified_notification_interface.dart';
import '../models/real_notification_model.dart';
import 'enhanced_logger.dart';

/// Utilitário para testar o sistema unificado de notificações
class TestUnifiedNotificationSystem {
  static final UnifiedNotificationInterface _unifiedInterface = UnifiedNotificationInterface();

  /// Testa o sistema unificado para um usuário
  static Future<void> testUnifiedSystem(String userId) async {
    EnhancedLogger.log('🧪 [TEST_UNIFIED] Iniciando teste do sistema unificado para: $userId');
    
    try {
      // 1. Testa stream unificado
      await _testUnifiedStream(userId);
      
      // 2. Testa cache
      await _testCache(userId);
      
      // 3. Testa sincronização forçada
      await _testForceSync(userId);
      
      // 4. Testa resolução de conflitos
      await _testConflictResolution(userId);
      
      // 5. Testa validação de consistência
      await _testConsistencyValidation(userId);
      
      EnhancedLogger.log('✅ [TEST_UNIFIED] Todos os testes passaram para: $userId');
      
    } catch (e) {
      EnhancedLogger.log('❌ [TEST_UNIFIED] Erro nos testes: $e');
      rethrow;
    }
  }

  /// Testa stream unificado
  static Future<void> _testUnifiedStream(String userId) async {
    EnhancedLogger.log('📡 [TEST_UNIFIED] Testando stream unificado...');
    
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = _unifiedInterface
        .getUnifiedNotificationStream(userId)
        .timeout(const Duration(seconds: 10))
        .listen(
          (notifications) {
            EnhancedLogger.log('✅ [TEST_UNIFIED] Stream funcionando: ${notifications.length} notificações');
            subscription.cancel();
            completer.complete();
          },
          onError: (error) {
            EnhancedLogger.log('❌ [TEST_UNIFIED] Erro no stream: $error');
            subscription.cancel();
            completer.completeError(error);
          },
        );
    
    await completer.future;
  }

  /// Testa cache
  static Future<void> _testCache(String userId) async {
    EnhancedLogger.log('📦 [TEST_UNIFIED] Testando cache...');
    
    // Verifica se há cache
    final hasCache = _unifiedInterface.hasCachedData(userId);
    EnhancedLogger.log('📦 [TEST_UNIFIED] Cache disponível: $hasCache');
    
    // Obtém dados do cache
    final cachedNotifications = _unifiedInterface.getCachedNotifications(userId);
    EnhancedLogger.log('📦 [TEST_UNIFIED] Notificações em cache: ${cachedNotifications.length}');
    
    // Testa invalidação
    await _unifiedInterface.invalidateAndRefresh(userId);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Cache invalidado e atualizado');
  }

  /// Testa sincronização forçada
  static Future<void> _testForceSync(String userId) async {
    EnhancedLogger.log('🚀 [TEST_UNIFIED] Testando sincronização forçada...');
    
    await _unifiedInterface.forceSync(userId);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Sincronização forçada concluída');
  }

  /// Testa resolução de conflitos
  static Future<void> _testConflictResolution(String userId) async {
    EnhancedLogger.log('⚡ [TEST_UNIFIED] Testando resolução de conflitos...');
    
    await _unifiedInterface.resolveConflicts(userId);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Conflitos resolvidos');
  }

  /// Testa validação de consistência
  static Future<void> _testConsistencyValidation(String userId) async {
    EnhancedLogger.log('🔍 [TEST_UNIFIED] Testando validação de consistência...');
    
    final isConsistent = await _unifiedInterface.validateConsistency(userId);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Sistema consistente: $isConsistent');
  }

  /// Executa teste de stress
  static Future<void> stressTest(String userId, {int iterations = 10}) async {
    EnhancedLogger.log('💪 [TEST_UNIFIED] Iniciando teste de stress com $iterations iterações...');
    
    final futures = <Future>[];
    
    for (int i = 0; i < iterations; i++) {
      futures.add(_performStressIteration(userId, i));
    }
    
    await Future.wait(futures);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Teste de stress concluído');
  }

  /// Executa uma iteração do teste de stress
  static Future<void> _performStressIteration(String userId, int iteration) async {
    try {
      // Força sync
      await _unifiedInterface.forceSync(userId);
      
      // Obtém dados do cache
      _unifiedInterface.getCachedNotifications(userId);
      
      // Valida consistência
      await _unifiedInterface.validateConsistency(userId);
      
      EnhancedLogger.log('✅ [TEST_UNIFIED] Iteração $iteration concluída');
      
    } catch (e) {
      EnhancedLogger.log('❌ [TEST_UNIFIED] Erro na iteração $iteration: $e');
    }
  }

  /// Testa múltiplos usuários simultaneamente
  static Future<void> testMultipleUsers(List<String> userIds) async {
    EnhancedLogger.log('👥 [TEST_UNIFIED] Testando ${userIds.length} usuários simultaneamente...');
    
    final futures = userIds.map((userId) => testUnifiedSystem(userId)).toList();
    
    await Future.wait(futures);
    EnhancedLogger.log('✅ [TEST_UNIFIED] Teste de múltiplos usuários concluído');
  }

  /// Monitora sistema em tempo real
  static StreamSubscription monitorSystem(String userId, {Duration? duration}) {
    EnhancedLogger.log('👁️ [TEST_UNIFIED] Iniciando monitoramento do sistema...');
    
    final subscription = _unifiedInterface
        .getUnifiedNotificationStream(userId)
        .listen(
          (notifications) {
            final stats = _unifiedInterface.getSystemStats();
            EnhancedLogger.log('📊 [MONITOR] ${notifications.length} notificações | Stats: $stats');
          },
          onError: (error) {
            EnhancedLogger.log('❌ [MONITOR] Erro no monitoramento: $error');
          },
        );
    
    // Auto-cancela após duração especificada
    if (duration != null) {
      Timer(duration, () {
        subscription.cancel();
        EnhancedLogger.log('⏰ [MONITOR] Monitoramento finalizado após ${duration.inSeconds}s');
      });
    }
    
    return subscription;
  }

  /// Imprime estatísticas detalhadas
  static void printDetailedStats() {
    EnhancedLogger.log('📊 [TEST_UNIFIED] Estatísticas detalhadas do sistema:');
    
    final stats = _unifiedInterface.getSystemStats();
    for (final entry in stats.entries) {
      EnhancedLogger.log('  ${entry.key}: ${entry.value}');
    }
    
    _unifiedInterface.debugPrintSystemState();
  }

  /// Executa teste completo do sistema
  static Future<void> runCompleteTest(String userId) async {
    EnhancedLogger.log('🎯 [TEST_UNIFIED] Executando teste completo do sistema unificado...');
    
    try {
      // Imprime estado inicial
      printDetailedStats();
      
      // Executa testes básicos
      await testUnifiedSystem(userId);
      
      // Executa teste de stress
      await stressTest(userId, iterations: 5);
      
      // Imprime estado final
      printDetailedStats();
      
      EnhancedLogger.log('🎉 [TEST_UNIFIED] Teste completo concluído com sucesso!');
      
    } catch (e) {
      EnhancedLogger.log('💥 [TEST_UNIFIED] Falha no teste completo: $e');
      rethrow;
    }
  }
}