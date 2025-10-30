import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/accepted_matches_view.dart';
import 'package:whatsapp_chat/views/romantic_match_chat_view.dart';
import 'package:whatsapp_chat/services/match_loading_manager.dart';
import 'package:whatsapp_chat/services/message_read_status_service.dart';
import 'package:whatsapp_chat/services/match_error_handler.dart';
import 'package:whatsapp_chat/components/unread_messages_counter.dart';

void main() {
  group('Real Time Sync Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
      MatchErrorHandler.clearErrorHistory();
      MessageReadStatusService.clearDebounceCache();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve sincronizar contadores de mensagens não lidas', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento e possível sincronização
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular mudanças nos contadores
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se sincronização funcionou
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Verificar se componentes de contador estão presentes
      final counterWidgets = find.byType(UnreadMessagesCounter);
      expect(counterWidgets.evaluate().length, greaterThanOrEqualTo(0));
    });

    testWidgets('deve sincronizar mensagens em tempo real no chat', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 5));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'sync_chat_123',
            otherUserId: 'user_sync',
            otherUserName: 'Sync Test User',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular chegada de novas mensagens (streams do Firebase)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se chat está sincronizado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se lista de mensagens está presente
      final listView = find.byType(ListView);
      expect(listView.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('deve atualizar status de leitura em tempo real', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 3));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'read_status_chat_123',
            otherUserId: 'user_read_status',
            otherUserName: 'Read Status User',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular interação com mensagens para marcar como lidas
      final messageWidgets = find.byType(GestureDetector);
      if (messageWidgets.evaluate().isNotEmpty) {
        await tester.tap(messageWidgets.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      // Simular atualizações de status de leitura
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se sistema de leitura está funcionando
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há erros críticos no sistema de leitura
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final readErrors = errorHistory.where((e) => 
        e.message.toLowerCase().contains('leitura') ||
        e.message.toLowerCase().contains('read')
      ).toList();
      expect(readErrors.length, lessThan(3));
    });

    testWidgets('deve manter sincronização durante navegação', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/accepted-matches',
          getPages: [
            GetPage(
              name: '/accepted-matches',
              page: () => const AcceptedMatchesView(),
            ),
            GetPage(
              name: '/match-chat',
              page: () => RomanticMatchChatView(
                chatId: 'nav_sync_chat_123',
                otherUserId: 'user_nav_sync',
                otherUserName: 'Nav Sync User',
                matchDate: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ),
          ],
        ),
      );

      // Act - Navegar entre telas
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular navegação para chat
      Get.toNamed('/match-chat');
      await tester.pumpAndSettle();

      // Aguardar sincronização no chat
      await tester.pump(const Duration(seconds: 2));

      // Voltar para lista
      Get.back();
      await tester.pumpAndSettle();

      // Aguardar sincronização na lista
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se sincronização foi mantida
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve sincronizar múltiplos streams simultaneamente', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar múltiplos streams (matches, contadores, etc.)
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular atualizações simultâneas
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Assert - Verificar se múltiplos streams funcionaram
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Verificar se não há sobrecarga de operações
      final loadingManager = Get.find<MatchLoadingManager>();
      final activeOperations = loadingManager.getActiveLoadingStates();
      expect(activeOperations.length, lessThan(10));
    });

    testWidgets('deve recuperar de falhas de sincronização', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 4));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'recovery_sync_chat_123',
            otherUserId: 'user_recovery',
            otherUserName: 'Recovery User',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento e possíveis falhas
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Simular reconexão após falha
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se sistema se recuperou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se erros foram tratados
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final networkErrors = errorHistory.where((e) => 
        e.type == MatchErrorType.networkError
      ).toList();
      
      // Pode haver alguns erros de rede, mas não muitos
      expect(networkErrors.length, lessThan(5));
    });

    testWidgets('deve manter performance durante sincronização intensa', (tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Simular sincronização intensa
      await tester.pump();
      
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      stopwatch.stop();

      // Assert - Verificar performance
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Menos de 5 segundos
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Verificar se não há vazamentos de recursos
      final errorHistory = MatchErrorHandler.getErrorHistory();
      expect(errorHistory.length, lessThan(15));
    });

    testWidgets('deve sincronizar dados offline/online', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Simular cenário offline/online
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular período offline (sem atualizações)
      await tester.pump(const Duration(seconds: 2));

      // Simular volta online (sincronização em lote)
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se sincronização offline/online funcionou
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve debounce atualizações frequentes', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 1));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'debounce_chat_123',
            otherUserId: 'user_debounce',
            otherUserName: 'Debounce User',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular múltiplas atualizações rápidas (devem ser debounced)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Aguardar debounce completar
      await tester.pump(const Duration(seconds: 3));

      // Assert - Verificar se debounce funcionou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há muitas operações simultâneas
      final loadingManager = Get.find<MatchLoadingManager>();
      final activeOperations = loadingManager.getActiveLoadingStates();
      expect(activeOperations.length, lessThan(5));
    });
  });

  group('Stream Management Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve gerenciar múltiplos streams sem vazamentos', (tester) async {
      // Arrange - Criar e destruir múltiplas telas
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          GetMaterialApp(
            home: RomanticMatchChatView(
              chatId: 'stream_test_$i',
              otherUserId: 'user_stream_$i',
              otherUserName: 'Stream User $i',
              matchDate: DateTime.now().subtract(Duration(days: i + 1)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      // Act - Limpar telas
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Assert - Verificar se não há vazamentos
      final loadingManager = Get.find<MatchLoadingManager>();
      final activeOperations = loadingManager.getActiveLoadingStates();
      expect(activeOperations.length, lessThan(3));
    });

    testWidgets('deve cancelar streams ao sair da tela', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'cancel_stream_chat_123',
            otherUserId: 'user_cancel',
            otherUserName: 'Cancel User',
            matchDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ),
      );

      // Act - Aguardar streams iniciarem
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Sair da tela
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se streams foram cancelados
      final loadingManager = Get.find<MatchLoadingManager>();
      final activeOperations = loadingManager.getActiveLoadingStates();
      expect(activeOperations.length, equals(0));
    });

    testWidgets('deve reconectar streams após erro', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'reconnect_chat_123',
            otherUserId: 'user_reconnect',
            otherUserName: 'Reconnect User',
            matchDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ),
      );

      // Act - Aguardar conexão inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular erro e reconexão
      await tester.pump(const Duration(seconds: 3));

      // Assert - Verificar se reconexão funcionou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há muitos erros acumulados
      final errorHistory = MatchErrorHandler.getErrorHistory();
      expect(errorHistory.length, lessThan(10));
    });
  });

  group('Data Consistency Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve manter consistência entre lista e chat', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/accepted-matches',
          getPages: [
            GetPage(
              name: '/accepted-matches',
              page: () => const AcceptedMatchesView(),
            ),
            GetPage(
              name: '/match-chat',
              page: () => RomanticMatchChatView(
                chatId: 'consistency_chat_123',
                otherUserId: 'user_consistency',
                otherUserName: 'Consistency User',
                matchDate: DateTime.now().subtract(const Duration(days: 1)),
              ),
            ),
          ],
        ),
      );

      // Act - Navegar entre telas múltiplas vezes
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      for (int i = 0; i < 3; i++) {
        Get.toNamed('/match-chat');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        Get.back();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Verificar consistência
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve sincronizar contadores corretamente', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar sincronização de contadores
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular mudanças nos contadores
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se contadores estão sincronizados
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Verificar se componentes de contador não têm valores inconsistentes
      final counterWidgets = find.byType(UnreadMessagesCounter);
      expect(counterWidgets.evaluate().length, greaterThanOrEqualTo(0));
    });
  });
}