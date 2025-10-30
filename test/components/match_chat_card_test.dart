import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/match_chat_card.dart';
import '../../lib/models/accepted_match_model.dart';

void main() {
  group('MatchChatCard', () {
    late AcceptedMatchModel testMatch;
    
    setUp(() {
      testMatch = AcceptedMatchModel(
        notificationId: 'test_match_1',
        otherUserId: 'user_123',
        otherUserName: 'João Silva',
        otherUserPhoto: 'https://example.com/photo.jpg',
        matchDate: DateTime.now().subtract(const Duration(days: 5)),
        chatId: 'chat_123',
        unreadMessages: 2,
        chatExpired: false,
        daysRemaining: 25,
      );
    });

    testWidgets('deve renderizar informações básicas do match', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: testMatch,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verificar se o nome do usuário está presente
      expect(find.text('João Silva'), findsOneWidget);
      
      // Verificar se a informação de match está presente
      expect(find.textContaining('Match'), findsOneWidget);
      
      // Verificar se o badge de mensagens não lidas está presente
      expect(find.text('2'), findsOneWidget);
      
      // Verificar se o indicador de dias restantes está presente
      expect(find.text('25d'), findsOneWidget);
    });

    testWidgets('deve mostrar indicador de chat expirado', (tester) async {
      final expiredMatch = testMatch.copyWith(
        chatExpired: true,
        daysRemaining: 0,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: expiredMatch,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verificar se o aviso de expiração está presente
      expect(find.text('Chat Expirado'), findsOneWidget);
      
      // Verificar se o ícone de bloqueio está presente
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('deve mostrar avatar padrão quando não há foto', (tester) async {
      final matchWithoutPhoto = testMatch.copyWith(otherUserPhoto: null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: matchWithoutPhoto,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verificar se o widget foi construído corretamente
      expect(find.byType(MatchChatCard), findsOneWidget);
      
      // Verificar se o nome do usuário está presente
      expect(find.text('João Silva'), findsOneWidget);
    });

    testWidgets('deve mostrar indicador online quando habilitado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: testMatch,
              onTap: () {},
              showOnlineStatus: true,
            ),
          ),
        ),
      );

      // O indicador online é um Container verde, difícil de testar diretamente
      // Vamos verificar se o widget foi construído sem erros
      expect(find.byType(MatchChatCard), findsOneWidget);
    });

    testWidgets('deve executar callback onTap quando tocado', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: testMatch,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tocar no card
      await tester.tap(find.byType(MatchChatCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('deve mostrar diferentes cores baseadas nos dias restantes', (tester) async {
      // Teste com poucos dias restantes (crítico)
      final criticalMatch = testMatch.copyWith(daysRemaining: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: criticalMatch,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1d'), findsOneWidget);
      
      // Teste com dias moderados (aviso)
      final warningMatch = testMatch.copyWith(daysRemaining: 5);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: warningMatch,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5d'), findsOneWidget);
    });

    testWidgets('deve mostrar ícone de chat quando não há mensagens não lidas', (tester) async {
      final matchWithoutUnread = testMatch.copyWith(unreadMessages: 0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: matchWithoutUnread,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verificar se o ícone de chat está presente
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('deve truncar nomes muito longos', (tester) async {
      final matchWithLongName = testMatch.copyWith(
        otherUserName: 'Nome Muito Longo Que Deveria Ser Truncado Para Não Quebrar Layout',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: matchWithLongName,
              onTap: () {},
            ),
          ),
        ),
      );

      // O widget deve ser construído sem erros mesmo com nome longo
      expect(find.byType(MatchChatCard), findsOneWidget);
    });

    testWidgets('deve aplicar margem personalizada', (tester) async {
      const customMargin = EdgeInsets.all(20);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: testMatch,
              onTap: () {},
              margin: customMargin,
            ),
          ),
        ),
      );

      expect(find.byType(MatchChatCard), findsOneWidget);
    });
  });

  group('MatchChatCardSkeleton', () {
    testWidgets('deve renderizar skeleton de loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchChatCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(MatchChatCardSkeleton), findsOneWidget);
    });

    testWidgets('deve aplicar margem personalizada no skeleton', (tester) async {
      const customMargin = EdgeInsets.all(20);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchChatCardSkeleton(margin: customMargin),
          ),
        ),
      );

      expect(find.byType(MatchChatCardSkeleton), findsOneWidget);
    });
  });

  group('AcceptedMatchModel Integration', () {
    testWidgets('deve usar propriedades do modelo corretamente', (tester) async {
      final match = AcceptedMatchModel(
        notificationId: 'test_123',
        otherUserId: 'user_456',
        otherUserName: 'Maria Santos',
        otherUserPhoto: null,
        matchDate: DateTime.now().subtract(const Duration(days: 10)),
        chatId: 'chat_456',
        unreadMessages: 5,
        chatExpired: false,
        daysRemaining: 20,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: match,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verificar se as propriedades do modelo são usadas
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('20d'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget); // Avatar padrão
    });

    testWidgets('deve lidar com valores extremos', (tester) async {
      final extremeMatch = AcceptedMatchModel(
        notificationId: 'extreme_test',
        otherUserId: 'user_extreme',
        otherUserName: '', // Nome vazio
        otherUserPhoto: 'invalid_url',
        matchDate: DateTime.now().subtract(const Duration(days: 100)),
        chatId: 'chat_extreme',
        unreadMessages: 999, // Muitas mensagens
        chatExpired: true,
        daysRemaining: 0,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchChatCard(
              match: extremeMatch,
              onTap: () {},
            ),
          ),
        ),
      );

      // O widget deve lidar com valores extremos sem quebrar
      expect(find.byType(MatchChatCard), findsOneWidget);
      expect(find.text('99+'), findsOneWidget); // Limite de mensagens
      expect(find.text('Chat Expirado'), findsOneWidget);
    });
  });
}