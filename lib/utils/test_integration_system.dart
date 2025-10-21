import '../services/unified_notification_interface.dart';
import '../services/conflict_resolver.dart';
import '../services/data_recovery_service.dart';
import '../services/notification_local_storage.dart';
import '../services/offline_sync_manager.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para executar testes de integração do sistema
class IntegrationSystemTester {
  static final UnifiedNotificationInterface _unifiedInterface = UnifiedNotificationInterface();
  static final ConflictResolver _conflictResolver = ConflictResolver();
  static final DataRecoveryService _recoveryService = DataRecoveryService();
  static final NotificationLocalStorage _localStorage = NotificationLocalStorage();
  static final OfflineSyncManager _syncManager = OfflineSyncManager();

  /// Executa teste completo de integração
  static Future<void> runCompleteIntegrationTest() async {
    EnhancedLogger.log('🚀 [INTEGRATION_TEST] Iniciando teste completo de integração');

    final testUserId = 'integration_test_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Inicializa todos os serviços
      await _initializeServices();

      // 2. Testa cenário de conflito
      await _testConflictScenario(testUserId);

      // 3. Testa cenário de recuperação
      await _testRecoveryScenario(testUserId);

      // 4. Testa cenário de stress
      await _testStressScenario(testUserId);

      // 5. Testa cenário de sincronização
      await _testSyncScenario(testUserId);

      // 6. Valida estado final
      await _validateFinalState(testUserId);

      // 7. Limpa dados de teste
      await _cleanup(testUserId);

      EnhancedLogger.log('✅ [INTEGRATION_TEST] Teste completo de integração concluído com sucesso');

    } catch (e) {
      EnhancedLogger.log('❌ [INTEGRATION_TEST] Erro no teste de integração: $e');
      await _cleanup(testUserId);
      rethrow;
    }
  }

  /// Inicializa todos os serviços
  static Future<void> _initializeServices() async {
    EnhancedLogger.log('🔧 [INTEGRATION_TEST] Inicializando serviços');

    await _localStorage.initialize();
    await _syncManager.initialize();

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Serviços inicializados');
  }

  /// Testa cenário de conflito
  static Future<void> _testConflictScenario(String userId) async {
    EnhancedLogger.log('⚔️ [INTEGRATION_TEST] Testando cenário de conflito');

    // Cria notificações conflitantes
    final notification1 = RealNotificationModel(
      id: 'conflict_test',
      userId: userId,
      type: 'test',
      title: 'Título Original',
      message: 'Mensagem original',
      timestamp: DateTime.now().subtract(Duration(minutes: 1)),
      isRead: false,
      data: {'version': 1},
    );

    final notification2 = RealNotificationModel(
      id: 'conflict_test', // Mesmo ID
      userId: userId,
      type: 'test',
      title: 'Título Atualizado',
      message: 'Mensagem atualizada',
      timestamp: DateTime.now(),
      isRead: true,
      data: {'version': 2},
    );

    // Adiciona notificações conflitantes
    await _unifiedInterface.addNotification(userId, notification1);
    await _unifiedInterface.addNotification(userId, notification2);

    // Detecta e resolve conflitos
    final conflicts = await _conflictResolver.detectConflicts(userId);
    if (conflicts.isNotEmpty) {
      await _conflictResolver.resolveConflicts(userId);
      EnhancedLogger.log('✅ [INTEGRATION_TEST] Conflitos resolvidos: ${conflicts.length}');
    }

    // Valida resolução
    final finalNotifications = await _unifiedInterface.getNotifications(userId);
    final resolvedNotification = finalNotifications.firstWhere((n) => n.id == 'conflict_test');
    
    if (resolvedNotification.title != 'Título Atualizado' || !resolvedNotification.isRead) {
      throw Exception('Conflito não foi resolvido corretamente');
    }

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Cenário de conflito passou');
  }

  /// Testa cenário de recuperação
  static Future<void> _testRecoveryScenario(String userId) async {
    EnhancedLogger.log('🔄 [INTEGRATION_TEST] Testando cenário de recuperação');

    // Cria dados de teste
    final testNotifications = _createTestNotifications(userId, 10);
    await _localStorage.saveNotifications(userId, testNotifications);

    // Cria backup de emergência
    await _recoveryService.createEmergencyBackup(userId, testNotifications.take(5).toList());

    // Simula perda de dados
    await _localStorage.clearNotifications(userId);
    _unifiedInterface.clearCache(userId);

    // Verifica perda
    final lostData = await _localStorage.loadNotifications(userId);
    if (lostData.isNotEmpty) {
      throw Exception('Dados não foram perdidos como esperado');
    }

    // Executa recuperação
    final recoveryResult = await _recoveryService.recoverLostData(userId);
    if (!recoveryResult.success) {
      throw Exception('Recuperação falhou: ${recoveryResult.message}');
    }

    // Valida recuperação
    final recoveredData = await _unifiedInterface.getNotifications(userId);
    if (recoveredData.isEmpty) {
      throw Exception('Nenhum dado foi recuperado');
    }

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Cenário de recuperação passou: ${recoveredData.length} notificações recuperadas');
  }

  /// Testa cenário de stress
  static Future<void> _testStressScenario(String userId) async {
    EnhancedLogger.log('💪 [INTEGRATION_TEST] Testando cenário de stress');

    const int operationCount = 50;
    final futures = <Future<void>>[];

    // Executa operações simultâneas
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < operationCount; i++) {
      final notification = RealNotificationModel(
        id: 'stress_$i',
        userId: userId,
        type: 'stress',
        title: 'Stress Test $i',
        message: 'Mensagem de stress $i',
        timestamp: DateTime.now().subtract(Duration(seconds: i)),
        isRead: i % 2 == 0,
        data: {'stressIndex': i},
      );

      futures.add(_unifiedInterface.addNotification(userId, notification));
    }

    await Future.wait(futures);
    stopwatch.stop();

    // Valida resultado
    final finalNotifications = await _unifiedInterface.getNotifications(userId);
    if (finalNotifications.length < operationCount) {
      throw Exception('Nem todas as operações de stress foram processadas');
    }

    final avgTime = stopwatch.elapsedMilliseconds / operationCount;
    if (avgTime > 100) {
      EnhancedLogger.log('⚠️ [INTEGRATION_TEST] Performance abaixo do esperado: ${avgTime.toStringAsFixed(2)}ms/op');
    }

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Cenário de stress passou: $operationCount operações em ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Testa cenário de sincronização
  static Future<void> _testSyncScenario(String userId) async {
    EnhancedLogger.log('🔄 [INTEGRATION_TEST] Testando cenário de sincronização');

    // Cria operações pendentes
    final pendingOps = [
      PendingOperation(
        id: 'sync_op_1',
        userId: userId,
        type: 'add',
        data: _createTestNotifications(userId, 1).first.toJson(),
        timestamp: DateTime.now(),
      ),
      PendingOperation(
        id: 'sync_op_2',
        userId: userId,
        type: 'update',
        data: _createTestNotifications(userId, 1).first.toJson(),
        timestamp: DateTime.now(),
      ),
    ];

    for (final op in pendingOps) {
      await _syncManager.addPendingOperation(op);
    }

    // Executa sincronização
    final syncResult = await _syncManager.syncNotifications(userId);
    if (!syncResult.success) {
      throw Exception('Sincronização falhou: ${syncResult.message}');
    }

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Cenário de sincronização passou: ${syncResult.syncedCount} operações sincronizadas');
  }

  /// Valida estado final do sistema
  static Future<void> _validateFinalState(String userId) async {
    EnhancedLogger.log('🔍 [INTEGRATION_TEST] Validando estado final');

    // Verifica consistência
    final isConsistent = await _unifiedInterface.validateConsistency(userId);
    if (!isConsistent) {
      throw Exception('Sistema não está consistente');
    }

    // Verifica se há dados
    final notifications = await _unifiedInterface.getNotifications(userId);
    if (notifications.isEmpty) {
      throw Exception('Nenhuma notificação encontrada no estado final');
    }

    // Verifica integridade dos dados
    final isValid = await _recoveryService.validateDataIntegrity(userId, notifications);
    if (!isValid) {
      throw Exception('Dados não passaram na validação de integridade');
    }

    // Obtém estatísticas finais
    final stats = await _localStorage.getStorageStats(userId);
    EnhancedLogger.log('📊 [INTEGRATION_TEST] Estatísticas finais: $stats');

    EnhancedLogger.log('✅ [INTEGRATION_TEST] Estado final validado');
  }

  /// Limpa dados de teste
  static Future<void> _cleanup(String userId) async {
    EnhancedLogger.log('🧹 [INTEGRATION_TEST] Limpando dados de teste');

    try {
      await _localStorage.clearNotifications(userId);
      await _syncManager.clearPendingOperations(userId);
      _unifiedInterface.disposeUser(userId);
      _recoveryService.dispose();
    } catch (e) {
      EnhancedLogger.log('⚠️ [INTEGRATION_TEST] Erro na limpeza: $e');
    }
  }

  /// Executa teste de performance
  static Future<Map<String, dynamic>> runPerformanceTest() async {
    EnhancedLogger.log('⚡ [INTEGRATION_TEST] Executando teste de performance');

    final testUserId = 'perf_test_${DateTime.now().millisecondsSinceEpoch}';
    final results = <String, dynamic>{};

    try {
      await _initializeServices();

      // Teste de adição em lote
      final addStopwatch = Stopwatch()..start();
      final notifications = _createTestNotifications(testUserId, 1000);
      await _localStorage.saveNotifications(testUserId, notifications);
      addStopwatch.stop();

      results['batchAdd'] = {
        'count': 1000,
        'timeMs': addStopwatch.elapsedMilliseconds,
        'avgTimePerItem': addStopwatch.elapsedMilliseconds / 1000,
      };

      // Teste de consulta
      final queryStopwatch = Stopwatch()..start();
      final loadedNotifications = await _localStorage.loadNotifications(testUserId);
      queryStopwatch.stop();

      results['query'] = {
        'count': loadedNotifications.length,
        'timeMs': queryStopwatch.elapsedMilliseconds,
      };

      // Teste de operação individual
      final individualStopwatch = Stopwatch()..start();
      final newNotification = _createTestNotifications(testUserId, 1).first;
      await _localStorage.addNotification(testUserId, newNotification);
      individualStopwatch.stop();

      results['individualOperation'] = {
        'timeMs': individualStopwatch.elapsedMilliseconds,
      };

      // Teste de resolução de conflitos
      final conflictStopwatch = Stopwatch()..start();
      await _conflictResolver.resolveConflicts(testUserId);
      conflictStopwatch.stop();

      results['conflictResolution'] = {
        'timeMs': conflictStopwatch.elapsedMilliseconds,
      };

      await _cleanup(testUserId);

      results['summary'] = {
        'totalTestTime': addStopwatch.elapsedMilliseconds + queryStopwatch.elapsedMilliseconds + 
                        individualStopwatch.elapsedMilliseconds + conflictStopwatch.elapsedMilliseconds,
        'passed': true,
      };

      EnhancedLogger.log('✅ [INTEGRATION_TEST] Teste de performance concluído');
      return results;

    } catch (e) {
      EnhancedLogger.log('❌ [INTEGRATION_TEST] Erro no teste de performance: $e');
      await _cleanup(testUserId);
      
      results['error'] = e.toString();
      results['passed'] = false;
      return results;
    }
  }

  /// Executa teste de confiabilidade
  static Future<bool> runReliabilityTest() async {
    EnhancedLogger.log('🛡️ [INTEGRATION_TEST] Executando teste de confiabilidade');

    final testUserId = 'reliability_test_${DateTime.now().millisecondsSinceEpoch}';
    var successCount = 0;
    const int totalRuns = 10;

    try {
      await _initializeServices();

      for (int run = 0; run < totalRuns; run++) {
        try {
          // Executa operações básicas
          final notifications = _createTestNotifications(testUserId, 10);
          await _localStorage.saveNotifications(testUserId, notifications);
          
          final loaded = await _localStorage.loadNotifications(testUserId);
          if (loaded.length == notifications.length) {
            successCount++;
          }

          // Limpa para próxima iteração
          await _localStorage.clearNotifications(testUserId);

        } catch (e) {
          EnhancedLogger.log('⚠️ [INTEGRATION_TEST] Falha na execução $run: $e');
        }
      }

      await _cleanup(testUserId);

      final successRate = (successCount / totalRuns) * 100;
      EnhancedLogger.log('📊 [INTEGRATION_TEST] Taxa de sucesso: ${successRate.toStringAsFixed(1)}% ($successCount/$totalRuns)');

      return successRate >= 90; // 90% de taxa de sucesso mínima

    } catch (e) {
      EnhancedLogger.log('❌ [INTEGRATION_TEST] Erro no teste de confiabilidade: $e');
      await _cleanup(testUserId);
      return false;
    }
  }

  /// Cria notificações de teste
  static List<RealNotificationModel> _createTestNotifications(String userId, int count) {
    final notifications = <RealNotificationModel>[];
    final baseTime = DateTime.now();

    for (int i = 0; i < count; i++) {
      notifications.add(RealNotificationModel(
        id: 'integration_test_$i',
        userId: userId,
        type: 'integration_test',
        title: 'Teste de Integração $i',
        message: 'Mensagem de teste de integração número $i',
        timestamp: baseTime.subtract(Duration(minutes: i)),
        isRead: i % 2 == 0,
        data: {
          'testIndex': i,
          'integrationTest': true,
          'createdAt': baseTime.toIso8601String(),
        },
      ));
    }

    return notifications;
  }
}

/// Função de conveniência para teste rápido
Future<void> testIntegrationQuick() async {
  await IntegrationSystemTester.runCompleteIntegrationTest();
}

/// Função de conveniência para teste de performance
Future<Map<String, dynamic>> testIntegrationPerformance() async {
  return await IntegrationSystemTester.runPerformanceTest();
}

/// Função de conveniência para teste de confiabilidade
Future<bool> testIntegrationReliability() async {
  return await IntegrationSystemTester.runReliabilityTest();
}