import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/search_strategies/search_strategy.dart';
import '../../../lib/models/search_filters.dart';
import '../../../lib/models/search_result.dart';
import '../../../lib/models/spiritual_profile_model.dart';

// Implementação de teste da SearchStrategy
class TestSearchStrategy extends BaseSearchStrategy {
  final bool _shouldFail;
  final List<SpiritualProfileModel> _mockProfiles;
  
  TestSearchStrategy({
    String name = 'Test Strategy',
    int priority = 1,
    bool shouldFail = false,
    List<SpiritualProfileModel>? mockProfiles,
  }) : _shouldFail = shouldFail,
       _mockProfiles = mockProfiles ?? [],
       super(name: name, priority: priority);
  
  @override
  Future<SearchResult> executeSearch({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    if (_shouldFail) {
      throw SearchStrategyException(
        message: 'Test failure',
        strategyName: name,
      );
    }
    
    // Simular delay
    await Future.delayed(Duration(milliseconds: 10));
    
    return SearchResult(
      profiles: _mockProfiles.take(limit).toList(),
      query: query,
      totalResults: _mockProfiles.length,
      hasMore: _mockProfiles.length > limit,
      appliedFilters: filters,
      strategy: name,
      executionTime: 10,
      fromCache: false,
    );
  }
}

void main() {
  group('SearchStrategy', () {
    late TestSearchStrategy strategy;
    
    setUp(() {
      strategy = TestSearchStrategy();
    });
    
    test('should have correct basic properties', () {
      expect(strategy.name, equals('Test Strategy'));
      expect(strategy.priority, equals(1));
      expect(strategy.isAvailable, isTrue);
    });
    
    test('should execute search successfully', () async {
      final mockProfiles = [
        SpiritualProfileModel(
          id: '1',
          displayName: 'João Silva',
          isActive: true,
        ),
        SpiritualProfileModel(
          id: '2',
          displayName: 'Maria Santos',
          isActive: true,
        ),
      ];
      
      final testStrategy = TestSearchStrategy(mockProfiles: mockProfiles);
      
      final result = await testStrategy.search(
        query: 'test',
        limit: 10,
      );
      
      expect(result.profiles, hasLength(2));
      expect(result.query, equals('test'));
      expect(result.strategy, equals('Test Strategy'));
      expect(result.executionTime, greaterThan(0));
    });
    
    test('should handle search failure', () async {
      final failingStrategy = TestSearchStrategy(shouldFail: true);
      
      expect(
        () => failingStrategy.search(query: 'test'),
        throwsA(isA<SearchStrategyException>()),
      );
    });
    
    test('should track statistics correctly', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];
      
      final testStrategy = TestSearchStrategy(mockProfiles: mockProfiles);
      
      // Executar algumas buscas
      await testStrategy.search(query: 'test1');
      await testStrategy.search(query: 'test2');
      
      final stats = testStrategy.getStats();
      
      expect(stats['attempts'], equals(2));
      expect(stats['successes'], equals(2));
      expect(stats['failures'], equals(0));
      expect(stats['successRate'], equals('100.0'));
      expect(stats['averageExecutionTime'], greaterThan(0));
    });
    
    test('should track failures in statistics', () async {
      final failingStrategy = TestSearchStrategy(shouldFail: true);
      
      try {
        await failingStrategy.search(query: 'test');
      } catch (e) {
        // Esperado
      }
      
      final stats = failingStrategy.getStats();
      
      expect(stats['attempts'], equals(1));
      expect(stats['successes'], equals(0));
      expect(stats['failures'], equals(1));
      expect(stats['successRate'], equals('0.0'));
    });
    
    test('should estimate execution time based on history', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];
      
      final testStrategy = TestSearchStrategy(mockProfiles: mockProfiles);
      
      // Antes de qualquer execução, deve usar estimativa baseada na prioridade
      final initialEstimate = testStrategy.estimateExecutionTime('test', null);
      expect(initialEstimate, equals(100)); // priority * 100
      
      // Após execução, deve usar média histórica
      await testStrategy.search(query: 'test');
      
      final historicalEstimate = testStrategy.estimateExecutionTime('test', null);
      expect(historicalEstimate, greaterThan(0));
      expect(historicalEstimate, lessThan(100)); // Deve ser menor que a estimativa inicial
    });
    
    test('should handle canHandleFilters correctly', () {
      expect(strategy.canHandleFilters(null), isTrue);
      
      final filters = SearchFilters(
        minAge: 18,
        maxAge: 65,
        city: 'São Paulo',
      );
      
      expect(strategy.canHandleFilters(filters), isTrue);
    });
    
    test('should handle clearCache correctly', () {
      expect(() => strategy.clearCache(), returnsNormally);
    });
    
    test('should provide complete stats structure', () {
      final stats = strategy.getStats();
      
      expect(stats, containsPair('name', 'Test Strategy'));
      expect(stats, containsPair('priority', 1));
      expect(stats, containsPair('attempts', 0));
      expect(stats, containsPair('successes', 0));
      expect(stats, containsPair('failures', 0));
      expect(stats, containsPair('successRate', '0.0'));
      expect(stats, containsPair('averageExecutionTime', 0));
      expect(stats, containsPair('totalExecutionTime', 0));
      expect(stats, containsPair('isAvailable', true));
      expect(stats, contains('lastUsed'));
    });
  });
  
  group('SearchStrategyException', () {
    test('should create exception with correct properties', () {
      const exception = SearchStrategyException(
        message: 'Test error',
        strategyName: 'Test Strategy',
        originalError: 'Original error',
      );
      
      expect(exception.message, equals('Test error'));
      expect(exception.strategyName, equals('Test Strategy'));
      expect(exception.originalError, equals('Original error'));
    });
    
    test('should have correct toString representation', () {
      const exception = SearchStrategyException(
        message: 'Test error',
        strategyName: 'Test Strategy',
      );
      
      expect(exception.toString(), equals('SearchStrategyException [Test Strategy]: Test error'));
    });
  });
}