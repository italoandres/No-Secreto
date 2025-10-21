import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/components/unified_notification_widget.dart';
import '../../lib/components/migration_control_widget.dart';
import '../../lib/services/unified_notification_interface.dart';
import '../../lib/services/ui_state_manager.dart';
import '../../lib/services/notification_sync_logger.dart';
import '../../lib/models/real_notification_model.dart';
import '../../lib/utils/enhanced_logger.dart';

/// Testes de integração de UI para validar sincronização visual
void main() {
  group('Notification UI Integration Tests', () {
    late UnifiedNotificationInterface unifiedInterface;
    late UIStateManager uiStateManager;
    late NotificationSyncLogger logger;
    late String testUserId;

    setUpAll(() {
      EnhancedLogger.log('🧪 [UI_INTEGRATION_TEST] Configurando testes de UI');
    });

    setUp(() {
      unifiedInterface = UnifiedNotificationInterface();
      uiStateManager = UIStateManager();
      logger = NotificationSyncLogger();
      testUserId = 'ui_test_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDown(() async {
      await unifiedInterface.clearCache(testUserId);
      uiStateManager.disposeUser(testUserId);
    });

    testWidgets('deve exibir notificações em tempo real', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Verifica estado inicial vazio
      expect(find.text('Nenhuma notificação'), findsOneWidget);

      // Act - Adiciona notificação
      final notification = _createTestNotification(testUserId, 0);
      await unifiedInterface.addNotification(testUserId, notification);
      
      // Aguarda atualização da UI
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));

      // Assert
      expect(find.text('Nenhuma notificação'), findsNothing);
      expect(find.text(notification.title), findsOneWidget);
      expect(find.text(notification.message), findsOneWidget);
    });

    testWidgets('deve mostrar indicador de loading durante sincronização', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Inicia sincronização
      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: true,
        syncStatus: SyncStatus.syncing,
        totalCount: 0,
        hasError: false,
      ));

      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sincronizando...'), findsOneWidget);
    });

    testWidgets('deve exibir erro quando sincronização falha', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Simula erro de sincronização
      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: false,
        syncStatus: SyncStatus.error,
        totalCount: 0,
        hasError: true,
        errorMessage: 'Erro de conexão',
      ));

      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Erro de conexão'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('deve permitir retry quando há erro', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Simula estado de erro
      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: false,
        syncStatus: SyncStatus.error,
        totalCount: 0,
        hasError: true,
        errorMessage: 'Falha na sincronização',
      ));

      await tester.pump();

      // Act - Toca no botão de retry
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      // Simula sucesso após retry
      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: false,
        syncStatus: SyncStatus.synced,
        totalCount: 1,
        hasError: false,
      ));

      final notification = _createTestNotification(testUserId, 0);
      await unifiedInterface.addNotification(testUserId, notification);
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error), findsNothing);
      expect(find.text(notification.title), findsOneWidget);
    });

    testWidgets('deve atualizar contador de notificações', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Adiciona múltiplas notificações
      for (int i = 0; i < 5; i++) {
        final notification = _createTestNotification(testUserId, i);
        await unifiedInterface.addNotification(testUserId, notification);
      }

      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: false,
        syncStatus: SyncStatus.synced,
        totalCount: 5,
        hasError: false,
      ));

      await tester.pump();

      // Assert
      expect(find.text('5 notificações'), findsOneWidget);
    });

    testWidgets('deve mostrar status de sincronização', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Testa diferentes status
      final statusTests = [
        (SyncStatus.idle, 'Aguardando'),
        (SyncStatus.syncing, 'Sincronizando'),
        (SyncStatus.synced, 'Sincronizado'),
        (SyncStatus.error, 'Erro'),
      ];

      for (final (status, expectedText) in statusTests) {
        uiStateManager.updateUIState(testUserId, UIState(
          isLoading: status == SyncStatus.syncing,
          syncStatus: status,
          totalCount: 0,
          hasError: status == SyncStatus.error,
        ));

        await tester.pump();

        // Assert
        expect(find.textContaining(expectedText), findsOneWidget);
      }
    });

    testWidgets('deve permitir força de sincronização', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Toca no botão de força de sincronização
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Simula início da sincronização
      uiStateManager.updateUIState(testUserId, UIState(
        isLoading: true,
        syncStatus: SyncStatus.syncing,
        totalCount: 0,
        hasError: false,
      ));

      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('deve exibir widget de controle de migração', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: MigrationControlWidget(userId: testUserId),
          ),
        ),
      );

      // Assert - Verifica elementos da interface
      expect(find.text('Migração de Sistema'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('deve permitir iniciar migração via UI', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: MigrationControlWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Toca no botão de iniciar migração
      await tester.tap(find.text('Iniciar Migração'));
      await tester.pump();

      // Assert - Verifica se mostra loading
      expect(find.text('Migrando...'), findsOneWidget);
    });

    testWidgets('deve mostrar detalhes da migração', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: MigrationControlWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Toca no botão de detalhes
      await tester.tap(find.text('Detalhes'));
      await tester.pump();

      // Assert - Verifica se abre dialog
      expect(find.text('Detalhes da Migração'), findsOneWidget);
      expect(find.text('Status:'), findsOneWidget);
    });

    testWidgets('deve atualizar UI quando dados mudam', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Estado inicial vazio
      expect(find.text('Nenhuma notificação'), findsOneWidget);

      // Act - Adiciona notificação
      final notification1 = _createTestNotification(testUserId, 0);
      await unifiedInterface.addNotification(testUserId, notification1);
      await tester.pump();

      // Assert - Verifica primeira notificação
      expect(find.text(notification1.title), findsOneWidget);

      // Act - Adiciona segunda notificação
      final notification2 = _createTestNotification(testUserId, 1);
      await unifiedInterface.addNotification(testUserId, notification2);
      await tester.pump();

      // Assert - Verifica ambas as notificações
      expect(find.text(notification1.title), findsOneWidget);
      expect(find.text(notification2.title), findsOneWidget);

      // Act - Remove primeira notificação
      await unifiedInterface.removeNotification(testUserId, notification1.id);
      await tester.pump();

      // Assert - Verifica que apenas segunda permanece
      expect(find.text(notification1.title), findsNothing);
      expect(find.text(notification2.title), findsOneWidget);
    });

    testWidgets('deve mostrar indicadores visuais corretos', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Adiciona notificação não lida
      final unreadNotification = _createTestNotification(testUserId, 0);
      unreadNotification.isRead = false;
      await unifiedInterface.addNotification(testUserId, unreadNotification);
      await tester.pump();

      // Assert - Verifica indicador de não lida
      expect(find.byIcon(Icons.circle), findsOneWidget); // Indicador de não lida

      // Act - Marca como lida
      unreadNotification.isRead = true;
      await unifiedInterface.updateNotification(testUserId, unreadNotification);
      await tester.pump();

      // Assert - Verifica que indicador mudou
      expect(find.byIcon(Icons.circle), findsNothing);
    });

    testWidgets('deve lidar com scroll em listas grandes', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Act - Adiciona muitas notificações
      for (int i = 0; i < 20; i++) {
        final notification = _createTestNotification(testUserId, i);
        await unifiedInterface.addNotification(testUserId, notification);
      }
      await tester.pump();

      // Assert - Verifica se lista é scrollável
      expect(find.byType(ListView), findsOneWidget);

      // Act - Testa scroll
      await tester.drag(find.byType(ListView), Offset(0, -300));
      await tester.pump();

      // Assert - Verifica que scroll funcionou (algumas notificações saíram de vista)
      expect(find.text('Notificação de Teste 0'), findsNothing);
      expect(find.text('Notificação de Teste 19'), findsOneWidget);
    });

    testWidgets('deve manter estado durante rotação de tela', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: UnifiedNotificationWidget(userId: testUserId),
          ),
        ),
      );

      // Adiciona notificações
      for (int i = 0; i < 3; i++) {
        final notification = _createTestNotification(testUserId, i);
        await unifiedInterface.addNotification(testUserId, notification);
      }
      await tester.pump();

      // Verifica estado inicial
      expect(find.text('Notificação de Teste 0'), findsOneWidget);
      expect(find.text('Notificação de Teste 1'), findsOneWidget);
      expect(find.text('Notificação de Teste 2'), findsOneWidget);

      // Act - Simula rotação de tela
      await tester.binding.setSurfaceSize(Size(800, 600)); // Landscape
      await tester.pump();

      // Assert - Verifica que dados persistem
      expect(find.text('Notificação de Teste 0'), findsOneWidget);
      expect(find.text('Notificação de Teste 1'), findsOneWidget);
      expect(find.text('Notificação de Teste 2'), findsOneWidget);

      // Restaura tamanho original
      await tester.binding.setSurfaceSize(Size(400, 800)); // Portrait
      await tester.pump();
    });
  });

  /// Cria uma notificação de teste
  RealNotificationModel _createTestNotification(String userId, int index) {
    return RealNotificationModel(
      id: 'ui_test_notification_$index',
      userId: userId,
      type: 'test',
      title: 'Notificação de Teste $index',
      message: 'Esta é uma mensagem de teste número $index',
      timestamp: DateTime.now().subtract(Duration(minutes: index)),
      isRead: index % 2 == 0,
      data: {
        'testIndex': index,
        'uiTest': true,
      },
    );
  }
}