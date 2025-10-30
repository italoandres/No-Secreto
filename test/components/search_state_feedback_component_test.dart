import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/search_state_feedback_component.dart';

void main() {
  group('SearchStateFeedbackComponent', () {
    testWidgets('should display loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.loading,
              query: 'test query',
            ),
          ),
        ),
      );

      expect(find.text('Buscando perfis...'), findsOneWidget);
      expect(find.text('Procurando por "test query"'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.empty,
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Nenhum perfil disponível'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('should display no results state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.noResults,
              query: 'João Silva',
              onRetry: () {},
              onClearFilters: () {},
            ),
          ),
        ),
      );

      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
      expect(find.textContaining('"João Silva"'), findsOneWidget);
      expect(find.text('Sugestões:'), findsOneWidget);
      expect(find.text('Limpar Filtros'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should display error state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.error,
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Erro na busca'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display success state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.success,
              query: 'test',
              resultCount: 5,
            ),
          ),
        ),
      );

      expect(find.text('5 perfis encontrados'), findsOneWidget);
      expect(find.textContaining('para "test"'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button is pressed', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.error,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tentar Novamente'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('should call onClearFilters when clear filters button is pressed', (WidgetTester tester) async {
      bool clearFiltersPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.noResults,
              query: 'test',
              onClearFilters: () {
                clearFiltersPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Limpar Filtros'));
      await tester.pump();

      expect(clearFiltersPressed, isTrue);
    });

    testWidgets('should show suggestions in no results state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.noResults,
              query: 'test',
            ),
          ),
        ),
      );

      expect(find.text('Tente termos mais gerais'), findsOneWidget);
      expect(find.text('Verifique a ortografia'), findsOneWidget);
      expect(find.text('Remova alguns filtros'), findsOneWidget);
      expect(find.text('Busque por cidade ou estado'), findsOneWidget);
    });

    testWidgets('should return empty widget for unknown state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchStateFeedbackComponent(
              state: SearchState.values.first, // Use any valid state
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(SearchStateFeedbackComponent), findsOneWidget);
    });
  });
}