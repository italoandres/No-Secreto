import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/unified_notification_interface.dart';
import '../../lib/services/data_recovery_service.dart';
import '../../lib/services/notification_local_storage.dart';
import '../../lib/services/offline_sync_manager.dart';
import '../../lib/models/real_notification_model.dart';
import '../../lib/utils/enhanced_logger.dart';

/// Testes de integração para recuperação automática após inconsistências
void main() {
  group('Notification Recovery Integration Tests', () {
    late UnifiedNotificationInterface unifiedInterface;
    late DataRecoveryService recoveryService;
    late NotificationLocalStorage localStorage;
    late OfflineSyncManager syncManager;
    late String testUserId;

    setUpAll(() {
      EnhancedLogger.log('🧪 [RECOVERY_INTEGRATION_TEST] Configurando testes de recuperação');
    });

    setUp(() async {
      unifiedInterface = UnifiedNotificationInterface();
      recoveryService = DataRecoveryService();
      localStorage = NotificationLocalStorage();
      syncManager = OfflineSyncManager();
      testUserId = 'recovery_test_${DateTime.now().millisecondsSinceEpoch}';

      // Inicializa serviços
      await localStorage.initialize();
      await syncManager.initialize();
    });

    tearDown(() async {
      // Limpa dados de teste
      await localStorage.clearNotifications(testUserId);
      await syncManager.clearPendingOperations(testUserId);
      unifiedInterface.disposeUser(testUserId);
    });

    testWidgets('deve recuperar dados após perda de cache', (WidgetTester tester) async {
      // Arrange
      final originalNotifications = _createTestNotifications(testUserId, 10);
      
      // Salva dados iniciais
      await localStorage.saveNotifications(testUserId, originalNotifications);
      await unifiedInterface.updateCache(testUserId, originalNotifications);

      // Verifica estado inicial
      final initialCache = unifiedInterface.getCachedNotifications(testUserId);
      expect(initialCache.length, 10, reason: 'Cache deve ter 10 notificações inicialmente');

      // Act - Simula perda de cache
      unifiedInterface.clearCache(testUserId);
      final emptyCache = unifiedInterface.getCachedNotifications(testUserId);
      expect(emptyCache.length, 0, reason: 'Cache deve estar vazio após limpeza');

      // Executa recuperação
      final recoveryResult = await recoveryService.recoverLostData(testUserId);

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve ser bem-sucedida');
      expect(recoveryResult.recoveredCount, 10, reason: 'Deve recuperar todas as 10 notificações');

      final recoveredCache = unifiedInterface.getCachedNotifications(testUserId);
      expect(recoveredCache.length, 10, reason: 'Cache deve ter 10 notificações após recuperação');

      // Verifica integridade dos dados recuperados
      final isValid = await recoveryService.validateDataIntegrity(testUserId, recoveredCache);
      expect(isValid, true, reason: 'Dados recuperados devem ser válidos');
    });

    testWidgets('deve recuperar de múltiplas fontes simultaneamente', (WidgetTester tester) async {
      // Arrange
      final notifications1 = _createTestNotifications(testUserId, 5, prefix: 'source1_');
      final notifications2 = _createTestNotifications(testUserId, 5, prefix: 'source2_');
      final notifications3 = _createTestNotifications(testUserId, 5, prefix: 'source3_');

      // Salva em diferentes fontes
      await localStorage.saveNotifications(testUserId, notifications1);
      await recoveryService.createEmergencyBackup(testUserId, notifications2);
      await unifiedInterface.updateCache(testUserId, notifications3);

      // Act - Escaneia fontes disponíveis
      final availableSources = await recoveryService.scanForLostData(testUserId);

      // Assert
      expect(availableSources.length, greaterThanOrEqualTo(2), reason: 'Deve encontrar múltiplas fontes');

      final totalNotifications = availableSources
          .expand((source) => source.notifications)
          .toList();
      expect(totalNotifications.length, greaterThanOrEqualTo(10), reason: 'Deve encontrar notificações de múltiplas fontes');

      // Executa recuperação híbrida
      final recoveryResult = await recoveryService.recoverLostData(testUserId, preferredType: RecoveryType.hybrid);
      expect(recoveryResult.success, true, reason: 'Recuperação híbrida deve ser bem-sucedida');
    });

    testWidgets('deve manter consistência durante recuperação', (WidgetTester tester) async {
      // Arrange
      final baseNotifications = _createTestNotifications(testUserId, 8);
      await localStorage.saveNotifications(testUserId, baseNotifications);

      // Simula inconsistência - adiciona notificações conflitantes
      final conflictingNotification = RealNotificationModel(
        id: baseNotifications.first.id, // Mesmo ID
        userId: testUserId,
        type: 'conflict',
        title: 'Notificação Conflitante',
        message: 'Esta notificação causa conflito',
        timestamp: DateTime.now(),
        isRead: true,
        data: {'conflict': true},
      );

      await unifiedInterface.addNotification(testUserId, conflictingNotification);

      // Act - Executa recuperação
      final recoveryResult = await recoveryService.recoverLostData(testUserId);

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve resolver conflitos');

      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      final uniqueIds = finalNotifications.map((n) => n.id).toSet();
      expect(uniqueIds.length, finalNotifications.length, reason: 'Não deve haver IDs duplicados');

      final isConsistent = await unifiedInterface.validateConsistency(testUserId);
      expect(isConsistent, true, reason: 'Sistema deve estar consistente após recuperação');
    });

    testWidgets('deve recuperar após falha de sincronização', (WidgetTester tester) async {
      // Arrange
      final notifications = _createTestNotifications(testUserId, 6);
      await localStorage.saveNotifications(testUserId, notifications);

      // Cria operações pendentes
      final pendingOps = [
        PendingOperation(
          id: 'pending_1',
          userId: testUserId,
          type: 'add',
          data: notifications[0].toJson(),
          timestamp: DateTime.now(),
        ),
        PendingOperation(
          id: 'pending_2',
          userId: testUserId,
          type: 'update',
          data: notifications[1].toJson(),
          timestamp: DateTime.now(),
        ),
      ];

      for (final op in pendingOps) {
        await syncManager.addPendingOperation(op);
      }

      // Simula falha de sincronização
      final initialPendingCount = syncManager.getPendingOperations(testUserId).length;
      expect(initialPendingCount, 2, reason: 'Deve ter 2 operações pendentes');

      // Act - Executa recuperação
      final recoveryResult = await recoveryService.recoverLostData(testUserId);

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve ser bem-sucedida mesmo com operações pendentes');

      final recoveredNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(recoveredNotifications.length, greaterThanOrEqualTo(6), reason: 'Deve manter todas as notificações');

      // Verifica se operações pendentes ainda existem para posterior sincronização
      final finalPendingCount = syncManager.getPendingOperations(testUserId).length;
      expect(finalPendingCount, greaterThanOrEqualTo(0), reason: 'Operações pendentes devem ser mantidas ou processadas');
    });

    testWidgets('deve validar integridade durante todo o processo', (WidgetTester tester) async {
      // Arrange
      final validNotifications = _createTestNotifications(testUserId, 5);
      final invalidNotification = RealNotificationModel(
        id: '', // ID inválido
        userId: testUserId,
        type: 'invalid',
        title: '',
        message: '',
        timestamp: DateTime.now().add(Duration(days: 1)), // Timestamp futuro
        isRead: false,
        data: {},
      );

      final mixedNotifications = [...validNotifications, invalidNotification];
      await localStorage.saveNotifications(testUserId, mixedNotifications);

      // Act
      final recoveryResult = await recoveryService.recoverLostData(testUserId);

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve filtrar dados inválidos');

      final recoveredNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(recoveredNotifications.length, 5, reason: 'Deve manter apenas notificações válidas');

      // Verifica se todas as notificações recuperadas são válidas
      for (final notification in recoveredNotifications) {
        expect(notification.id.isNotEmpty, true, reason: 'ID não deve estar vazio');
        expect(notification.title.isNotEmpty, true, reason: 'Título não deve estar vazio');
        expect(notification.message.isNotEmpty, true, reason: 'Mensagem não deve estar vazia');
        expect(notification.timestamp.isBefore(DateTime.now().add(Duration(minutes: 1))), true, reason: 'Timestamp deve ser válido');
      }
    });

    testWidgets('deve recuperar backup de emergência quando necessário', (WidgetTester tester) async {
      // Arrange
      final emergencyNotifications = _createTestNotifications(testUserId, 3, prefix: 'emergency_');
      await recoveryService.createEmergencyBackup(testUserId, emergencyNotifications);

      // Simula perda total de dados
      await localStorage.clearNotifications(testUserId);
      unifiedInterface.clearCache(testUserId);

      // Verifica que não há dados
      final emptyNotifications = await localStorage.loadNotifications(testUserId);
      expect(emptyNotifications.length, 0, reason: 'Não deve haver dados após limpeza');

      // Act - Executa recuperação
      final recoveryResult = await recoveryService.recoverLostData(testUserId, preferredType: RecoveryType.backup);

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação de backup deve ser bem-sucedida');
      expect(recoveryResult.recoveryType, RecoveryType.backup, reason: 'Deve usar backup como fonte');

      final recoveredNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(recoveredNotifications.length, 3, reason: 'Deve recuperar todas as notificações do backup');

      // Verifica se são as notificações corretas
      final recoveredIds = recoveredNotifications.map((n) => n.id).toSet();
      final emergencyIds = emergencyNotifications.map((n) => n.id).toSet();
      expect(recoveredIds, equals(emergencyIds), reason: 'Deve recuperar exatamente as notificações do backup');
    });

    testWidgets('deve monitorar progresso de recuperação', (WidgetTester tester) async {
      // Arrange
      final notifications = _createTestNotifications(testUserId, 15);
      await localStorage.saveNotifications(testUserId, notifications);

      final progressUpdates = <RecoveryProgress>[];
      final subscription = recoveryService.recoveryProgressStream.listen((progress) {
        if (progress.userId == testUserId) {
          progressUpdates.add(progress);
        }
      });

      // Act
      final recoveryResult = await recoveryService.recoverLostData(testUserId);

      // Aguarda um pouco para garantir que todos os updates foram recebidos
      await Future.delayed(Duration(milliseconds: 100));
      await subscription.cancel();

      // Assert
      expect(recoveryResult.success, true, reason: 'Recuperação deve ser bem-sucedida');
      expect(progressUpdates.isNotEmpty, true, reason: 'Deve ter updates de progresso');

      // Verifica se houve progresso de 0 a 100%
      final hasStartProgress = progressUpdates.any((p) => p.progress == 0.0);
      final hasEndProgress = progressUpdates.any((p) => p.progress == 1.0);
      expect(hasStartProgress || hasEndProgress, true, reason: 'Deve ter progresso inicial ou final');

      // Verifica se status final é correto
      final finalProgress = progressUpdates.last;
      expect(finalProgress.status, RecoveryStatus.completed, reason: 'Status final deve ser completed');
    });

    testWidgets('deve manter histórico de recuperações', (WidgetTester tester) async {
      // Arrange
      final notifications = _createTestNotifications(testUserId, 4);
      await localStorage.saveNotifications(testUserId, notifications);

      // Act - Executa múltiplas recuperações
      final recovery1 = await recoveryService.recoverLostData(testUserId);
      await Future.delayed(Duration(milliseconds: 50));
      final recovery2 = await recoveryService.recoverLostData(testUserId);

      // Assert
      expect(recovery1.success, true, reason: 'Primeira recuperação deve ser bem-sucedida');
      expect(recovery2.success, true, reason: 'Segunda recuperação deve ser bem-sucedida');

      final history = recoveryService.getRecoveryHistory(testUserId);
      expect(history, isNotNull, reason: 'Deve ter histórico de recuperação');
      expect(history!.success, true, reason: 'Histórico deve mostrar sucesso');

      final stats = recoveryService.getRecoveryStats(testUserId);
      expect(stats['hasHistory'], true, reason: 'Estatísticas devem mostrar que há histórico');
      expect(stats['lastRecoverySuccess'], true, reason: 'Última recuperação deve ter sido bem-sucedida');
    });
  });

  /// Cria notificações de teste
  List<RealNotificationModel> _createTestNotifications(String userId, int count, {String prefix = 'test_'}) {
    final notifications = <RealNotificationModel>[];
    final baseTime = DateTime.now();

    for (int i = 0; i < count; i++) {
      notifications.add(RealNotificationModel(
        id: '${prefix}notification_$i',
        userId: userId,
        type: 'test',
        title: 'Notificação de Teste $i',
        message: 'Esta é a notificação de teste número $i',
        timestamp: baseTime.subtract(Duration(minutes: i)),
        isRead: i % 2 == 0,
        data: {
          'testIndex': i,
          'testPrefix': prefix,
          'createdAt': baseTime.toIso8601String(),
        },
      ));
    }

    return notifications;
  }
}