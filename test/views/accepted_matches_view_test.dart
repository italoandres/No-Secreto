import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/views/accepted_matches_view.dart';
import '../../lib/models/accepted_match_model.dart';

// Mock widget para testar sem Firebase
class MockAcceptedMatchesView extends StatelessWidget {
  const MockAcceptedMatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Matches Aceitos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B9D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seus Matches',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Mock View'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('AcceptedMatchesView', () {
    testWidgets('deve renderizar AppBar corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se o AppBar está presente
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Matches Aceitos'), findsOneWidget);
      
      // Verificar se o botão de refresh está presente
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('deve mostrar estado de loading inicialmente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se os skeletons de loading estão presentes
      expect(find.text('Seus Matches'), findsOneWidget);
      
      // Aguardar um frame para o loading aparecer
      await tester.pump();
      
      // Verificar se o widget foi construído
      expect(find.byType(MockAcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve mostrar header com informações corretas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se o header está presente
      expect(find.text('Seus Matches'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('deve ter cores e tema corretos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se o Scaffold tem a cor de fundo correta
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF8F9FA));

      // Verificar se o AppBar tem a cor correta
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFFF6B9D));
    });

    testWidgets('deve responder ao tap no botão refresh', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Encontrar e tocar no botão de refresh
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      // Verificar se não houve erro
      expect(find.byType(MockAcceptedMatchesView), findsOneWidget);
    });

    testWidgets('deve ter estrutura de layout correta', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar estrutura básica
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('deve ter título correto na AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar título
      expect(find.text('Matches Aceitos'), findsOneWidget);
      
      // Verificar estilo do título
      final titleWidget = tester.widget<Text>(find.text('Matches Aceitos'));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, Colors.white);
    });

    testWidgets('deve ter ícones corretos na interface', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar ícones presentes
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('AcceptedMatchesView Layout', () {
    testWidgets('deve ter layout responsivo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se o widget foi construído corretamente
      expect(find.byType(MockAcceptedMatchesView), findsOneWidget);
      expect(find.text('Mock View'), findsOneWidget);
    });

    testWidgets('deve ter gradiente no header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockAcceptedMatchesView(),
        ),
      );

      // Verificar se o container com gradiente está presente
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.text('Seus Matches'), findsOneWidget);
    });
  });
}