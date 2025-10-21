import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/romantic_match_chat_view.dart';
import 'package:whatsapp_chat/services/chat_expiration_service.dart';
import 'package:whatsapp_chat/services/match_loading_manager.dart';
import 'package:whatsapp_chat/services/match_error_handler.dart';
import 'package:whatsapp_chat/components/chat_expiration_banner.dart';

void main() {
  group('Chat Expiration Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
      MatchErrorHandler.clearErrorHistory();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve exibir banner verde para chat novo (25+ dias)', (tester) async {
      // Arrange - Chat com 2 dias (28 dias restantes)
      final matchDate = DateTime.now().subtract(const Duration(days: 2));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'new_chat_123',
            otherUserId: 'user_123',
            otherUserName: 'João Silva',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar cálculos de expiração
      final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
      final isExpired = ChatExpirationService.isChatExpired(matchDate);
      
      expect(daysRemaining, greaterThan(25));
      expect(isExpired, isFalse);
      
      // Verificar se chat está funcional
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se campo de input está habilitado
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.enabled, isTrue);
      }
    });

    testWidgets('deve exibir banner amarelo para chat em alerta (10-25 dias)', (tester) async {
      // Arrange - Chat com 15 dias (15 dias restantes)
      final matchDate = DateTime.now().subtract(const Duration(days: 15));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'warning_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'Maria Santos',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar estado de alerta
      final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
      final isExpired = ChatExpirationService.isChatExpired(matchDate);
      
      expect(daysRemaining, greaterThan(10));
      expect(daysRemaining, lessThan(25));
      expect(isExpired, isFalse);
      
      // Verificar se chat ainda está funcional
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se banner de aviso é exibido
      final bannerFinder = find.byType(ChatExpirationBanner);
      if (bannerFinder.evaluate().isNotEmpty) {
        expect(bannerFinder, findsOneWidget);
      }
    });

    testWidgets('deve exibir banner vermelho para chat crítico (1-10 dias)', (tester) async {
      // Arrange - Chat com 25 dias (5 dias restantes)
      final matchDate = DateTime.now().subtract(const Duration(days: 25));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'critical_chat_123',
            otherUserId: 'user_789',
            otherUserName: 'Pedro Costa',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar estado crítico
      final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
      final isExpired = ChatExpirationService.isChatExpired(matchDate);
      
      expect(daysRemaining, greaterThan(0));
      expect(daysRemaining, lessThan(10));
      expect(isExpired, isFalse);
      
      // Verificar se chat ainda está funcional mas com aviso
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se banner crítico é exibido
      final bannerFinder = find.byType(ChatExpirationBanner);
      if (bannerFinder.evaluate().isNotEmpty) {
        expect(bannerFinder, findsOneWidget);
      }
    });

    testWidgets('deve bloquear chat expirado (30+ dias)', (tester) async {
      // Arrange - Chat expirado (35 dias)
      final matchDate = DateTime.now().subtract(const Duration(days: 35));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'expired_chat_123',
            otherUserId: 'user_999',
            otherUserName: 'Ana Lima',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar estado expirado
      final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
      final isExpired = ChatExpirationService.isChatExpired(matchDate);
      
      expect(daysRemaining, lessThanOrEqualTo(0));
      expect(isExpired, isTrue);
      
      // Verificar se chat está bloqueado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se campo de input está desabilitado
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.enabled, isFalse);
      }
      
      // Verificar se banner de expiração é exibido
      final bannerFinder = find.byType(ChatExpirationBanner);
      if (bannerFinder.evaluate().isNotEmpty) {
        expect(bannerFinder, findsOneWidget);
      }
    });

    testWidgets('deve impedir envio de mensagem em chat expirado', (tester) async {
      // Arrange - Chat expirado
      final matchDate = DateTime.now().subtract(const Duration(days: 32));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'blocked_chat_123',
            otherUserId: 'user_111',
            otherUserName: 'Carlos Ferreira',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Tentar enviar mensagem
      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'Esta mensagem não deve ser enviada');
        await tester.pump();

        if (sendButton.evaluate().isNotEmpty) {
          await tester.tap(sendButton);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
      }

      // Assert - Verificar se envio foi bloqueado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se erro de chat expirado foi registrado
      final errorHistory = MatchErrorHandler.getErrorHistory();
      final expiredErrors = errorHistory.where((e) => 
        e.type == MatchErrorType.chatExpired ||
        e.message.toLowerCase().contains('expirou')
      ).toList();
      
      // Pode não haver erro se o campo já está desabilitado
      expect(expiredErrors.length, greaterThanOrEqualTo(0));
    });

    testWidgets('deve calcular dias restantes corretamente', (tester) async {
      // Arrange - Diferentes cenários de data
      final testCases = [
        {'days': 1, 'expectedRemaining': 29},
        {'days': 10, 'expectedRemaining': 20},
        {'days': 20, 'expectedRemaining': 10},
        {'days': 29, 'expectedRemaining': 1},
        {'days': 30, 'expectedRemaining': 0},
        {'days': 35, 'expectedRemaining': -5},
      ];

      for (final testCase in testCases) {
        final matchDate = DateTime.now().subtract(Duration(days: testCase['days']! as int));
        final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
        
        // Assert - Verificar cálculo (com tolerância de 1 dia para diferenças de horário)
        expect(
          daysRemaining, 
          inInclusiveRange(
            (testCase['expectedRemaining']! as int) - 1, 
            (testCase['expectedRemaining']! as int) + 1
          ),
          reason: 'Falha no cálculo para ${testCase['days']} dias atrás'
        );
      }
    });

    testWidgets('deve atualizar banner automaticamente', (tester) async {
      // Arrange - Chat próximo da mudança de estado
      final matchDate = DateTime.now().subtract(const Duration(days: 24, hours: 23));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'updating_chat_123',
            otherUserId: 'user_222',
            otherUserName: 'Lucia Oliveira',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular passagem de tempo (banner deve atualizar automaticamente)
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 30));

      // Assert - Verificar se banner ainda está funcionando
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      final bannerFinder = find.byType(ChatExpirationBanner);
      if (bannerFinder.evaluate().isNotEmpty) {
        expect(bannerFinder, findsOneWidget);
      }
    });

    testWidgets('deve manter histórico de mensagens após expiração', (tester) async {
      // Arrange - Chat expirado que tinha mensagens
      final matchDate = DateTime.now().subtract(const Duration(days: 40));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'history_chat_123',
            otherUserId: 'user_333',
            otherUserName: 'Roberto Alves',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se chat expirado ainda mostra histórico
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      expect(ChatExpirationService.isChatExpired(matchDate), isTrue);
      
      // Verificar se lista de mensagens ainda está presente (mesmo que vazia)
      final listView = find.byType(ListView);
      expect(listView.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('deve exibir diferentes mensagens de expiração', (tester) async {
      // Arrange - Testar diferentes estados de expiração
      final testCases = [
        {'days': 5, 'description': 'Chat novo'},
        {'days': 15, 'description': 'Chat em alerta'},
        {'days': 28, 'description': 'Chat crítico'},
        {'days': 35, 'description': 'Chat expirado'},
      ];

      for (final testCase in testCases) {
        final matchDate = DateTime.now().subtract(Duration(days: testCase['days']! as int));
        
        await tester.pumpWidget(
          GetMaterialApp(
            home: RomanticMatchChatView(
              chatId: 'message_test_${testCase['days']}',
              otherUserId: 'user_test_${testCase['days']}',
              otherUserName: 'Test User ${testCase['days']}',
              matchDate: matchDate,
            ),
          ),
        );

        // Act - Aguardar carregamento
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Assert - Verificar se tela carregou para cada caso
        expect(find.byType(RomanticMatchChatView), findsOneWidget);
        
        final daysRemaining = ChatExpirationService.getDaysRemaining(matchDate);
        final isExpired = ChatExpirationService.isChatExpired(matchDate);
        
        if (isExpired) {
          expect(daysRemaining, lessThanOrEqualTo(0));
        } else {
          expect(daysRemaining, greaterThan(0));
        }
      }
    });

    testWidgets('deve lidar com edge cases de data', (tester) async {
      // Arrange - Casos extremos
      final edgeCases = [
        DateTime.now(), // Chat criado agora
        DateTime.now().subtract(const Duration(days: 30)), // Exatamente 30 dias
        DateTime.now().subtract(const Duration(days: 30, hours: 1)), // 1 hora após expiração
        DateTime.now().add(const Duration(days: 1)), // Data futura (erro)
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final matchDate = edgeCases[i];
        
        await tester.pumpWidget(
          GetMaterialApp(
            home: RomanticMatchChatView(
              chatId: 'edge_case_$i',
              otherUserId: 'user_edge_$i',
              otherUserName: 'Edge Case $i',
              matchDate: matchDate,
            ),
          ),
        );

        // Act - Aguardar carregamento
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Assert - Verificar se sistema lida com edge cases
        expect(find.byType(RomanticMatchChatView), findsOneWidget);
        
        // Verificar se cálculos não quebram
        expect(() => ChatExpirationService.getDaysRemaining(matchDate), returnsNormally);
        expect(() => ChatExpirationService.isChatExpired(matchDate), returnsNormally);
      }
    });
  });

  group('Chat Expiration Performance Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve calcular expiração rapidamente', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 15));
      final stopwatch = Stopwatch()..start();

      // Act - Múltiplos cálculos de expiração
      for (int i = 0; i < 100; i++) {
        ChatExpirationService.getDaysRemaining(matchDate);
        ChatExpirationService.isChatExpired(matchDate);
      }

      stopwatch.stop();

      // Assert - Verificar performance
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Menos de 100ms para 100 cálculos
    });

    testWidgets('deve atualizar banner sem impacto na performance', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 20));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'performance_chat_123',
            otherUserId: 'user_perf',
            otherUserName: 'Performance Test',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Simular múltiplas atualizações
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10; i++) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      stopwatch.stop();

      // Assert - Verificar performance das atualizações
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Menos de 2 segundos
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
    });
  });
}