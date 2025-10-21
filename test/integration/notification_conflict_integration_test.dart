import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/unified_notification_interface.dart';
import '../../lib/services/conflict_resolver.dart';
import '../../lib/services/notification_sync_logger.dart';
import '../../lib/models/real_notification_model.dart';
import '../../lib/utils/enhanced_logger.dart';

/// Testes de integração para cenários de conflito entre sistemas
void main() {
  group('Notification Conflict Integration Tests', () {
    late UnifiedNotificationInterface unifiedInterface;
    late ConflictResolver conflictResolver;
    late NotificationSyncLogger logger;
    late String testUserId;

    setUpAll(() {
      EnhancedLogger.log('🧪 [CONFLICT_INTEGRATION_TEST] Configurando testes de conflito');
    });

    setUp(() {
      unifiedInterface = UnifiedNotificationInterface();
      conflictResolver = ConflictResolver();
      logger = NotificationSyncLogger();
      testUserId = 'conflict_test_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDown(() async {
      // Limpa dados de teste
      await unifiedInterface.clearCache(testUserId);
      unifiedInterface.disposeUser(testUserId);
    });

    testWidgets('deve resolver conflitos de notificações duplicadas', (WidgetTester tester) async {
      // Arrange
      final notification1 = RealNotificationModel(
        id: 'conflict_notification_1',
        userId: testUserId,
        type: 'interest',
        title: 'Notificação Original',
        message: 'Mensagem original',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        isRead: false,
        data: {'source': 'system_a'},
      );

      final notification2 = RealNotificationModel(
        id: 'conflict_notification_1', // Mesmo ID
        userId: testUserId,
        type: 'interest',
        title: 'Notificação Atualizada',
        message: 'Mensagem atualizada',
        timestamp: DateTime.now(), // Mais recente
        isRead: true,
        data: {'source': 'system_b'},
      );

      // Act
      await unifiedInterface.addNotification(testUserId, notification1);
      await unifiedInterface.addNotification(testUserId, notification2);

      final conflicts = await conflictResolver.detectConflicts(testUserId);
      expect(conflicts.isNotEmpty, true, reason: 'Deve detectar conflitos');

      final resolvedNotifications = await conflictResolver.resolveConflicts(testUserId);

      // Assert
      expect(resolvedNotifications.length, 1, reason: 'Deve ter apenas uma notificação após resolução');
      expect(resolvedNotifications.first.title, 'Notificação Atualizada', reason: 'Deve manter a versão mais recente');
      expect(resolvedNotifications.first.isRead, true, reason: 'Deve manter o estado mais recente');

      logger.logUserAction(testUserId, 'Conflict resolution test completed');
    });

    testWidgets('deve lidar com conflitos de timestamp', (WidgetTester tester) async {
      // Arrange
      final baseTime = DateTime.now();
      final notifications = [
        RealNotificationModel(
          id: 'timestamp_conflict_1',
          userId: testUserId,
          type: 'match',
          title: 'Notificação 1',
          message: 'Primeira notificação',
          timestamp: baseTime.subtract(Duration(minutes: 10)),
          isRead: false,
          data: {'order': 1},
        ),
        RealNotificationModel(
          id: 'timestamp_conflict_2',
          userId: testUserId,
          type: 'match',
          title: 'Notificação 2',
          message: 'Segunda notificação',
          timestamp: baseTime.subtract(Duration(minutes: 5)),
          isRead: false,
          data: {'order': 2},
        ),
        RealNotificationModel(
          id: 'timestamp_conflict_3',
          userId: testUserId,
          type: 'match',
          title: 'Notificação 3',
          message: 'Terceira notificação',
          timestamp: baseTime,
          isRead: false,
          data: {'order': 3},
        ),
      ];

      // Act
      for (final notification in notifications) {
        await unifiedInterface.addNotification(testUserId, notification);
      }

      final sortedNotifications = await unifiedInterface.getNotifications(testUserId);

      // Assert
      expect(sortedNotifications.length, 3, reason: 'Deve ter todas as notificações');
      
      // Verifica se estão ordenadas por timestamp (mais recente primeiro)
      for (int i = 0; i < sortedNotifications.length - 1; i++) {
        expect(
          sortedNotifications[i].timestamp.isAfter(sortedNotifications[i + 1].timestamp) ||
          sortedNotifications[i].timestamp.isAtSameMomentAs(sortedNotifications[i + 1].timestamp),
          true,
          reason: 'Notificações devem estar ordenadas por timestamp',
        );
      }

      expect(sortedNotifications.first.data['order'], 3, reason: 'Primeira deve ser a mais recente');
      expect(sortedNotifications.last.data['order'], 1, reason: 'Última deve ser a mais antiga');
    });

    testWidgets('deve resolver conflitos de estado de leitura', (WidgetTester tester) async {
      // Arrange
      final notificationId = 'read_state_conflict';
      final unreadNotification = RealNotificationModel(
        id: notificationId,
        userId: testUserId,
        type: 'message',
        title: 'Notificação de Teste',
        message: 'Teste de estado de leitura',
        timestamp: DateTime.now().subtract(Duration(minutes: 1)),
        isRead: false,
        data: {'source': 'cache'},
      );

      final readNotification = RealNotificationModel(
        id: notificationId,
        userId: testUserId,
        type: 'message',
        title: 'Notificação de Teste',
        message: 'Teste de estado de leitura',
        timestamp: DateTime.now(),
        isRead: true,
        data: {'source': 'server'},
      );

      // Act
      await unifiedInterface.addNotification(testUserId, unreadNotification);
      await unifiedInterface.addNotification(testUserId, readNotification);

      final resolvedNotifications = await conflictResolver.resolveConflicts(testUserId);

      // Assert
      expect(resolvedNotifications.length, 1, reason: 'Deve ter apenas uma notificação');
      expect(resolvedNotifications.first.isRead, true, reason: 'Deve priorizar estado "lido"');
      expect(resolvedNotifications.first.data['source'], 'server', reason: 'Deve manter dados da versão mais recente');
    });

    testWidgets('deve detectar e resolver conflitos de dados inconsistentes', (WidgetTester tester) async {
      // Arrange
      final notifications = [
        RealNotificationModel(
          id: 'data_conflict_1',
          userId: testUserId,
          type: 'interest',
          title: 'Título Original',
          message: 'Mensagem original',
          timestamp: DateTime.now().subtract(Duration(minutes: 2)),
          isRead: false,
          data: {
            'interestId': 'interest_123',
            'profileName': 'João',
            'profileAge': 25,
          },
        ),
        RealNotificationModel(
          id: 'data_conflict_1', // Mesmo ID
          userId: testUserId,
          type: 'interest',
          title: 'Título Atualizado',
          message: 'Mensagem atualizada',
          timestamp: DateTime.now(),
          isRead: false,
          data: {
            'interestId': 'interest_123',
            'profileName': 'João Silva', // Nome completo
            'profileAge': 26, // Idade atualizada
            'profilePhoto': 'photo_url', // Novo campo
          },
        ),
      ];

      // Act
      for (final notification in notifications) {
        await unifiedInterface.addNotification(testUserId, notification);
      }

      final conflicts = await conflictResolver.detectConflicts(testUserId);
      final resolvedNotifications = await conflictResolver.resolveConflicts(testUserId);

      // Assert
      expect(conflicts.isNotEmpty, true, reason: 'Deve detectar conflitos de dados');
      expect(resolvedNotifications.length, 1, reason: 'Deve resolver para uma notificação');
      
      final resolved = resolvedNotifications.first;
      expect(resolved.title, 'Título Atualizado', reason: 'Deve usar título mais recente');
      expect(resolved.data['profileName'], 'João Silva', reason: 'Deve usar nome mais completo');
      expect(resolved.data['profileAge'], 26, reason: 'Deve usar idade mais recente');
      expect(resolved.data['profilePhoto'], 'photo_url', reason: 'Deve incluir novos campos');
    });

    testWidgets('deve lidar com múltiplos conflitos simultâneos', (WidgetTester tester) async {
      // Arrange
      final baseTime = DateTime.now();
      final conflictingNotifications = <RealNotificationModel>[];

      // Cria múltiplas versões de várias notificações
      for (int i = 1; i <= 3; i++) {
        for (int version = 1; version <= 3; version++) {
          conflictingNotifications.add(RealNotificationModel(
            id: 'multi_conflict_$i',
            userId: testUserId,
            type: 'test',
            title: 'Notificação $i - Versão $version',
            message: 'Mensagem da versão $version',
            timestamp: baseTime.subtract(Duration(minutes: 10 - version)),
            isRead: version == 3, // Última versão está lida
            data: {
              'version': version,
              'priority': version * 10,
            },
          ));
        }
      }

      // Act
      for (final notification in conflictingNotifications) {
        await unifiedInterface.addNotification(testUserId, notification);
      }

      final conflicts = await conflictResolver.detectConflicts(testUserId);
      final resolvedNotifications = await conflictResolver.resolveConflicts(testUserId);

      // Assert
      expect(conflicts.length, 3, reason: 'Deve detectar 3 grupos de conflitos');
      expect(resolvedNotifications.length, 3, reason: 'Deve resolver para 3 notificações únicas');

      // Verifica se cada notificação resolvida é a versão mais recente
      for (final resolved in resolvedNotifications) {
        expect(resolved.data['version'], 3, reason: 'Deve manter a versão mais recente');
        expect(resolved.isRead, true, reason: 'Deve manter o estado mais recente');
        expect(resolved.title.contains('Versão 3'), true, reason: 'Deve ter o título da versão mais recente');
      }
    });

    testWidgets('deve validar consistência após resolução de conflitos', (WidgetTester tester) async {
      // Arrange
      final notifications = [
        RealNotificationModel(
          id: 'consistency_test_1',
          userId: testUserId,
          type: 'match',
          title: 'Match com Ana',
          message: 'Você tem um novo match!',
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
          isRead: false,
          data: {'matchId': 'match_123', 'profileId': 'profile_456'},
        ),
        RealNotificationModel(
          id: 'consistency_test_1', // Conflito
          userId: testUserId,
          type: 'match',
          title: 'Match com Ana Silva',
          message: 'Você tem um novo match com Ana!',
          timestamp: DateTime.now(),
          isRead: true,
          data: {'matchId': 'match_123', 'profileId': 'profile_456', 'profilePhoto': 'photo.jpg'},
        ),
      ];

      // Act
      for (final notification in notifications) {
        await unifiedInterface.addNotification(testUserId, notification);
      }

      await conflictResolver.resolveConflicts(testUserId);
      final isConsistent = await unifiedInterface.validateConsistency(testUserId);

      // Assert
      expect(isConsistent, true, reason: 'Sistema deve estar consistente após resolução');

      final finalNotifications = await unifiedInterface.getNotifications(testUserId);
      expect(finalNotifications.length, 1, reason: 'Deve ter apenas uma notificação');

      final resolved = finalNotifications.first;
      expect(resolved.id, 'consistency_test_1', reason: 'ID deve ser mantido');
      expect(resolved.data['matchId'], 'match_123', reason: 'Dados essenciais devem ser preservados');
      expect(resolved.data['profilePhoto'], 'photo.jpg', reason: 'Novos dados devem ser incluídos');
    });

    testWidgets('deve manter log detalhado de resolução de conflitos', (WidgetTester tester) async {
      // Arrange
      final notification1 = RealNotificationModel(
        id: 'log_test_notification',
        userId: testUserId,
        type: 'interest',
        title: 'Título Original',
        message: 'Mensagem original',
        timestamp: DateTime.now().subtract(Duration(minutes: 1)),
        isRead: false,
        data: {'source': 'system_a'},
      );

      final notification2 = RealNotificationModel(
        id: 'log_test_notification',
        userId: testUserId,
        type: 'interest',
        title: 'Título Atualizado',
        message: 'Mensagem atualizada',
        timestamp: DateTime.now(),
        isRead: true,
        data: {'source': 'system_b'},
      );

      // Act
      await unifiedInterface.addNotification(testUserId, notification1);
      await unifiedInterface.addNotification(testUserId, notification2);

      final conflicts = await conflictResolver.detectConflicts(testUserId);
      await conflictResolver.resolveConflicts(testUserId);

      // Assert
      expect(conflicts.isNotEmpty, true, reason: 'Deve ter detectado conflitos');

      // Verifica se logs foram criados
      final logs = logger.getLogsForUser(testUserId);
      expect(logs.isNotEmpty, true, reason: 'Deve ter logs de resolução');

      final conflictLogs = logs.where((log) => log.action.contains('conflict')).toList();
      expect(conflictLogs.isNotEmpty, true, reason: 'Deve ter logs específicos de conflito');
    });

    testWidgets('deve recuperar automaticamente após falha na resolução', (WidgetTester tester) async {
      // Arrange
      final validNotification = RealNotificationModel(
        id: 'recovery_test_valid',
        userId: testUserId,
        type: 'message',
        title: 'Notificação Válida',
        message: 'Esta notificação é válida',
        timestamp: DateTime.now(),
        isRead: false,
        data: {'valid': true},
      );

      // Act
      await unifiedInterface.addNotification(testUserId, validNotification);

      // Simula falha e recuperação
      try {
        await conflictResolver.resolveConflicts(testUserId);
      } catch (e) {
        // Falha esperada em alguns casos
      }

      // Verifica se sistema ainda funciona
      final notifications = await unifiedInterface.getNotifications(testUserId);
      final isConsistent = await unifiedInterface.validateConsistency(testUserId);

      // Assert
      expect(notifications.isNotEmpty, true, reason: 'Deve manter notificações válidas');
      expect(isConsistent, true, reason: 'Sistema deve se recuperar e manter consistência');
    });
  });
}