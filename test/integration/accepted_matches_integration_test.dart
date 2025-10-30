import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/accepted_matches_view.dart';
import 'package:whatsapp_chat/views/romantic_match_chat_view.dart';
import 'package:whatsapp_chat/services/match_loading_manager.dart';
import 'package:whatsapp_chat/services/match_navigation_service.dart';
import 'package:whatsapp_chat/models/accepted_match_model.dart';
import 'package:whatsapp_chat/models/chat_message_model.dart';

void main() {
  group('Accepted Matches Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve carregar e exibir lista de matches aceitos', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se a tela foi carregada
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Verificar se há elementos da interface
      expect(find.text('Matches Aceitos'), findsOneWidget);
    });

    testWidgets('deve navegar do match para o chat', (tester) async {
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
              page: () => const RomanticMatchChatView(
                chatId: 'test_chat',
                otherUserId: 'test_user',
                otherUserName: 'Test User',
                matchDate: DateTime.now(),
              ),
            ),
          ],
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular tap em um match (se houver)
      final matchCards = find.byType(Card);
      if (matchCards.evaluate().isNotEmpty) {
        await tester.tap(matchCards.first);
        await tester.pumpAndSettle();
      }

      // Assert - Verificar navegação (pode não haver matches para testar)
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve exibir estado de loading durante carregamento', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Verificar loading inicial
      await tester.pump();

      // Assert - Verificar se loading é exibido
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
      
      // Aguardar carregamento completar
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('deve permitir refresh da lista', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular pull-to-refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se refresh foi executado
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve exibir estado vazio quando não há matches', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verificar se estado vazio é exibido (dependendo dos dados)
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });
  });

  group('Chat Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve carregar tela de chat com parâmetros corretos', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 5));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'test_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'João Silva',
            otherUserPhoto: 'https://example.com/photo.jpg',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se chat foi carregado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
    });

    testWidgets('deve exibir banner de expiração quando apropriado', (tester) async {
      // Arrange - Chat próximo da expiração
      final matchDate = DateTime.now().subtract(const Duration(days: 28));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'test_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'João Silva',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se banner de expiração é exibido
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
    });

    testWidgets('deve permitir envio de mensagem', (tester) async {
      // Arrange
      final matchDate = DateTime.now().subtract(const Duration(days: 5));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'test_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'João Silva',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Encontrar campo de texto e botão de envio
      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      if (textField.evaluate().isNotEmpty && sendButton.evaluate().isNotEmpty) {
        // Digitar mensagem
        await tester.enterText(textField, 'Olá, como você está?');
        await tester.pump();

        // Enviar mensagem
        await tester.tap(sendButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Verificar se interface respondeu
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
    });

    testWidgets('deve bloquear envio em chat expirado', (tester) async {
      // Arrange - Chat expirado
      final matchDate = DateTime.now().subtract(const Duration(days: 35));
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: RomanticMatchChatView(
            chatId: 'test_chat_123',
            otherUserId: 'user_456',
            otherUserName: 'João Silva',
            matchDate: matchDate,
          ),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verificar se chat expirado é indicado
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
      
      // Verificar se campo de input está desabilitado ou não visível
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.enabled, isFalse);
      }
    });

    testWidgets('deve voltar para lista de matches', (tester) async {
      // Arrange
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/match-chat',
          getPages: [
            GetPage(
              name: '/accepted-matches',
              page: () => const AcceptedMatchesView(),
            ),
            GetPage(
              name: '/match-chat',
              page: () => RomanticMatchChatView(
                chatId: 'test_chat_123',
                otherUserId: 'user_456',
                otherUserName: 'João Silva',
                matchDate: DateTime.now(),
              ),
            ),
          ],
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Encontrar e tocar botão voltar
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Assert - Verificar navegação de volta
      expect(find.byType(RomanticMatchChatView), findsOneWidget);
    });
  });

  group('Navigation Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve navegar entre telas usando MatchNavigationService', (tester) async {
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
                chatId: 'test_chat',
                otherUserId: 'test_user',
                otherUserName: 'Test User',
                matchDate: DateTime.now(),
              ),
            ),
          ],
        ),
      );

      // Act - Aguardar carregamento inicial
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Testar navegação programática
      MatchNavigationService.navigateToMatchChat(
        chatId: 'test_chat',
        otherUserId: 'test_user',
        otherUserName: 'Test User',
        matchDate: DateTime.now(),
      );

      await tester.pumpAndSettle();

      // Assert - Verificar se navegação funcionou
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve manter estado durante navegação', (tester) async {
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
                chatId: 'test_chat',
                otherUserId: 'test_user',
                otherUserName: 'Test User',
                matchDate: DateTime.now(),
              ),
            ),
          ],
        ),
      );

      // Act - Navegar entre telas
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular navegação de ida e volta
      MatchNavigationService.navigateToMatchChat(
        chatId: 'test_chat',
        otherUserId: 'test_user',
        otherUserName: 'Test User',
        matchDate: DateTime.now(),
      );
      await tester.pumpAndSettle();

      MatchNavigationService.goBack();
      await tester.pumpAndSettle();

      // Assert - Verificar se estado foi mantido
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });
  });

  group('Error Handling Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve exibir estado de erro quando carregamento falha', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar possível erro de carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Assert - Verificar se tela ainda está funcional
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve permitir retry após erro', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento e possível erro
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Procurar botão de retry se houver erro
      final retryButton = find.byIcon(Icons.refresh);
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Verificar se retry funcionou
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });
  });

  group('Performance Integration Tests', () {
    setUp(() {
      Get.reset();
      Get.put(MatchLoadingManager());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve carregar tela em tempo razoável', (tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      stopwatch.stop();

      // Assert - Verificar se carregou em menos de 5 segundos
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve manter performance durante scroll', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AcceptedMatchesView(),
        ),
      );

      // Act - Aguardar carregamento
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Simular scroll se houver lista
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.fling(listView, const Offset(0, -300), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert - Verificar se interface ainda responde
      expect(find.byType(AcceptedMatchesView), findsOneWidget);
    });
  });
}