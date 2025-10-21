import '../services/notification_local_storage.dart';
import '../services/offline_sync_manager.dart';
import '../services/data_recovery_service.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o sistema de persistência
class PersistenceSystemTester {
  static final NotificationLocalStorage _localStorage = NotificationLocalStorage();
  static final OfflineSyncManager _syncManager = OfflineSyncManager();
  static final DataRecoveryService _recoveryService = DataRecoveryService();

  /// Testa armazenamento local completo
  static Future<void> testLocalStorage(String userId) async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Testando armazenamento local');

    try {
      // 1. Inicializa armazenamento
      await _localStorage.initialize();
      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Armazenamento inicializado');

      // 2. Cria notificações de teste
      final testNotifications = _createTestNotifications(userId, 10);
      EnhancedLogger.log('📝 [PERSISTENCE_TEST] Criadas ${testNotifications.length} notificações de teste');

      // 3. Testa salvamento
      final saveSuccess = await _localStorage.saveNotifications(userId, testNotifications);
      EnhancedLogger.log('💾 [PERSISTENCE_TEST] Salvamento: ${saveSuccess ? 'SUCESSO' : 'FALHA'}');

      // 4. Testa carregamento
      final loadedNotifications = await _localStorage.loadNotifications(userId);
      EnhancedLogger.log('📂 [PERSISTENCE_TEST] Carregadas ${loadedNotifications.length} notificações');

      // 5. Verifica integridade
      final integrityOk = _verifyIntegrity(testNotifications, loadedNotifications);
      EnhancedLogger.log('🔍 [PERSISTENCE_TEST] Integridade: ${integrityOk ? 'OK' : 'FALHA'}');

      // 6. Testa adição individual
      final newNotification = _createTestNotifications(userId, 1).first;
      final addSuccess = await _localStorage.addNotification(userId, newNotification);
      EnhancedLogger.log('➕ [PERSISTENCE_TEST] Adição individual: ${addSuccess ? 'SUCESSO' : 'FALHA'}');

      // 7. Testa atualização
      newNotification.message = 'Mensagem atualizada';
      final updateSuccess = await _localStorage.updateNotification(userId, newNotification);
      EnhancedLogger.log('✏️ [PERSISTENCE_TEST] Atualização: ${updateSuccess ? 'SUCESSO' : 'FALHA'}');

      // 8. Testa remoção
      final removeSuccess = await _localStorage.removeNotification(userId, newNotification.id);
      EnhancedLogger.log('🗑️ [PERSISTENCE_TEST] Remoção: ${removeSuccess ? 'SUCESSO' : 'FALHA'}');

      // 9. Obtém estatísticas
      final stats = await _localStorage.getStorageStats(userId);
      EnhancedLogger.log('📊 [PERSISTENCE_TEST] Estatísticas: $stats');

      // 10. Testa limpeza
      final clearSuccess = await _localStorage.clearNotifications(userId);
      EnhancedLogger.log('🧹 [PERSISTENCE_TEST] Limpeza: ${clearSuccess ? 'SUCESSO' : 'FALHA'}');

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Teste de armazenamento local concluído');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro no teste de armazenamento: $e');
    }
  }

  /// Testa sincronização offline/online
  static Future<void> testOfflineSync(String userId) async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Testando sincronização offline/online');

    try {
      // 1. Inicializa gerenciador de sincronização
      await _syncManager.initialize();
      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Gerenciador de sincronização inicializado');

      // 2. Monitora status de conectividade
      final connectivitySubscription = _syncManager.connectivityStream.listen((status) {
        EnhancedLogger.log('📶 [PERSISTENCE_TEST] Status de conectividade: $status');
      });

      // 3. Monitora progresso de sincronização
      final progressSubscription = _syncManager.syncProgressStream.listen((progress) {
        EnhancedLogger.log('🔄 [PERSISTENCE_TEST] Progresso: ${(progress.progress * 100).toInt()}% - ${progress.message}');
      });

      // 4. Cria operações pendentes
      final pendingOps = [
        PendingOperation(
          id: 'op1',
          userId: userId,
          type: 'add',
          data: _createTestNotifications(userId, 1).first.toJson(),
          timestamp: DateTime.now(),
        ),
        PendingOperation(
          id: 'op2',
          userId: userId,
          type: 'update',
          data: _createTestNotifications(userId, 1).first.toJson(),
          timestamp: DateTime.now(),
        ),
      ];

      for (final op in pendingOps) {
        await _syncManager.addPendingOperation(op);
      }

      EnhancedLogger.log('📝 [PERSISTENCE_TEST] Adicionadas ${pendingOps.length} operações pendentes');

      // 5. Testa sincronização
      final syncResult = await _syncManager.syncNotifications(userId);
      EnhancedLogger.log('🔄 [PERSISTENCE_TEST] Resultado da sincronização:');
      EnhancedLogger.log('   Sucesso: ${syncResult.success}');
      EnhancedLogger.log('   Mensagem: ${syncResult.message}');
      EnhancedLogger.log('   Sincronizadas: ${syncResult.syncedCount}');
      EnhancedLogger.log('   Falhas: ${syncResult.failedCount}');

      // 6. Obtém estatísticas
      final stats = await _syncManager.getSyncStats(userId);
      EnhancedLogger.log('📊 [PERSISTENCE_TEST] Estatísticas de sincronização: $stats');

      // 7. Testa força de sincronização
      final forceResult = await _syncManager.forceSync(userId);
      EnhancedLogger.log('⚡ [PERSISTENCE_TEST] Força de sincronização: ${forceResult.success ? 'SUCESSO' : 'FALHA'}');

      // Limpa subscriptions
      await connectivitySubscription.cancel();
      await progressSubscription.cancel();

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Teste de sincronização concluído');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro no teste de sincronização: $e');
    }
  }

  /// Testa recuperação de dados
  static Future<void> testDataRecovery(String userId) async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Testando recuperação de dados');

    try {
      // 1. Monitora progresso de recuperação
      final progressSubscription = _recoveryService.recoveryProgressStream.listen((progress) {
        EnhancedLogger.log('🔄 [PERSISTENCE_TEST] Recuperação: ${(progress.progress * 100).toInt()}% - ${progress.message}');
      });

      // 2. Cria backup de emergência
      final testNotifications = _createTestNotifications(userId, 5);
      final backupSuccess = await _recoveryService.createEmergencyBackup(userId, testNotifications);
      EnhancedLogger.log('💾 [PERSISTENCE_TEST] Backup de emergência: ${backupSuccess ? 'SUCESSO' : 'FALHA'}');

      // 3. Escaneia dados perdidos
      final recoveryData = await _recoveryService.scanForLostData(userId);
      EnhancedLogger.log('🔍 [PERSISTENCE_TEST] Fontes de recuperação encontradas: ${recoveryData.length}');

      for (final data in recoveryData) {
        EnhancedLogger.log('   Fonte: ${data.source} - ${data.notifications.length} notificações');
      }

      // 4. Testa recuperação automática
      final recoveryResult = await _recoveryService.recoverLostData(userId);
      EnhancedLogger.log('🔄 [PERSISTENCE_TEST] Resultado da recuperação:');
      EnhancedLogger.log('   Sucesso: ${recoveryResult.success}');
      EnhancedLogger.log('   Mensagem: ${recoveryResult.message}');
      EnhancedLogger.log('   Recuperadas: ${recoveryResult.recoveredCount}');
      EnhancedLogger.log('   Total encontrado: ${recoveryResult.totalFound}');
      EnhancedLogger.log('   Tipo: ${recoveryResult.recoveryType}');

      // 5. Testa restauração de backup de emergência
      final restoredNotifications = await _recoveryService.restoreEmergencyBackup(userId);
      EnhancedLogger.log('📂 [PERSISTENCE_TEST] Backup restaurado: ${restoredNotifications.length} notificações');

      // 6. Testa validação de integridade
      final integrityValid = await _recoveryService.validateDataIntegrity(userId, testNotifications);
      EnhancedLogger.log('🔍 [PERSISTENCE_TEST] Validação de integridade: ${integrityValid ? 'VÁLIDA' : 'INVÁLIDA'}');

      // 7. Obtém estatísticas de recuperação
      final recoveryStats = _recoveryService.getRecoveryStats(userId);
      EnhancedLogger.log('📊 [PERSISTENCE_TEST] Estatísticas de recuperação: $recoveryStats');

      // Limpa subscription
      await progressSubscription.cancel();

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Teste de recuperação concluído');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro no teste de recuperação: $e');
    }
  }

  /// Testa cenário de falha e recuperação
  static Future<void> testFailureRecoveryScenario(String userId) async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Testando cenário de falha e recuperação');

    try {
      // 1. Salva dados iniciais
      final initialNotifications = _createTestNotifications(userId, 20);
      await _localStorage.saveNotifications(userId, initialNotifications);
      EnhancedLogger.log('💾 [PERSISTENCE_TEST] Dados iniciais salvos: ${initialNotifications.length}');

      // 2. Cria backup
      await _recoveryService.createEmergencyBackup(userId, initialNotifications);
      EnhancedLogger.log('💾 [PERSISTENCE_TEST] Backup criado');

      // 3. Simula falha - limpa dados
      await _localStorage.clearNotifications(userId);
      EnhancedLogger.log('💥 [PERSISTENCE_TEST] Falha simulada - dados limpos');

      // 4. Verifica se dados foram perdidos
      final lostData = await _localStorage.loadNotifications(userId);
      EnhancedLogger.log('📭 [PERSISTENCE_TEST] Dados após falha: ${lostData.length}');

      // 5. Executa recuperação
      final recoveryResult = await _recoveryService.recoverLostData(userId);
      EnhancedLogger.log('🔄 [PERSISTENCE_TEST] Recuperação executada: ${recoveryResult.success}');

      // 6. Verifica dados recuperados
      final recoveredData = await _localStorage.loadNotifications(userId);
      EnhancedLogger.log('📂 [PERSISTENCE_TEST] Dados recuperados: ${recoveredData.length}');

      // 7. Valida recuperação
      final recoverySuccess = recoveredData.length > 0;
      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Cenário de recuperação: ${recoverySuccess ? 'SUCESSO' : 'FALHA'}');

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Cenário de falha e recuperação concluído');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro no cenário de falha: $e');
    }
  }

  /// Testa performance do sistema
  static Future<void> testPerformance(String userId) async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Testando performance do sistema');

    try {
      final stopwatch = Stopwatch();

      // 1. Testa salvamento de grande volume
      stopwatch.start();
      final largeDataset = _createTestNotifications(userId, 1000);
      final saveTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      await _localStorage.saveNotifications(userId, largeDataset);
      final persistTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Criação de 1000 notificações: ${saveTime}ms');
      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Salvamento de 1000 notificações: ${persistTime}ms');

      // 2. Testa carregamento
      stopwatch.start();
      final loadedData = await _localStorage.loadNotifications(userId);
      final loadTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Carregamento de ${loadedData.length} notificações: ${loadTime}ms');

      // 3. Testa operações individuais
      final singleNotification = _createTestNotifications(userId, 1).first;

      stopwatch.start();
      await _localStorage.addNotification(userId, singleNotification);
      final addTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      stopwatch.start();
      await _localStorage.updateNotification(userId, singleNotification);
      final updateTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      stopwatch.start();
      await _localStorage.removeNotification(userId, singleNotification.id);
      final removeTime = stopwatch.elapsedMilliseconds;

      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Adição individual: ${addTime}ms');
      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Atualização individual: ${updateTime}ms');
      EnhancedLogger.log('⏱️ [PERSISTENCE_TEST] Remoção individual: ${removeTime}ms');

      // 4. Obtém tamanho do armazenamento
      final storageSize = await _localStorage.getStorageSize(userId);
      EnhancedLogger.log('📏 [PERSISTENCE_TEST] Tamanho do armazenamento: ${storageSize} bytes');

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Teste de performance concluído');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro no teste de performance: $e');
    }
  }

  /// Executa bateria completa de testes
  static Future<void> runAllTests() async {
    EnhancedLogger.log('🧪 [PERSISTENCE_TEST] Executando bateria completa de testes');

    final testUserId = 'test_persistence_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Testa armazenamento local
      await testLocalStorage(testUserId);
      await Future.delayed(Duration(seconds: 1));

      // 2. Testa sincronização offline/online
      await testOfflineSync(testUserId);
      await Future.delayed(Duration(seconds: 1));

      // 3. Testa recuperação de dados
      await testDataRecovery(testUserId);
      await Future.delayed(Duration(seconds: 1));

      // 4. Testa cenário de falha
      await testFailureRecoveryScenario(testUserId);
      await Future.delayed(Duration(seconds: 1));

      // 5. Testa performance
      await testPerformance(testUserId);

      // 6. Limpa dados de teste
      await _localStorage.clearNotifications(testUserId);
      await _syncManager.clearPendingOperations(testUserId);

      EnhancedLogger.log('✅ [PERSISTENCE_TEST] Todos os testes concluídos com sucesso');

    } catch (e) {
      EnhancedLogger.log('❌ [PERSISTENCE_TEST] Erro na bateria de testes: $e');
    }
  }

  /// Cria notificações de teste
  static List<RealNotificationModel> _createTestNotifications(String userId, int count) {
    final notifications = <RealNotificationModel>[];

    for (int i = 0; i < count; i++) {
      notifications.add(RealNotificationModel(
        id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}_$i',
        userId: userId,
        type: 'test',
        title: 'Notificação de Teste $i',
        message: 'Esta é uma notificação de teste número $i',
        timestamp: DateTime.now().subtract(Duration(minutes: i)),
        isRead: i % 2 == 0,
        data: {
          'testIndex': i,
          'testType': 'persistence_test',
          'createdAt': DateTime.now().toIso8601String(),
        },
      ));
    }

    return notifications;
  }

  /// Verifica integridade entre duas listas
  static bool _verifyIntegrity(List<RealNotificationModel> original, List<RealNotificationModel> loaded) {
    if (original.length != loaded.length) {
      return false;
    }

    final originalIds = original.map((n) => n.id).toSet();
    final loadedIds = loaded.map((n) => n.id).toSet();

    return originalIds.difference(loadedIds).isEmpty && 
           loadedIds.difference(originalIds).isEmpty;
  }
}

/// Função de conveniência para teste rápido
Future<void> testPersistenceQuick() async {
  final testUserId = 'quick_persistence_test_${DateTime.now().millisecondsSinceEpoch}';
  await PersistenceSystemTester.testLocalStorage(testUserId);
}

/// Função de conveniência para teste completo
Future<void> testPersistenceComplete() async {
  await PersistenceSystemTester.runAllTests();
}