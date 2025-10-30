import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/services/match_loading_manager.dart';

void main() {
  group('LoadingState', () {
    testWidgets('deve criar estado com parâmetros obrigatórios', (tester) async {
      // Arrange & Act
      final state = LoadingState(
        type: LoadingType.loadingMessages,
        isLoading: true,
      );

      // Assert
      expect(state.type, equals(LoadingType.loadingMessages));
      expect(state.isLoading, isTrue);
      expect(state.message, isNull);
      expect(state.timestamp, isA<DateTime>());
      expect(state.operationId, isNull);
    });

    testWidgets('deve criar estado com todos os parâmetros', (tester) async {
      // Arrange
      final timestamp = DateTime.now();

      // Act
      final state = LoadingState(
        type: LoadingType.sendingMessage,
        isLoading: false,
        message: 'Enviando...',
        timestamp: timestamp,
        operationId: 'op_123',
      );

      // Assert
      expect(state.type, equals(LoadingType.sendingMessage));
      expect(state.isLoading, isFalse);
      expect(state.message, equals('Enviando...'));
      expect(state.timestamp, equals(timestamp));
      expect(state.operationId, equals('op_123'));
    });

    testWidgets('deve criar cópia com modificações', (tester) async {
      // Arrange
      final original = LoadingState(
        type: LoadingType.loadingMatches,
        isLoading: true,
        message: 'Carregando...',
      );

      // Act
      final copy = original.copyWith(
        isLoading: false,
        message: 'Concluído',
      );

      // Assert
      expect(copy.type, equals(original.type));
      expect(copy.isLoading, isFalse);
      expect(copy.message, equals('Concluído'));
      expect(copy.timestamp, equals(original.timestamp));
      expect(copy.operationId, equals(original.operationId));
    });

    testWidgets('deve ter toString informativo', (tester) async {
      // Arrange
      final state = LoadingState(
        type: LoadingType.refreshing,
        isLoading: true,
        message: 'Atualizando...',
      );

      // Act
      final string = state.toString();

      // Assert
      expect(string, contains('LoadingState'));
      expect(string, contains('refreshing'));
      expect(string, contains('true'));
      expect(string, contains('Atualizando...'));
    });
  });

  group('MatchLoadingManager', () {
    late MatchLoadingManager manager;

    setUp(() {
      Get.reset();
      manager = MatchLoadingManager();
      Get.put(manager);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('deve inicializar sem loading ativo', (tester) async {
      // Assert
      expect(manager.hasAnyLoading, isFalse);
      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
      expect(manager.getLoadingState(LoadingType.loadingMessages), isNull);
    });

    testWidgets('deve iniciar loading corretamente', (tester) async {
      // Act
      manager.startLoading(LoadingType.loadingMessages, message: 'Carregando...');

      // Assert
      expect(manager.isLoading(LoadingType.loadingMessages), isTrue);
      expect(manager.hasAnyLoading, isTrue);
      expect(manager.getLoadingMessage(LoadingType.loadingMessages), equals('Carregando...'));
      
      final state = manager.getLoadingState(LoadingType.loadingMessages);
      expect(state, isNotNull);
      expect(state!.isLoading, isTrue);
      expect(state.message, equals('Carregando...'));
    });

    testWidgets('deve parar loading corretamente', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.sendingMessage);

      // Act
      manager.stopLoading(LoadingType.sendingMessage);

      // Assert
      expect(manager.isLoading(LoadingType.sendingMessage), isFalse);
      expect(manager.hasAnyLoading, isFalse);
      
      final state = manager.getLoadingState(LoadingType.sendingMessage);
      expect(state!.isLoading, isFalse);
    });

    testWidgets('deve gerenciar múltiplos loadings', (tester) async {
      // Act
      manager.startLoading(LoadingType.loadingMessages);
      manager.startLoading(LoadingType.sendingMessage);

      // Assert
      expect(manager.isLoading(LoadingType.loadingMessages), isTrue);
      expect(manager.isLoading(LoadingType.sendingMessage), isTrue);
      expect(manager.hasAnyLoading, isTrue);

      // Act
      manager.stopLoading(LoadingType.loadingMessages);

      // Assert
      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
      expect(manager.isLoading(LoadingType.sendingMessage), isTrue);
      expect(manager.hasAnyLoading, isTrue);

      // Act
      manager.stopLoading(LoadingType.sendingMessage);

      // Assert
      expect(manager.hasAnyLoading, isFalse);
    });

    testWidgets('deve parar todos os loadings', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.loadingMessages);
      manager.startLoading(LoadingType.sendingMessage);
      manager.startLoading(LoadingType.refreshing);

      // Act
      manager.stopAllLoading();

      // Assert
      expect(manager.hasAnyLoading, isFalse);
      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
      expect(manager.isLoading(LoadingType.sendingMessage), isFalse);
      expect(manager.isLoading(LoadingType.refreshing), isFalse);
    });

    testWidgets('deve atualizar mensagem de loading', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.loadingMessages, message: 'Carregando...');

      // Act
      manager.updateLoadingMessage(LoadingType.loadingMessages, 'Quase pronto...');

      // Assert
      expect(manager.getLoadingMessage(LoadingType.loadingMessages), equals('Quase pronto...'));
    });

    testWidgets('deve executar operação com loading automático', (tester) async {
      // Arrange
      Future<String> operation() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'resultado';
      }

      // Act
      final result = await manager.withLoading(
        LoadingType.loadingMessages,
        operation,
        message: 'Processando...',
      );

      // Assert
      expect(result, equals('resultado'));
      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
    });

    testWidgets('deve parar loading mesmo com erro na operação', (tester) async {
      // Arrange
      Future<String> operation() async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw Exception('Erro de teste');
      }

      // Act & Assert
      expect(() async {
        await manager.withLoading(LoadingType.loadingMessages, operation);
      }, throwsException);

      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
    });

    testWidgets('deve executar múltiplas operações com loading', (tester) async {
      // Arrange
      Future<String> operation1() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'resultado1';
      }

      Future<String> operation2() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'resultado2';
      }

      // Act
      final results = await manager.withMultipleLoading(
        [LoadingType.loadingMessages, LoadingType.sendingMessage],
        [operation1, operation2],
        messages: ['Carregando 1...', 'Carregando 2...'],
      );

      // Assert
      expect(results, equals(['resultado1', 'resultado2']));
      expect(manager.isLoading(LoadingType.loadingMessages), isFalse);
      expect(manager.isLoading(LoadingType.sendingMessage), isFalse);
    });

    testWidgets('deve obter estados ativos de loading', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.loadingMessages);
      manager.startLoading(LoadingType.sendingMessage);
      manager.startLoading(LoadingType.refreshing);
      manager.stopLoading(LoadingType.refreshing);

      // Act
      final activeStates = manager.getActiveLoadingStates();

      // Assert
      expect(activeStates.length, equals(2));
      expect(activeStates.containsKey(LoadingType.loadingMessages), isTrue);
      expect(activeStates.containsKey(LoadingType.sendingMessage), isTrue);
      expect(activeStates.containsKey(LoadingType.refreshing), isFalse);
    });

    testWidgets('deve retornar estatísticas válidas', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.loadingMessages);
      manager.startLoading(LoadingType.sendingMessage);

      // Act
      final stats = manager.getLoadingStats();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['totalOperations'], equals(2));
      expect(stats['activeOperations'], equals(2));
      expect(stats['hasAnyLoading'], isTrue);
      expect(stats['activeTypes'], isA<List>());
      expect(stats['activeTypes'].length, equals(2));
    });

    testWidgets('deve limpar estados antigos', (tester) async {
      // Arrange
      manager.startLoading(LoadingType.loadingMessages);
      manager.stopLoading(LoadingType.loadingMessages);

      // Act
      manager.cleanupOldStates();

      // Assert - Deve executar sem erros
      expect(() => manager.cleanupOldStates(), returnsNormally);
    });
  });
}