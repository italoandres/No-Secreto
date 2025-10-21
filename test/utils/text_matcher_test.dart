import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/text_matcher.dart';

void main() {
  group('TextMatcher', () {
    group('matches', () {
      test('should match exact text', () {
        expect(TextMatcher.matches('João Silva', 'João Silva'), isTrue);
        expect(TextMatcher.matches('joão silva', 'João Silva'), isTrue); // Case insensitive
        expect(TextMatcher.matches('João Silva', 'Maria Santos'), isFalse);
      });

      test('should match contained text', () {
        expect(TextMatcher.matches('João Silva Santos', 'Silva'), isTrue);
        expect(TextMatcher.matches('João Silva Santos', 'joão'), isTrue);
        expect(TextMatcher.matches('João Silva Santos', 'Pedro'), isFalse);
      });

      test('should handle case sensitivity', () {
        expect(TextMatcher.matches('João Silva', 'joão', caseSensitive: false), isTrue);
        expect(TextMatcher.matches('João Silva', 'joão', caseSensitive: true), isFalse);
      });

      test('should handle empty strings', () {
        expect(TextMatcher.matches('', 'query'), isFalse);
        expect(TextMatcher.matches('text', ''), isFalse);
        expect(TextMatcher.matches('', ''), isFalse);
      });

      test('should match similar text based on threshold', () {
        expect(TextMatcher.matches('João', 'Joao', threshold: 0.7), isTrue);
        expect(TextMatcher.matches('Silva', 'Silvia', threshold: 0.6), isTrue);
        expect(TextMatcher.matches('João', 'Pedro', threshold: 0.8), isFalse);
      });
    });

    group('calculateSimilarity', () {
      test('should return 1.0 for identical strings', () {
        expect(TextMatcher.calculateSimilarity('João', 'João'), equals(1.0));
        expect(TextMatcher.calculateSimilarity('', ''), equals(1.0));
      });

      test('should return 0.0 for completely different strings', () {
        expect(TextMatcher.calculateSimilarity('', 'text'), equals(0.0));
        expect(TextMatcher.calculateSimilarity('text', ''), equals(0.0));
      });

      test('should calculate similarity correctly', () {
        // Strings muito similares
        final similarity1 = TextMatcher.calculateSimilarity('João', 'Joao');
        expect(similarity1, greaterThan(0.7)); // Ajustado para 0.7

        // Strings moderadamente similares
        final similarity2 = TextMatcher.calculateSimilarity('Silva', 'Silvia');
        expect(similarity2, greaterThan(0.6));
        expect(similarity2, lessThan(0.9));

        // Strings pouco similares
        final similarity3 = TextMatcher.calculateSimilarity('João', 'Pedro');
        expect(similarity3, lessThan(0.5));
      });
    });

    group('calculateMatchScore', () {
      test('should give highest score for exact match', () {
        final score = TextMatcher.calculateMatchScore('João Silva', 'João Silva');
        expect(score, equals(TextMatcher.exactMatchWeight));
      });

      test('should give high score for start of word match', () {
        final score = TextMatcher.calculateMatchScore('João Silva Santos', 'João');
        expect(score, equals(TextMatcher.startOfWordWeight));
      });

      test('should give medium score for contains match', () {
        final score = TextMatcher.calculateMatchScore('João Silva Santos', 'Silva');
        expect(score, greaterThanOrEqualTo(TextMatcher.containsWeight));
      });

      test('should handle case insensitivity', () {
        final score1 = TextMatcher.calculateMatchScore('João Silva', 'joão', caseSensitive: false);
        final score2 = TextMatcher.calculateMatchScore('João Silva', 'joão', caseSensitive: true);
        
        expect(score1, greaterThan(score2));
      });
    });

    group('extractKeywords', () {
      test('should extract words from text', () {
        final keywords = TextMatcher.extractKeywords('João Silva Santos');
        
        expect(keywords, contains('joao')); // Normalizado
        expect(keywords, contains('silva'));
        expect(keywords, contains('santos'));
      });

      test('should include partial keywords when requested', () {
        final keywords = TextMatcher.extractKeywords('João', includePartials: true);
        
        expect(keywords, contains('jo'));
        expect(keywords, contains('joa'));
        expect(keywords, contains('joao')); // Normalizado
      });

      test('should exclude partial keywords when not requested', () {
        final keywords = TextMatcher.extractKeywords('João', includePartials: false);
        
        expect(keywords, isNot(contains('jo')));
        expect(keywords, isNot(contains('joa')));
        expect(keywords, contains('joao')); // Normalizado
      });

      test('should respect minimum length', () {
        final keywords = TextMatcher.extractKeywords('A B João', minLength: 3);
        
        expect(keywords, isNot(contains('a')));
        expect(keywords, isNot(contains('b')));
        expect(keywords, contains('joao')); // Normalizado
      });

      test('should handle special characters', () {
        final keywords = TextMatcher.extractKeywords('João-Silva, Santos!');
        
        expect(keywords, contains('joao')); // Normalizado
        expect(keywords, contains('silva'));
        expect(keywords, contains('santos'));
      });
    });

    group('fuzzySearch', () {
      final testTexts = [
        'João Silva',
        'Maria Santos',
        'Pedro João',
        'Ana Silva Santos',
        'Carlos Pereira',
      ];

      test('should find exact matches', () {
        final results = TextMatcher.fuzzySearch(testTexts, 'João Silva');
        
        expect(results, isNotEmpty);
        expect(results.first.text, equals('João Silva'));
        expect(results.first.score, equals(TextMatcher.exactMatchWeight));
      });

      test('should find partial matches', () {
        final results = TextMatcher.fuzzySearch(testTexts, 'Silva');
        
        expect(results.length, greaterThanOrEqualTo(2));
        expect(results.any((r) => r.text.contains('Silva')), isTrue);
      });

      test('should sort by score descending', () {
        final results = TextMatcher.fuzzySearch(testTexts, 'João');
        
        expect(results, isNotEmpty);
        for (int i = 1; i < results.length; i++) {
          expect(results[i - 1].score, greaterThanOrEqualTo(results[i].score));
        }
      });

      test('should respect threshold', () {
        final results = TextMatcher.fuzzySearch(testTexts, 'xyz', threshold: 0.8);
        
        expect(results, isEmpty);
      });

      test('should limit results', () {
        final results = TextMatcher.fuzzySearch(testTexts, 'a', maxResults: 2);
        
        expect(results.length, lessThanOrEqualTo(2));
      });
    });

    group('highlightMatches', () {
      test('should highlight exact matches', () {
        final result = TextMatcher.highlightMatches('João Silva', 'João');
        
        expect(result, equals('<mark>João</mark> Silva'));
      });

      test('should highlight multiple matches', () {
        final result = TextMatcher.highlightMatches('João Silva João', 'João');
        
        expect(result, equals('<mark>João</mark> Silva <mark>João</mark>'));
      });

      test('should use custom tags', () {
        final result = TextMatcher.highlightMatches(
          'João Silva',
          'João',
          startTag: '<b>',
          endTag: '</b>',
        );
        
        expect(result, equals('<b>João</b> Silva'));
      });

      test('should handle case insensitivity', () {
        final result = TextMatcher.highlightMatches('João Silva', 'joão');
        
        expect(result, equals('<mark>João</mark> Silva'));
      });

      test('should return original text when no matches', () {
        final result = TextMatcher.highlightMatches('João Silva', 'Pedro');
        
        expect(result, equals('João Silva'));
      });

      test('should handle empty inputs', () {
        expect(TextMatcher.highlightMatches('', 'query'), equals(''));
        expect(TextMatcher.highlightMatches('text', ''), equals('text'));
      });
    });

    group('suggestCorrections', () {
      final availableTexts = [
        'João Silva Santos',
        'Maria Oliveira',
        'Pedro Almeida',
        'Ana Costa',
        'Carlos Pereira',
      ];

      test('should suggest similar words', () {
        final suggestions = TextMatcher.suggestCorrections('Joao', availableTexts);
        
        expect(suggestions, contains('joao')); // Normalizado
      });

      test('should limit suggestions', () {
        final suggestions = TextMatcher.suggestCorrections('a', availableTexts, maxSuggestions: 2);
        
        expect(suggestions.length, lessThanOrEqualTo(2));
      });

      test('should respect threshold', () {
        final suggestions = TextMatcher.suggestCorrections('xyz', availableTexts, threshold: 0.9);
        
        expect(suggestions, isEmpty);
      });

      test('should return empty for empty inputs', () {
        expect(TextMatcher.suggestCorrections('', availableTexts), isEmpty);
        expect(TextMatcher.suggestCorrections('query', []), isEmpty);
      });

      test('should remove duplicates', () {
        final textsWithDuplicates = [
          'João Silva',
          'João Santos',
          'Maria João',
        ];
        
        final suggestions = TextMatcher.suggestCorrections('Joao', textsWithDuplicates);
        
        // Deve ter apenas uma sugestão 'joao' mesmo aparecendo em múltiplos textos
        final joaoCount = suggestions.where((s) => s == 'joao').length;
        expect(joaoCount, equals(1));
      });
    });
  });

  group('MatchResult', () {
    test('should create correctly', () {
      const result = MatchResult(
        text: 'João Silva',
        index: 0,
        score: 0.8,
        query: 'João',
      );

      expect(result.text, equals('João Silva'));
      expect(result.index, equals(0));
      expect(result.score, equals(0.8));
      expect(result.query, equals('João'));
    });

    test('should handle equality correctly', () {
      const result1 = MatchResult(text: 'João', index: 0, score: 0.8, query: 'João');
      const result2 = MatchResult(text: 'João', index: 0, score: 0.8, query: 'João');
      const result3 = MatchResult(text: 'Maria', index: 0, score: 0.8, query: 'João');

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('should have correct toString', () {
      const result = MatchResult(text: 'João', index: 0, score: 0.8, query: 'João');
      final string = result.toString();

      expect(string, contains('MatchResult'));
      expect(string, contains('João'));
      expect(string, contains('0.8'));
    });
  });

  group('SuggestionResult', () {
    test('should create correctly', () {
      const suggestion = SuggestionResult(suggestion: 'João', similarity: 0.9);

      expect(suggestion.suggestion, equals('João'));
      expect(suggestion.similarity, equals(0.9));
    });

    test('should handle equality correctly', () {
      const suggestion1 = SuggestionResult(suggestion: 'João', similarity: 0.9);
      const suggestion2 = SuggestionResult(suggestion: 'João', similarity: 0.9);
      const suggestion3 = SuggestionResult(suggestion: 'Maria', similarity: 0.9);

      expect(suggestion1, equals(suggestion2));
      expect(suggestion1, isNot(equals(suggestion3)));
    });
  });

  group('Match', () {
    test('should create correctly', () {
      const match = Match(0, 5);

      expect(match.start, equals(0));
      expect(match.end, equals(5));
    });

    test('should handle equality correctly', () {
      const match1 = Match(0, 5);
      const match2 = Match(0, 5);
      const match3 = Match(1, 5);

      expect(match1, equals(match2));
      expect(match1, isNot(equals(match3)));
    });
  });
}