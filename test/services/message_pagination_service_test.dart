import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/message_pagination_service.dart';
import 'package:whatsapp_chat/models/chat_message_model.dart';

void main() {
  group('PaginationConfig', () {
    testWidgets('deve ter configuração padrão válida', (tester) async {
      // Arrange & Act
      const config = PaginationConfig.defaultConfig;

      // Assert
      expect(config.pageSize, equals(20));
      expect(config.maxPages, equals(10));
      expect(config.cacheTimeout, equals(const Duration(minutes: 5)));
    });

    testWidgets('deve ter configuração de carregamento inicial válida', (tester) async {
      // Arrange & Act
      const config = PaginationConfig.initialLoad;

      // Assert
      expect(config.pageSize, equals(50));
      expect(config.maxPages, equals(5));
    });

    testWidgets('deve ter configuração de carregamento rápido válida', (tester) async {
      // Arrange & Act
      const config = PaginationConfig.quickLoad;

      // Assert
      expect(config.pageSize, equals(10));
      expect(config.maxPages, equals(20));
    });

    testWidgets('deve permitir configuração personalizada', (tester) async {
      // Arrange & Act
      const config = PaginationConfig(
        pageSize: 15,
        maxPages: 8,
        cacheTimeout: Duration(minutes: 3),
      );

      // Assert
      expect(config.pageSize, equals(15));
      expect(config.maxPages, equals(8));
      expect(config.cacheTimeout, equals(const Duration(minutes: 3)));
    });
  });

  group('MessagePage', () {
    testWidgets('deve criar página com parâmetros obrigatórios', (tester) async {
      // Arrange
      final messages = [
        ChatMessageModel(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          senderName: 'João',
          message: 'Olá!',
          timestamp: DateTime.now(),
          isRead: false,
          type: MessageType.text,
        ),
      ];

      // Act
      final page = MessagePage(
        messages: messages,
        hasMore: true,
        pageNumber: 1,
      );

      // Assert
      expect(page.messages.length, equals(1));
      expect(page.hasMore, isTrue);
      expect(page.pageNumber, equals(1));
      expect(page.lastDocument, isNull);
      expect(page.loadedAt, isA<DateTime>());
    });

    testWidgets('deve ter toString informativo', (tester) async {
      // Arrange
      final messages = [
        ChatMessageModel(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          senderName: 'João',
          message: 'Olá!',
          timestamp: DateTime.now(),
          isRead: false,
          type: MessageType.text,
        ),
      ];

      final page = MessagePage(
        messages: messages,
        hasMore: false,
        pageNumber: 2,
      );

      // Act
      final string = page.toString();

      // Assert
      expect(string, contains('MessagePage'));
      expect(string, contains('messages: 1'));
      expect(string, contains('hasMore: false'));
      expect(string, contains('page: 2'));
    });
  });

  group('MessagePaginationService', () {
    setUp(() {
      MessagePaginationService.clearAllCache();
    });

    tearDown(() {
      MessagePaginationService.clearAllCache();
    });

    group('getAllLoadedMessages', () {
      testWidgets('deve retornar lista vazia quando não há cache', (tester) async {
        // Act
        final messages = MessagePaginationService.getAllLoadedMessages('chat_inexistente');

        // Assert
        expect(messages, isEmpty);
      });
    });

    group('hasMorePages', () {
      testWidgets('deve retornar true quando não há cache', (tester) async {
        // Act
        final hasMore = MessagePaginationService.hasMorePages('chat_inexistente');

        // Assert
        expect(hasMore, isTrue);
      });
    });

    group('getLoadedPagesCount', () {
      testWidgets('deve retornar 0 quando não há cache', (tester) async {
        // Act
        final count = MessagePaginationService.getLoadedPagesCount('chat_inexistente');

        // Assert
        expect(count, equals(0));
      });
    });

    group('getTotalLoadedMessages', () {
      testWidgets('deve retornar 0 quando não há cache', (tester) async {
        // Act
        final count = MessagePaginationService.getTotalLoadedMessages('chat_inexistente');

        // Assert
        expect(count, equals(0));
      });
    });

    group('invalidateCache', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() {
          MessagePaginationService.invalidateCache('chat_1');
        }, returnsNormally);
      });
    });

    group('clearAllCache', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() {
          MessagePaginationService.clearAllCache();
        }, returnsNormally);
      });
    });

    group('optimizeCache', () {
      testWidgets('deve executar otimização sem erros', (tester) async {
        // Act & Assert
        expect(() {
          MessagePaginationService.optimizeCache();
        }, returnsNormally);
      });

      testWidgets('deve aceitar parâmetros personalizados', (tester) async {
        // Act & Assert
        expect(() {
          MessagePaginationService.optimizeCache(
            maxAge: const Duration(minutes: 5),
            maxChatsInCache: 5,
          );
        }, returnsNormally);
      });
    });

    group('getPaginationStats', () {
      testWidgets('deve retornar estatísticas válidas', (tester) async {
        // Act
        final stats = MessagePaginationService.getPaginationStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalChatsInCache'), isTrue);
        expect(stats.containsKey('totalPages'), isTrue);
        expect(stats.containsKey('totalMessages'), isTrue);
        expect(stats.containsKey('averagePagesPerChat'), isTrue);
        expect(stats.containsKey('averageMessagesPerChat'), isTrue);
        expect(stats.containsKey('chatStats'), isTrue);
      });

      testWidgets('deve retornar zeros quando cache vazio', (tester) async {
        // Act
        final stats = MessagePaginationService.getPaginationStats();

        // Assert
        expect(stats['totalChatsInCache'], equals(0));
        expect(stats['totalPages'], equals(0));
        expect(stats['totalMessages'], equals(0));
        expect(stats['averagePagesPerChat'], equals(0));
        expect(stats['averageMessagesPerChat'], equals(0));
      });
    });

    // Métodos que dependem do Firebase são testados em testes de integração
  });
}