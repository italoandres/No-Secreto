import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'dart:math';
import '../../lib/services/unified_notification_interface.dart';
import '../../lib/services/notification_local_storage.dart';
import '../../lib/services/offline_sync_manager.dart';
import '../../lib/services/data_recovery_service.dart';
import '../../lib/models/real_notification_model.dart';
import '../../lib/utils/enhanced_logger.dart';

/// Testes de integração de stress com múltiplas requisições simultâneas
void main() {
  group('Notification Stress Integration Tests', () {
    late UnifiedNotificationInterface unifiedInterface;
    late NotificationLocalStorage localStorage;
    late OfflineSyncManager syncManager;
    late DataRecoveryService recoveryService;
    late String testUserId;

    setUpAll(() {
      EnhancedLogger.log('🧪 [STRESS_INTEGRATION_TEST] Configurando testes de stress');
    });

    setUp(() async {
      unifiedInterface = UnifiedNotificationInterface();
      localStorage = NotificationLocalStorage();
      syncManager = OfflineSyncManager();
      recoveryService = DataRecoveryService();
      testUserId = 'stress_test_${DateTime.now().millisecondsSinceEpoch}';

      await localStorage.initialize();
      await syncManager.initialize();
    });

    tearDown(() async {
      await localStorage.clearNotifications(testUserId);
      await syncManager.clearPendingOperations(testUserId);
      unifiedInterface.disposeUser(testUserId);
    });

    testWidgets('deve lidar com múltiplas adições simultâneas', (WidgetTester tester) async {
      // Arrange
      const int concurrentOperations = 50;
      final futures = <Future<void>>[];
      final addedNotifications = <RealNotificationModel>[];

      // Act - Executa múltiplas adições simultaneamente
      for (int i = 0; i < concurrentOperations; i++) {
        final notification = _createTestNotification(testUserId, i);
        addedNotifications.add(notification);
        
        futures.add(unifiedInterface.addNotification(testUserId, notification));
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      // Assert
      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(finalNotifications.length, concurrentOperations, reason: 'Deve ter todas as notificações adicionadas');

      // Verifica integridade
      final uniqueIds = finalNotifications.map((n) => n.id).toSet();
      expect(uniqueIds.length, concurrentOperations, reason: 'Todos os IDs devem ser únicos');

      // Verifica performance
      final avgTimePerOperation = stopwatch.elapsedMilliseconds / concurrentOperations;
      expect(avgTimePerOperation, lessThan(100), reason: 'Tempo médio por operação deve ser < 100ms');

      EnhancedLogger.log('⏱️ [STRESS_TEST] $concurrentOperations adições em ${stopwatch.elapsedMilliseconds}ms (${avgTimePerOperation.toStringAsFixed(2)}ms/op)');
    });

    testWidgets('deve lidar com operações mistas simultâneas', (WidgetTester tester) async {
      // Arrange
      const int totalOperations = 100;
      final futures = <Future<void>>[];
      final random = Random();

      // Adiciona algumas notificações iniciais
      final initialNotifications = <RealNotificationModel>[];
      for (int i = 0; i < 20; i++) {
        final notification = _createTestNotification(testUserId, i);
        initialNotifications.add(notification);
        await unifiedInterface.addNotification(testUserId, notification);
      }

      // Act - Executa operações mistas simultaneamente
      for (int i = 0; i < totalOperations; i++) {
        final operationType = random.nextInt(4);
        
        switch (operationType) {
          case 0: // Adicionar
            final notification = _createTestNotification(testUserId, 1000 + i);
            futures.add(unifiedInterface.addNotification(testUserId, notification));
            break;
            
          case 1: // Atualizar
            if (initialNotifications.isNotEmpty) {
              final notification = initialNotifications[random.nextInt(initialNotifications.length)];
              notification.message = 'Mensagem atualizada $i';
              notification.isRead = !notification.isRead;
              futures.add(unifiedInterface.updateNotification(testUserId, notification));
            }
            break;
            
          case 2: // Remover
            if (initialNotifications.isNotEmpty && random.nextBool()) {
              final notification = initialNotifications.removeAt(0);
              futures.add(unifiedInterface.removeNotification(testUserId, notification.id));
            }
            break;
            
          case 3: // Consultar
            futures.add(unifiedInterface.getNotifications(testUserId).then((_) {}));
            break;
        }
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      // Assert
      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(finalNotifications.isNotEmpty, true, reason: 'Deve ter notificações após operações mistas');

      // Verifica consistência
      final isConsistent = await unifiedInterface.validateConsistency(testUserId);
      expect(isConsistent, true, reason: 'Sistema deve manter consistência após operações simultâneas');

      EnhancedLogger.log('⏱️ [STRESS_TEST] $totalOperations operações mistas em ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('deve lidar com múltiplos usuários simultâneos', (WidgetTester tester) async {
      // Arrange
      const int userCount = 10;
      const int notificationsPerUser = 20;
      final userIds = List.generate(userCount, (i) => 'stress_user_$i');
      final futures = <Future<void>>[];

      // Act - Executa operações para múltiplos usuários simultaneamente
      for (final userId in userIds) {
        for (int i = 0; i < notificationsPerUser; i++) {
          final notification = _createTestNotification(userId, i);
          futures.add(unifiedInterface.addNotification(userId, notification));
        }
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      // Assert
      for (final userId in userIds) {
        final userNotifications = await unifiedInterface.getNotifications(userId);
        expect(userNotifications.length, notificationsPerUser, reason: 'Cada usuário deve ter $notificationsPerUser notificações');
        
        // Verifica se todas as notificações pertencem ao usuário correto
        for (final notification in userNotifications) {
          expect(notification.userId, userId, reason: 'Notificação deve pertencer ao usuário correto');
        }
      }

      final totalOperations = userCount * notificationsPerUser;
      final avgTimePerOperation = stopwatch.elapsedMilliseconds / totalOperations;
      expect(avgTimePerOperation, lessThan(50), reason: 'Tempo médio por operação deve ser < 50ms');

      EnhancedLogger.log('⏱️ [STRESS_TEST] $totalOperations operações para $userCount usuários em ${stopwatch.elapsedMilliseconds}ms');

      // Limpa dados de teste
      for (final userId in userIds) {
        await localStorage.clearNotifications(userId);
        unifiedInterface.disposeUser(userId);
      }
    });

    testWidgets('deve manter performance com grande volume de dados', (WidgetTester tester) async {
      // Arrange
      const int largeDatasetSize = 1000;
      final notifications = <RealNotificationModel>[];

      for (int i = 0; i < largeDatasetSize; i++) {
        notifications.add(_createTestNotification(testUserId, i));
      }

      // Act - Adiciona grande volume de dados
      final addStopwatch = Stopwatch()..start();
      await localStorage.saveNotifications(testUserId, notifications);
      addStopwatch.stop();

      // Testa consultas com grande volume
      final queryStopwatch = Stopwatch()..start();
      final loadedNotifications = await localStorage.loadNotifications(testUserId);
      queryStopwatch.stop();

      // Testa operações individuais com grande volume
      final individualStopwatch = Stopwatch()..start();
      final newNotification = _createTestNotification(testUserId, largeDatasetSize);
      await localStorage.addNotification(testUserId, newNotification);
      individualStopwatch.stop();

      // Assert
      expect(loadedNotifications.length, largeDatasetSize, reason: 'Deve carregar todos os dados');
      expect(addStopwatch.elapsedMilliseconds, lessThan(5000), reason: 'Salvamento deve ser < 5s');
      expect(queryStopwatch.elapsedMilliseconds, lessThan(2000), reason: 'Carregamento deve ser < 2s');
      expect(individualStopwatch.elapsedMilliseconds, lessThan(500), reason: 'Operação individual deve ser < 500ms');

      EnhancedLogger.log('⏱️ [STRESS_TEST] Performance com $largeDatasetSize notificações:');
      EnhancedLogger.log('   Salvamento: ${addStopwatch.elapsedMilliseconds}ms');
      EnhancedLogger.log('   Carregamento: ${queryStopwatch.elapsedMilliseconds}ms');
      EnhancedLogger.log('   Operação individual: ${individualStopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('deve lidar com sincronização sob stress', (WidgetTester tester) async {
      // Arrange
      const int operationCount = 30;
      final pendingOperations = <PendingOperation>[];

      for (int i = 0; i < operationCount; i++) {
        final notification = _createTestNotification(testUserId, i);
        pendingOperations.add(PendingOperation(
          id: 'stress_op_$i',
          userId: testUserId,
          type: i % 3 == 0 ? 'add' : (i % 3 == 1 ? 'update' : 'delete'),
          data: notification.toJson(),
          timestamp: DateTime.now(),
        ));
      }

      // Act - Adiciona operações pendentes simultaneamente
      final futures = pendingOperations.map((op) => syncManager.addPendingOperation(op)).toList();
      await Future.wait(futures);

      // Executa sincronização
      final syncStopwatch = Stopwatch()..start();
      final syncResult = await syncManager.syncNotifications(testUserId);
      syncStopwatch.stop();

      // Assert
      expect(syncResult.success, true, reason: 'Sincronização deve ser bem-sucedida');
      expect(syncStopwatch.elapsedMilliseconds, lessThan(10000), reason: 'Sincronização deve ser < 10s');

      final remainingOperations = syncManager.getPendingOperations(testUserId);
      expect(remainingOperations.length, lessThanOrEqualTo(operationCount), reason: 'Operações devem ser processadas ou mantidas');

      EnhancedLogger.log('⏱️ [STRESS_TEST] Sincronização de $operationCount operações em ${syncStopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('deve recuperar dados sob condições de stress', (WidgetTester tester) async {
      // Arrange
      const int datasetSize = 200;
      final notifications = List.generate(datasetSize, (i) => _createTestNotification(testUserId, i));

      // Salva dados em múltiplas fontes
      await localStorage.saveNotifications(testUserId, notifications.take(100).toList());
      await recoveryService.createEmergencyBackup(testUserId, notifications.skip(50).take(100).toList());
      await unifiedInterface.updateCache(testUserId, notifications.skip(100).toList());

      // Simula perda de dados
      await localStorage.clearNotifications(testUserId);
      unifiedInterface.clearCache(testUserId);

      // Act - Executa recuperação sob stress
      final recoveryStopwatch = Stopwatch()..start();
      final recoveryResult = await recoveryService.recoverLostData(testUserId);
      recoveryStopwatch.stop();

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve ser bem-sucedida');
      expect(recoveryResult.recoveredCount, greaterThan(0), reason: 'Deve recuperar dados');
      expect(recoveryStopwatch.elapsedMilliseconds, lessThan(5000), reason: 'Recuperação deve ser < 5s');

      final recoveredNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(recoveredNotifications.isNotEmpty, true, reason: 'Deve ter dados recuperados');

      EnhancedLogger.log('⏱️ [STRESS_TEST] Recuperação de ${recoveryResult.recoveredCount} notificações em ${recoveryStopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('deve manter estabilidade durante operações contínuas', (WidgetTester tester) async {
      // Arrange
      const int duration = 5; // segundos
      const int operationsPerSecond = 20;
      final futures = <Future<void>>[];
      var operationCount = 0;

      final timer = Timer.periodic(Duration(milliseconds: 50), (timer) async {
        if (timer.tick * 50 >= duration * 1000) {
          timer.cancel();
          return;
        }

        // Executa operações contínuas
        for (int i = 0; i < operationsPerSecond ~/ 20; i++) {
          final notification = _createTestNotification(testUserId, operationCount++);
          futures.add(unifiedInterface.addNotification(testUserId, notification));
        }
      });

      // Act - Aguarda conclusão das operações contínuas
      await Future.delayed(Duration(seconds: duration + 1));
      await Future.wait(futures);

      // Assert
      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(finalNotifications.length, operationCount, reason: 'Deve ter todas as notificações adicionadas');

      // Verifica estabilidade do sistema
      final isConsistent = await unifiedInterface.validateConsistency(testUserId);
      expect(isConsistent, true, reason: 'Sistema deve manter consistência após operações contínuas');

      // Verifica se não há vazamentos de memória (teste básico)
      final stats = await localStorage.getStorageStats(testUserId);
      expect(stats['notificationsCount'], operationCount, reason: 'Contagem deve estar correta');

      EnhancedLogger.log('⏱️ [STRESS_TEST] $operationCount operações contínuas em ${duration}s mantiveram estabilidade');
    });

    testWidgets('deve lidar com falhas simultâneas e recuperação', (WidgetTester tester) async {
      // Arrange
      const int operationCount = 50;
      final notifications = List.generate(operationCount, (i) => _createTestNotification(testUserId, i));
      
      // Adiciona dados iniciais
      await localStorage.saveNotifications(testUserId, notifications);

      // Act - Simula múltiplas falhas simultâneas
      final failureFutures = <Future<void>>[];
      
      // Simula falhas de cache
      failureFutures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 100));
        unifiedInterface.clearCache(testUserId);
      }));

      // Simula falhas de armazenamento
      failureFutures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 200));
        await localStorage.clearNotifications(testUserId);
      }));

      // Executa recuperações simultâneas
      failureFutures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 300));
        await recoveryService.recoverLostData(testUserId);
      }));

      failureFutures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 400));
        await recoveryService.recoverLostData(testUserId);
      }));

      await Future.wait(failureFutures);

      // Assert
      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(finalNotifications.isNotEmpty, true, reason: 'Deve ter recuperado dados após falhas');

      final isConsistent = await unifiedInterface.validateConsistency(testUserId);
      expect(isConsistent, true, reason: 'Sistema deve estar consistente após falhas e recuperações');

      EnhancedLogger.log('✅ [STRESS_TEST] Sistema manteve estabilidade após múltiplas falhas simultâneas');
    });
  });

  /// Cria uma notificação de teste
  RealNotificationModel _createTestNotification(String userId, int index) {
    return RealNotificationModel(
      id: 'stress_notification_${userId}_$index',
      userId: userId,
      type: 'stress_test',
      title: 'Notificação de Stress $index',
      message: 'Esta é uma notificação de teste de stress número $index',
      timestamp: DateTime.now().subtract(Duration(seconds: index)),
      isRead: index % 3 == 0,
      data: {
        'stressIndex': index,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'testType': 'stress',
      },
    );
  }
}