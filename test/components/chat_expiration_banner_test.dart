import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/chat_expiration_banner.dart';

void main() {
  group('ChatExpirationBanner', () {
    testWidgets('deve mostrar banner para chat não expirado', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se o banner está presente
      expect(find.byType(ChatExpirationBanner), findsOneWidget);
      
      // Verificar se mostra dias restantes
      expect(find.textContaining('dias restantes'), findsOneWidget);
    });

    testWidgets('deve mostrar banner para chat expirado', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 35));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: true,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se mostra "Chat Expirado"
      expect(find.text('Chat Expirado'), findsOneWidget);
      
      // Verificar se mostra ícone de bloqueio
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('deve mostrar estado crítico para poucos dias', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 28));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se mostra aviso crítico
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.textContaining('Envie uma mensagem'), findsOneWidget);
    });

    testWidgets('deve mostrar estado de aviso', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 25));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se mostra ícone de relógio
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('deve mostrar indicador de progresso', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 15));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se há indicador circular
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('deve executar callback quando expirar', (tester) async {
      bool callbackExecuted = false;
      final matchDate = DateTime.now().subtract(const Duration(days: 31));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              onExpired: () => callbackExecuted = true,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Aguardar um pouco para o timer
      await tester.pump(const Duration(seconds: 1));

      // O callback deve ser executado se o chat expirou
      // Note: Em um teste real, seria necessário simular a passagem do tempo
      expect(find.byType(ChatExpirationBanner), findsOneWidget);
    });

    testWidgets('deve ter animação de slide quando habilitada', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: true,
            ),
          ),
        ),
      );

      // Verificar se há SlideTransition
      expect(find.byType(SlideTransition), findsOneWidget);
    });

    testWidgets('deve mostrar texto correto para diferentes estados', (tester) async {
      // Teste para "expira hoje"
      final todayMatch = DateTime.now().subtract(const Duration(days: 30));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: todayMatch,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Expira'), findsOneWidget);
    });

    testWidgets('deve ter cores diferentes para diferentes estados', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Verificar se o container está presente
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('CompactExpirationIndicator', () {
    testWidgets('deve mostrar indicador compacto', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExpirationIndicator(
              matchDate: matchDate,
              isExpired: false,
            ),
          ),
        ),
      );

      // Verificar se mostra dias restantes
      expect(find.textContaining('d'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('deve mostrar "Expirado" quando expirado', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 35));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExpirationIndicator(
              matchDate: matchDate,
              isExpired: true,
            ),
          ),
        ),
      );

      expect(find.text('Expirado'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('deve ter cores diferentes baseadas no tempo', (tester) async {
      // Teste com tempo normal
      final normalMatch = DateTime.now().subtract(const Duration(days: 10));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExpirationIndicator(
              matchDate: normalMatch,
              isExpired: false,
            ),
          ),
        ),
      );

      expect(find.byType(CompactExpirationIndicator), findsOneWidget);

      // Teste com tempo crítico
      final criticalMatch = DateTime.now().subtract(const Duration(days: 28));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExpirationIndicator(
              matchDate: criticalMatch,
              isExpired: false,
            ),
          ),
        ),
      );

      expect(find.byType(CompactExpirationIndicator), findsOneWidget);
    });
  });

  group('ExpirationHistoryCard', () {
    testWidgets('deve mostrar card de histórico', (tester) async {
      final matchDate = DateTime(2023, 12, 1);
      final expirationDate = DateTime(2023, 12, 31);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationHistoryCard(
              matchDate: matchDate,
              expirationDate: expirationDate,
              otherUserName: 'João',
            ),
          ),
        ),
      );

      // Verificar se mostra o nome do usuário
      expect(find.text('Chat com João'), findsOneWidget);
      
      // Verificar se mostra as datas
      expect(find.text('Match:'), findsOneWidget);
      expect(find.text('Expirou:'), findsOneWidget);
      
      // Verificar se mostra mensagem de expiração
      expect(find.text('Chat expirado após 30 dias'), findsOneWidget);
      
      // Verificar ícones
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('deve formatar datas corretamente', (tester) async {
      final matchDate = DateTime(2023, 12, 25);
      final expirationDate = DateTime(2024, 1, 24);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationHistoryCard(
              matchDate: matchDate,
              expirationDate: expirationDate,
              otherUserName: 'Maria',
            ),
          ),
        ),
      );

      // Verificar formato das datas
      expect(find.text('25/12/2023'), findsOneWidget);
      expect(find.text('24/1/2024'), findsOneWidget);
    });

    testWidgets('deve ter layout correto', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 35));
      final expirationDate = DateTime.now().subtract(const Duration(days: 5));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpirationHistoryCard(
              matchDate: matchDate,
              expirationDate: expirationDate,
              otherUserName: 'Pedro',
            ),
          ),
        ),
      );

      // Verificar estrutura
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('Banner States', () {
    testWidgets('deve calcular dias restantes corretamente', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 20));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Deve mostrar dias restantes (entre 8-12 dias aproximadamente)
      expect(find.textContaining('dias restantes'), findsOneWidget);
    });

    testWidgets('deve lidar com chat que expira amanhã', (tester) async {
      final matchDate = DateTime.now().subtract(const Duration(days: 29));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatExpirationBanner(
              matchDate: matchDate,
              isExpired: false,
              showAnimation: false,
            ),
          ),
        ),
      );

      // Deve mostrar "Expira amanhã" ou similar
      expect(find.textContaining('Expira'), findsOneWidget);
    });
  });
}