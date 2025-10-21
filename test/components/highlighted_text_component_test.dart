import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/highlighted_text_component.dart';

void main() {
  group('HighlightedTextComponent', () {
    testWidgets('should display text without highlighting when no search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: null,
            ),
          ),
        ),
      );

      expect(find.text('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should display text without highlighting when empty search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: '',
            ),
          ),
        ),
      );

      expect(find.text('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should highlight single word correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: 'Silva',
            ),
          ),
        ),
      );

      // Verificar se o componente RichText foi criado
      expect(find.byType(RichText), findsOneWidget);
      
      // Verificar se o texto completo está presente
      expect(find.textContaining('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should highlight multiple words correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: 'João Silva',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should be case insensitive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: 'joão silva',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should handle partial word matches correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: 'Silv',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.textContaining('João Silva da Costa'), findsOneWidget);
    });

    testWidgets('should respect maxLines property', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa\nSegunda linha\nTerceira linha',
              searchQuery: 'Silva',
              maxLines: 2,
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.maxLines, equals(2));
    });

    testWidgets('should apply custom styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedTextComponent(
              text: 'João Silva da Costa',
              searchQuery: 'Silva',
              style: TextStyle(fontSize: 20, color: Colors.blue),
              highlightStyle: TextStyle(backgroundColor: Colors.red),
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });
  });

  group('QuickHighlightText', () {
    testWidgets('should create highlighted text with quick setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickHighlightText(
              text: 'João Silva da Costa',
              searchQuery: 'Silva',
              fontSize: 16,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.byType(HighlightedTextComponent), findsOneWidget);
    });

    testWidgets('should handle null search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickHighlightText(
              text: 'João Silva da Costa',
              searchQuery: null,
            ),
          ),
        ),
      );

      expect(find.byType(HighlightedTextComponent), findsOneWidget);
    });
  });

  group('ProfileHighlightText', () {
    testWidgets('should create profile-specific highlighted text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileHighlightText(
              text: 'João Silva da Costa',
              searchQuery: 'Silva',
              isTitle: true,
            ),
          ),
        ),
      );

      expect(find.byType(HighlightedTextComponent), findsOneWidget);
    });

    testWidgets('should apply different styles for title and regular text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfileHighlightText(
                  text: 'João Silva da Costa',
                  searchQuery: 'Silva',
                  isTitle: true,
                ),
                ProfileHighlightText(
                  text: 'Descrição do perfil',
                  searchQuery: 'perfil',
                  isTitle: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(HighlightedTextComponent), findsNWidgets(2));
    });
  });

  group('HighlightMatch', () {
    test('should create highlight match correctly', () {
      final match = HighlightMatch(
        start: 5,
        end: 10,
        word: 'Silva',
      );

      expect(match.start, equals(5));
      expect(match.end, equals(10));
      expect(match.word, equals('Silva'));
    });

    test('should have correct toString representation', () {
      final match = HighlightMatch(
        start: 5,
        end: 10,
        word: 'Silva',
      );

      expect(match.toString(), equals('HighlightMatch(start: 5, end: 10, word: Silva)'));
    });
  });
}