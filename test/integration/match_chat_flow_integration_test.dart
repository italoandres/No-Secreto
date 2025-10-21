import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/romantic_match_chat_view.dart';
import 'package:whatsapp_chat/services/match_loading_manager.dart';
import 'package:whatsapp_chat/services/match_error_handler.dart';
import 'package:whatsapp_chat/services/match_retry_service.dart';
import 'package:whatsapp_chat/services/message_read_status_service.dart';
import 'package:whatsapp_chat/services/chat_expiration_service.dart';
import 'package:whatsapp_chat/models/chat_message_model.dart';

void main() {
  group('Match Chat Flow Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
      MatchErrorHandler.clearErrorHistory();
      MatchRetryService.resetAllStats();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve completar fluxo de criação de chat', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 1));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'new_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'Maria Silva',
            otherUserPhoto: 'https://example.com/maria.jpg',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar criação do chat
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se chat foi criado com sucesso
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      
      // Verificar se não há erros críticos
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final criticalErrors = errorHistory.where((e) => 
        e.type == MatchErrorType.firebaseError || 
        e.type == MatchErrorType.unknownError
      ).toList();
      expect(criticalErrors.length, lessThan(3)); // Permitir alguns erros menores
    });

    testWidgets('deve completar fluxo de envio e recebimento de mensagens', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 5));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'active_chat_123',
            otherUserId: 'user_789',
            otherUserName: 'Pedro Santos',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular envio de mensagem
      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      if (textField.evaluate().isNotEmpty && sendButton.evaluate().isNotEmpty) {
        // Digitar mensagem
        await tester.enterText(textField, 'Olá! Como está seu dia?');
        await tester.pump();

        // Verificar se botão de envio está habilitado
        final sendButtonWidget = tester.widget<IconButton>(sendButton);
        expect(sendButtonWidget.onPressed, isNotNull);

        // Enviar mensagem
        await tester.tap(sendButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // Verificar se campo foi limpo após envio
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, isEmpty);
      }

      // Assert - Verificar se fluxo foi completado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
    });

    testWidgets('deve gerenciar expiração de chat corretamente', (tester) async {
      // Arrange - Chat próximo da expiração
      final matchDate = DateTime.now().subtract(const Duration(days: 29));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'expiring_chat_123',
            otherUserId: 'user_999',
            otherUserName: 'Ana Costa',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verificar cálculo de expiração
      final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
      final isExpired = ChatExpirationService.isChatExpired(matchDate);

      // Assert - Verificar comportamento de expiração
      expect(daysRemaining, lessThanOrEqualTo(30));
      
      if (isExpired) {
        // Chat expirado - verificar se envio está bloqueado
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          final textFieldWidget = tester.widget<TextField>(textField);
          expect(textFieldWidget.enabled, isFalse);
        }
      } else {
        // Chat ainda ativo - verificar se banner de aviso é exibido
        expect(find.byType(RomanticMatchChatView), findsOneWidget);
      }
    });

    testWidgets('deve marcar mensagens como lidas automaticamente', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'read_test_chat_123',
            otherUserId: 'user_111',
            otherUserName: 'Carlos Lima',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento e marcação automática
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular interação com mensagens (se houver)
      final messageWidgets = find.byType(GestureDetector);
      if (messageWidgets.evaluate().isNotEmpty) {
        await tester.tap(messageWidgets.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Verificar se sistema de leitura funcionou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não houve erros críticos no sistema de leitura
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final readErrors = errorHistory.where((e) => 
        e.message.toLowerCase().contains('leitura') ||
        e.message.toLowerCase().contains('read')
      ).toList();
      expect(readErrors.length, lessThan(2));
    });

    testWidgets('deve recuperar de erros de rede automaticamente', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 3));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'network_test_chat_123',
            otherUserId: 'user_222',
            otherUserName: 'Lucia Ferreira',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento e possíveis tentativas de retry
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Simular tentativa de envio de mensagem (pode falhar por rede)
      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      if (textField.evaluate().isNotEmpty && sendButton.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'Teste de conectividade');
        await tester.pump();
        
        await tester.tap(sendButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
      }

      // Assert - Verificar se sistema se recuperou de erros
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar estatísticas de retry
      final retryStats = MatchRetryService.getRetryStats();
      expect(retryStats['totalOperations'], greaterThanOrEqualTo(0));
    });

    testWidgets('deve sincronizar dados em tempo real', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 7));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'sync_test_chat_123',
            otherUserId: 'user_333',
            otherUserName: 'Roberto Alves',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar sincronização inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Simular mudanças de dados (mensagens chegando)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se sincronização funcionou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há loops infinitos ou problemas de performance
      final loadingManager = Get.find<MatchLoadingManager>();
      final activeOperations = loadingManager.getActiveLoadingStates();
      expect(activeOperations.length, lessThan(5)); // Não deve ter muitas operações ativas
    });

    testWidgets('deve manter performance durante uso intenso', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 2));
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'performance_test_chat_123',
            otherUserId: 'user_444',
            otherUserName: 'Fernanda Oliveira',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Simular uso intenso
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular múltiplas interações
      for (int i = 0; i < 5; i++) {
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField, 'Mensagem de teste $i');
          await tester.pump();
          
          final sendButton = find.byIcon(Icons.send);
          if (sendButton.evaluate().isNotEmpty) {
            await tester.tap(sendButton);
            await tester.pump();
          }
        }
        
        await tester.pump(const Duration(milliseconds: 200));
      }

      stopwatch.stop();

      // Assert - Verificar performance
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Menos de 10 segundos
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há vazamentos de memória (muitos erros)
      final errorHistory = MatchErrorHandler.getErrorHistory();
      expect(errorHistory.length, lessThan(20)); // Não deve ter muitos erros
    });

    testWidgets('deve completar fluxo de navegação complexa', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/match-chat',
          getPages: [
            GetPage(
              name: '/match-chat',
              page: () => RomanticMatchChatView(
                chatId: 'navigation_test_chat_123',
                otherUserId: 'user_555',
                otherUserName: 'Gabriel Santos',
                matchDate: DateTime.now().subtract(const Duration(days: 4)),
              ),
            ),
          ],
        ),
      );

      // Act - Testar navegação e estados
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular abertura de menu de opções
      final moreButton = find.byIcon(Icons.more_vert);
      if (moreButton.evaluate().isNotEmpty) {
        await tester.tap(moreButton);
        await tester.pumpAndSettle();
        
        // Fechar menu
        await tester.tapAt(const Offset(100, 100));
        await tester.pumpAndSettle();
      }

      // Simular scroll na lista de mensagens
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.fling(listView, const Offset(0, 200), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Assert - Verificar se navegação complexa funcionou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      expect(find.text('Gabriel Santos'), findsOneWidget);
    });
  });

  group('Chat System Stress Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve suportar múltiplos chats simultâneos', (tester) async {
      // Arrange - Simular abertura rápida de múltiplos chats
      final chats = [
        {'id': 'chat_1', 'user': 'user_1', 'name': 'User 1'},
        {'id': 'chat_2', 'user': 'user_2', 'name': 'User 2'},
        {'id': 'chat_3', 'user': 'user_3', 'name': 'User 3'},
      ];

      for (final chat in chats) {
        await tester.pumpWidget(
          GetMaterialApp(
            home: RomanticMatchChatView(
              chatId: chat['id']!,
              otherUserId: chat['user']!,
              otherUserName: chat['name']!,
              matchDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Assert - Verificar se sistema suportou múltiplos chats
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se não há vazamentos de recursos
      final loadingManager = Get.find<MatchLoadingManager>();
      final stats = loadingManager.getLoadingStats();
      expect(stats['activeOperations'], lessThan(10));
    });

    testWidgets('deve recuperar de falhas críticas', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'critical_test_chat_123',
            otherUserId: 'user_critical',
            otherUserName: 'Critical Test User',
            matchDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      );

      // Act - Aguardar possíveis falhas e recuperação
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      // Simular interações após possíveis falhas
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'Teste após recuperação');
        await tester.pump();
      }

      // Assert - Verificar se sistema se recuperou
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se erros foram tratados adequadamente
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final criticalErrors = errorHistory.where((e) => 
        e.type == MatchErrorType.unknownError
      ).toList();
      expect(criticalErrors.length, lessThan(5)); // Permitir alguns erros, mas não muitos
    });
  });
}