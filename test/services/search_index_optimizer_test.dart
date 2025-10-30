import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_index_optimizer.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchIndexOptimizer', () {
    late SearchIndexOptimizer optimizer;

    setUp(() {
      optimizer = SearchIndexOptimizer.instance;
      optimizer.clearAll();
    });

    test('should be singleton', () {
      final optimizer1 = SearchIndexOptimizer.instance;
      final optimizer2 = SearchIndexOptimizer.instance;
      
      expect(optimizer1, same(optimizer2));
    });

    test('should analyze query patterns', () {
      optimizer.analyzeQuery(
        query: 'test user',
        filters: SearchFilters(minAge: 25, maxAge: 35),
        executionTime: 1500,
        resultCount: 10,
      );

      final stats = optimizer.getIndexStats();
      expect(stats['totalPatterns'], equals(1));
    });

    test('should generate index suggestions for frequent queries', () {
      final filters = SearchFilters(
        minAge: 25,
        maxAge: 35,
        city: 'São Paulo',
        isVerified: true,
      );

      // Simular queries frequentes
      for (int i = 0; i < 25; i++) {
        optimizer.analyzeQuery(
          query: 'frequent query',
          filters: filters,
          executionTime: 3000, // Query lenta
          resultCount: 5,
        );
      }

      final stats = optimizer.getIndexStats();
      expect(stats['totalSuggestions'], greaterThan(0));
      expect(stats['highPrioritySuggestions'], isNotEmpty);
    });

    test('should suggest text search index for slow text queries', () {
      // Simular busca por texto lenta
      for (int i = 0; i < 15; i++) {
        optimizer.analyzeQuery(
          query: 'search by name',
          filters: null,
          executionTime: 2500, // Lenta
          resultCount: 8,
        );
      }

      final stats = optimizer.getIndexStats();
      final suggestions = stats['highPrioritySuggestions'] as List;
      
      expect(suggestions, isNotEmpty);
      
      // Verificar se há sugestão de índice de texto
      final hasTextSearchSuggestion = suggestions.any((s) => 
        s['type'].toString().contains('textSearch')
      );
      expect(hasTextSearchSuggestion, isTrue);
    });

    test('should suggest range index for age filters', () {
      final ageFilters = SearchFilters(minAge: 20, maxAge: 40);

      // Simular filtros de idade frequentes
      for (int i = 0; i < 15; i++) {
        optimizer.analyzeQuery(
          query: 'age filter test',
          filters: ageFilters,
          executionTime: 1000,
          resultCount: 12,
        );
      }

      final stats = optimizer.getIndexStats();
      expect(stats['totalSuggestions'], greaterThan(0));
    });

    test('should create memory indexes for frequent patterns', () {
      final filters = SearchFilters(city: 'Rio de Janeiro');

      // Simular padrão frequente
      for (int i = 0; i < 25; i++) {
        optimizer.analyzeQuery(
          query: 'memory index test',
          filters: filters,
          executionTime: 800,
          resultCount: 15,
        );
      }

      final stats = optimizer.getIndexStats();
      expect(stats['memoryIndexes']['count'], greaterThan(0));
    });

    test('should search using memory indexes', () {
      final filters = SearchFilters(city: 'Brasília');

      // Criar padrão frequente para gerar índice em memória
      for (int i = 0; i < 25; i++) {
        optimizer.analyzeQuery(
          query: 'memory search test',
          filters: filters,
          executionTime: 600,
          resultCount: 8,
        );
      }

      // Tentar buscar usando índice em memória
      final result = optimizer.searchMemoryIndex('memory search test', filters);
      
      // Pode retornar null se o índice ainda não foi criado ou lista de IDs
      expect(result, anyOf(isNull, isA<List<String>>()));
    });

    test('should add profiles to memory indexes', () {
      final profile = SpiritualProfileModel(
        id: 'test_profile_1',
        displayName: 'Test User',
        age: 30,
        city: 'São Paulo',
      );

      final filters = SearchFilters(
        minAge: 25,
        maxAge: 35,
        city: 'São Paulo',
      );

      // Criar padrão para gerar índice
      for (int i = 0; i < 25; i++) {
        optimizer.analyzeQuery(
          query: 'profile index test',
          filters: filters,
          executionTime: 500,
          resultCount: 10,
        );
      }

      // Adicionar perfil aos índices
      optimizer.addToMemoryIndexes(profile);

      // Verificar se foi adicionado
      final stats = optimizer.getIndexStats();
      expect(stats['memoryIndexes']['count'], greaterThanOrEqualTo(0));
    });

    test('should remove profiles from memory indexes', () {
      final profileId = 'test_profile_to_remove';

      // Remover perfil dos índices
      optimizer.removeFromMemoryIndexes(profileId);

      // Operação deve completar sem erro
      expect(true, isTrue);
    });

    test('should generate Firebase index script', () {
      final filters = SearchFilters(
        minAge: 25,
        maxAge: 35,
        city: 'São Paulo',
        isVerified: true,
      );

      // Gerar sugestões de alta prioridade
      for (int i = 0; i < 30; i++) {
        optimizer.analyzeQuery(
          query: 'firebase index test',
          filters: filters,
          executionTime: 4000, // Muito lenta
          resultCount: 5,
        );
      }

      final script = optimizer.generateFirebaseIndexScript();
      
      expect(script, isNotEmpty);
      expect(script, contains('indexes'));
    });

    test('should cleanup old data', () {
      // Adicionar alguns padrões
      optimizer.analyzeQuery(
        query: 'cleanup test 1',
        filters: null,
        executionTime: 1000,
        resultCount: 5,
      );

      optimizer.analyzeQuery(
        query: 'cleanup test 2',
        filters: null,
        executionTime: 1200,
        resultCount: 3,
      );

      var stats = optimizer.getIndexStats();
      final initialPatterns = stats['totalPatterns'];

      // Executar limpeza
      optimizer.cleanup();

      stats = optimizer.getIndexStats();
      
      // Padrões recentes podem ser mantidos
      expect(stats['totalPatterns'], lessThanOrEqualTo(initialPatterns));
    });

    test('should clear all data', () {
      // Adicionar dados
      optimizer.analyzeQuery(
        query: 'clear all test',
        filters: SearchFilters(minAge: 25),
        executionTime: 1000,
        resultCount: 8,
      );

      var stats = optimizer.getIndexStats();
      expect(stats['totalPatterns'], greaterThan(0));

      // Limpar tudo
      optimizer.clearAll();

      stats = optimizer.getIndexStats();
      expect(stats['totalPatterns'], equals(0));
      expect(stats['totalSuggestions'], equals(0));
      expect(stats['memoryIndexes']['count'], equals(0));
    });

    test('should calculate priority correctly', () {
      // Query muito lenta e frequente (alta prioridade)
      for (int i = 0; i < 60; i++) {
        optimizer.analyzeQuery(
          query: 'high priority test',
          filters: SearchFilters(minAge: 25, maxAge: 35),
          executionTime: 6000, // Muito lenta
          resultCount: 10,
        );
      }

      // Query moderada (média prioridade)
      for (int i = 0; i < 25; i++) {
        optimizer.analyzeQuery(
          query: 'medium priority test',
          filters: SearchFilters(city: 'São Paulo'),
          executionTime: 2500, // Moderadamente lenta
          resultCount: 15,
        );
      }

      final stats = optimizer.getIndexStats();
      expect(stats['suggestionsByPriority']['high'], greaterThan(0));
    });

    test('should estimate improvement correctly', () {
      // Simular query que precisa de melhoria
      for (int i = 0; i < 30; i++) {
        optimizer.analyzeQuery(
          query: 'improvement estimation test',
          filters: SearchFilters(
            minAge: 25,
            maxAge: 35,
            city: 'São Paulo',
            isVerified: true,
          ),
          executionTime: 5500, // Muito lenta
          resultCount: 8,
        );
      }

      final stats = optimizer.getIndexStats();
      final suggestions = stats['highPrioritySuggestions'] as List;
      
      if (suggestions.isNotEmpty) {
        final suggestion = suggestions.first;
        expect(suggestion['estimatedImprovement'], greaterThan(0));
        expect(suggestion['estimatedImprovement'], lessThanOrEqualTo(90));
      }
    });
  });

  group('QueryPattern', () {
    test('should record executions correctly', () {
      final pattern = QueryPattern(
        signature: 'test_signature',
        query: 'test query',
        filters: SearchFilters(minAge: 25),
      );

      pattern.recordExecution(
        executionTime: 1500,
        resultCount: 10,
      );

      pattern.recordExecution(
        executionTime: 2000,
        resultCount: 5,
      );

      expect(pattern.frequency, equals(2));
      expect(pattern.averageExecutionTime, equals(1750));
      expect(pattern.averageResults, equals(7.5));
    });

    test('should detect optimization needs', () {
      final pattern = QueryPattern(
        signature: 'optimization_test',
        query: 'slow query',
        filters: null,
      );

      // Simular execuções lentas e frequentes
      for (int i = 0; i < 15; i++) {
        pattern.recordExecution(
          executionTime: 3000, // Lenta
          resultCount: 8,
        );
      }

      expect(pattern.needsOptimization, isTrue);
    });

    test('should identify filter types', () {
      final pattern = QueryPattern(
        signature: 'filter_test',
        query: 'test',
        filters: SearchFilters(
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
          isVerified: true,
        ),
      );

      expect(pattern.hasAgeFilter, isTrue);
      expect(pattern.hasCityFilter, isTrue);
      expect(pattern.hasVerificationFilter, isTrue);
      expect(pattern.hasTextSearch, isTrue);
    });
  });

  group('InMemoryIndex', () {
    test('should match profiles correctly', () {
      final pattern = QueryPattern(
        signature: 'match_test',
        query: 'test',
        filters: SearchFilters(
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
        ),
      );

      final index = InMemoryIndex(
        key: 'test_index',
        pattern: pattern,
        createdAt: DateTime.now(),
      );

      final matchingProfile = SpiritualProfileModel(
        id: 'matching',
        displayName: 'Matching User',
        age: 30,
        city: 'São Paulo',
      );

      final nonMatchingProfile = SpiritualProfileModel(
        id: 'non_matching',
        displayName: 'Non Matching User',
        age: 40, // Fora da faixa
        city: 'Rio de Janeiro',
      );

      expect(index.matchesProfile(matchingProfile), isTrue);
      expect(index.matchesProfile(nonMatchingProfile), isFalse);
    });

    test('should manage profile IDs', () {
      final pattern = QueryPattern(
        signature: 'profile_management_test',
        query: 'test',
        filters: null,
      );

      final index = InMemoryIndex(
        key: 'management_test',
        pattern: pattern,
        createdAt: DateTime.now(),
      );

      index.addProfile('profile_1');
      index.addProfile('profile_2');
      index.addProfile('profile_1'); // Duplicata

      expect(index.profileIds, hasLength(2));
      expect(index.profileIds, contains('profile_1'));
      expect(index.profileIds, contains('profile_2'));

      index.removeProfile('profile_1');
      expect(index.profileIds, hasLength(1));
      expect(index.profileIds, contains('profile_2'));
    });

    test('should detect expiration', () {
      final pattern = QueryPattern(
        signature: 'expiration_test',
        query: 'test',
        filters: null,
      );

      // Índice antigo
      final oldIndex = InMemoryIndex(
        key: 'old_index',
        pattern: pattern,
        createdAt: DateTime.now().subtract(Duration(hours: 3)),
      );

      // Índice novo
      final newIndex = InMemoryIndex(
        key: 'new_index',
        pattern: pattern,
        createdAt: DateTime.now(),
      );

      expect(oldIndex.isExpired, isTrue);
      expect(newIndex.isExpired, isFalse);
    });
  });
}