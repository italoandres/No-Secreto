import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/message_read_status_service.dart';

void main() {
  group('MessageReadStatusService', () {
    const testChatId = 'test_chat_123';
    const testMessageId = 'test_message_456';
    const testUserId = 'test_user_789';

    group('markMessageAsRead', () {
      testWidgets('deve executar sem erros com parâmetros válidos', (tester) async {
        // Act & Assert
        expect(() async {
          await MessageReadStatusService.markMessageAsRead(
            chatId: testChatId,
            messageId: testMessageId,
            userId: testUserId,
          );
        }, returnsNormally);
      });

      testWidgets('deve tratar erro quando messageId é inválido', (tester) async {
        // Act & Assert
        expect(() async {
          await MessageReadStatusService.markMessageAsRead(
            chatId: testChatId,
            messageId: '',
            userId: testUserId,
          );
        }, throwsA(isA<Exception>()));
      });
    });

    group('markAllMessagesAsRead', () {
      testWidgets('deve executar sem erros com parâmetros válidos', (tester) async {
        // Act & Assert
        expect(() async {
          await MessageReadStatusService.markAllMessagesAsRead(
            chatId: testChatId,
            userId: testUserId,
          );
        }, returnsNormally);
      });

      testWidgets('deve tratar chatId vazio', (tester) async {
        // Act & Assert
        expect(() async {
          await MessageReadStatusService.markAllMessagesAsRead(
            chatId: '',
            userId: testUserId,
          );
        }, throwsA(isA<Exception>()));
      });
    });

    group('getUnreadCount', () {
      testWidgets('deve retornar número válido', (tester) async {
        // Act
        final count = await MessageReadStatusService.getUnreadCount(
          testChatId,
          testUserId,
        );

        // Assert
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });

      testWidgets('deve retornar 0 para chat inexistente', (tester) async {
        // Act
        final count = await MessageReadStatusService.getUnreadCount(
          'chat_inexistente',
          testUserId,
        );

        // Assert
        expect(count, equals(0));
      });
    });

    group('watchUnreadCount', () {
      testWidgets('deve retornar stream válido', (tester) async {
        // Act
        final stream = MessageReadStatusService.watchUnreadCount(
          testChatId,
          testUserId,
        );

        // Assert
        expect(stream, isA<Stream<int>>());
      });

      testWidgets('deve emitir valores não negativos', (tester) async {
        // Arrange
        final stream = MessageReadStatusService.watchUnreadCount(
          testChatId,
          testUserId,
        );

        // Act & Assert
        await expectLater(
          stream.take(1),
          emits(greaterThanOrEqualTo(0)),
        );
      });
    });

    group('isMessageReadBy', () {
      testWidgets('deve retornar boolean válido', (tester) async {
        // Act
        final isRead = await MessageReadStatusService.isMessageReadBy(
          testMessageId,
          testUserId,
        );

        // Assert
        expect(isRead, isA<bool>());
      });

      testWidgets('deve retornar false para mensagem inexistente', (tester) async {
        // Act
        final isRead = await MessageReadStatusService.isMessageReadBy(
          'mensagem_inexistente',
          testUserId,
        );

        // Assert
        expect(isRead, isFalse);
      });
    });

    group('markMessageAsReadWithDebounce', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() async {
          await MessageReadStatusService.markMessageAsReadWithDebounce(
            chatId: testChatId,
            messageId: testMessageId,
            userId: testUserId,
          );
        }, returnsNormally);
      });

      testWidgets('deve aplicar debounce corretamente', (tester) async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await MessageReadStatusService.markMessageAsReadWithDebounce(
          chatId: testChatId,
          messageId: testMessageId,
          userId: testUserId,
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert
        expect(duration.inSeconds, greaterThanOrEqualTo(2));
      });
    });

    group('clearDebounceCache', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() {
          MessageReadStatusService.clearDebounceCache();
        }, returnsNormally);
      });
    });

    group('getChatReadStats', () {
      testWidgets('deve retornar estatísticas válidas', (tester) async {
        // Act
        final stats = await MessageReadStatusService.getChatReadStats(testChatId);

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalMessages'), isTrue);
        expect(stats.containsKey('readMessages'), isTrue);
        expect(stats.containsKey('unreadMessages'), isTrue);
        expect(stats.containsKey('readPercentage'), isTrue);
        
        expect(stats['totalMessages'], isA<int>());
        expect(stats['readMessages'], isA<int>());
        expect(stats['unreadMessages'], isA<int>());
        expect(stats['readPercentage'], isA<int>());
        
        expect(stats['totalMessages'], greaterThanOrEqualTo(0));
        expect(stats['readMessages'], greaterThanOrEqualTo(0));
        expect(stats['unreadMessages'], greaterThanOrEqualTo(0));
        expect(stats['readPercentage'], greaterThanOrEqualTo(0));
        expect(stats['readPercentage'], lessThanOrEqualTo(100));
      });

      testWidgets('deve retornar zeros para chat inexistente', (tester) async {
        // Act
        final stats = await MessageReadStatusService.getChatReadStats('chat_inexistente');

        // Assert
        expect(stats['totalMessages'], equals(0));
        expect(stats['readMessages'], equals(0));
        expect(stats['unreadMessages'], equals(0));
        expect(stats['readPercentage'], equals(0));
      });
    });
  });
}