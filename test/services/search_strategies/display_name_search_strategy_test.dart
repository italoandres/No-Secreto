import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/search_strategies/display_name_search_strategy.dart';
import '../../../lib/models/search_filters.dart';

void main() {
  group('DisplayNameSearchStrategy', () {
    late DisplayNameSearchStrategy strategy;
    
    setUp(() {
      strategy = DisplayNameSearchStrategy();
    });
    
    test('should have correct properties', () {
      expect(strategy.name, equals('Display Name Search'));
      expect(strategy.priority, equals(2));
      expect(strategy.isAvailable, isTrue);
    });
    
    test('should handle filters correctly', () {
      expect(strategy.canHandleFilters(null), isTrue);
      
      final filters = SearchFilters(
        minAge: 25,
        maxAge: 45,
        city: 'São Paulo',
        interests: ['música', 'leitura'],
      );
      
      expect(strategy.canHandleFilters(filters), isTrue);
    });
    
    test('should estimate execution time correctly', () {
      // Query curta
      final shortQueryTime = strategy.estimateExecutionTime('João', null);
      expect(shortQueryTime, equals(300)); // Base time
      
      // Query longa
      final longQueryTime = strategy.estimateExecutionTime('João Silva Santos', null);
      expect(longQueryTime, equals(350)); // Base + 50 for long name
      
      // Com filtros
      final filters = SearchFilters(minAge: 25);
      final withFiltersTime = strategy.estimateExecutionTime('João', filters);
      expect(withFiltersTime, equals(400)); // Base + 100 for filters
    });
    
    group('isNameQuery', () {
      test('should identify valid name queries', () {
        expect(DisplayNameSearchStrategy.isNameQuery('João'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('Maria Silva'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('José da Silva'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('Ana-Maria'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('O\'Connor'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('Dr. Silva'), isTrue);
      });
      
      test('should reject invalid name queries', () {
        // Muito curto
        expect(DisplayNameSearchStrategy.isNameQuery('A'), isFalse);
        
        // Muito longo
        expect(DisplayNameSearchStrategy.isNameQuery('A' * 51), isFalse);
        
        // Contém números
        expect(DisplayNameSearchStrategy.isNameQuery('João123'), isFalse);
        
        // Contém símbolos especiais
        expect(DisplayNameSearchStrategy.isNameQuery('João@Silva'), isFalse);
        expect(DisplayNameSearchStrategy.isNameQuery('João#Silva'), isFalse);
        
        // Muitas palavras
        expect(DisplayNameSearchStrategy.isNameQuery('Um nome muito longo com muitas palavras aqui'), isFalse);
        
        // String vazia
        expect(DisplayNameSearchStrategy.isNameQuery(''), isFalse);
        expect(DisplayNameSearchStrategy.isNameQuery('   '), isFalse);
      });
      
      test('should handle edge cases', () {
        // Acentos são válidos
        expect(DisplayNameSearchStrategy.isNameQuery('José'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('María'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('François'), isTrue);
        
        // Espaços extras
        expect(DisplayNameSearchStrategy.isNameQuery('  João Silva  '), isTrue);
        
        // Nomes compostos
        expect(DisplayNameSearchStrategy.isNameQuery('Ana Paula'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('João Pedro Silva'), isTrue);
        expect(DisplayNameSearchStrategy.isNameQuery('Maria da Conceição'), isTrue);
      });
    });
    
    // Nota: Testes que requerem Firebase seriam implementados em testes de integração
    // pois precisam de configuração específica do Firebase Emulator
    
    test('should provide correct stats structure', () {
      final stats = strategy.getStats();
      
      expect(stats['name'], equals('Display Name Search'));
      expect(stats['priority'], equals(2));
      expect(stats['isAvailable'], isTrue);
    });
  });
}