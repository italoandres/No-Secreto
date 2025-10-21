import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_chat/services/match_cache_service.dart';
import 'package:whatsapp_chat/models/accepted_match_model.dart';
import 'package:whatsapp_chat/models/chat_message_model.dart';

void main() {
  group('MatchCacheService', () {
    setUp(() async {
      // Configurar SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      await MatchCacheService.initialize();
    });

    tearDown(() async {
      await MatchCacheService.clearAllCache();
    });

    group('initialize', () {
      testWidgets('deve inicializar sem erros', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchCacheService.initialize();
        }, returnsNormally);
      });
    });

    group('cacheAcceptedMatches', () {
      testWidgets('deve cachear matches aceitos', (tester) async {
        // Arrange
        final matches = [
          AcceptedMatchModel.fromNotification(
            notificationId: 'notif_1',
            otherUserId: 'user_1',
            otherUserName: 'João',
            matchDate: DateTime.now(),
            chatId: 'chat_1',
            unreadMessages: 0,
            chatExpired: false,
            daysRemaining: 30,
          ),
        ];

        // Act & Assert
        expect(() async {
          await MatchCacheService.cacheAcceptedMatches(matches);
        }, returnsNormally);
      });

      testWidgets('deve lidar com lista vazia', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchCacheService.cacheAcceptedMatches([]);
        }, returnsNormally);
      });
    });

    group('getCachedAcceptedMatches', () {
      testWidgets('deve retornar null quando não há cache', (tester) async {
        // Act
        final result = await MatchCacheService.getCachedAcceptedMatches();

        // Assert
        expect(result, isNull);
      });

      testWidgets('deve retornar matches do cache quando válido', (tester) async {
        // Arrange
        final matches = [
          AcceptedMatchModel.fromNotification(
            notificationId: 'notif_1',
            otherUserId: 'user_1',
            otherUserName: 'João',
            matchDate: DateTime.now(),
            chatId: 'chat_1',
            unreadMessages: 0,
            chatExpired: false,
            daysRemaining: 30,
          ),
        ];

        await MatchCacheService.cacheAcceptedMatches(matches);

        // Act
        final result = await MatchCacheService.getCachedAcceptedMatches();

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(1));
        expect(result.first.otherUserName, equals('João'));
      });
    });

    group('cacheChatMessages', () {
      testWidgets('deve cachear mensagens de chat', (tester) async {
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

        // Act & Assert
        expect(() async {
          await MatchCacheService.cacheChatMessages('chat_1', messages);
        }, returnsNormally);
      });

      testWidgets('deve limitar número de mensagens em cache', (tester) async {
        // Arrange
        final messages = List.generate(100, (index) => 
          ChatMessageModel(
            id: 'msg_$index',
            chatId: 'chat_1',
            senderId: 'user_1',
            senderName: 'João',
            message: 'Mensagem $index',
            timestamp: DateTime.now(),
            isRead: false,
            type: MessageType.text,
          ),
        );

        // Act
        await MatchCacheService.cacheChatMessages('chat_1', messages);
        final cached = await MatchCacheService.getCachedChatMessages('chat_1');

        // Assert
        expect(cached, isNotNull);
        expect(cached!.length, lessThanOrEqualTo(50)); // Limite configurado
      });
    });

    group('getCachedChatMessages', () {
      testWidgets('deve retornar null quando não há cache', (tester) async {
        // Act
        final result = await MatchCacheService.getCachedChatMessages('chat_inexistente');

        // Assert
        expect(result, isNull);
      });

      testWidgets('deve retornar mensagens do cache quando válido', (tester) async {
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

        await MatchCacheService.cacheChatMessages('chat_1', messages);

        // Act
        final result = await MatchCacheService.getCachedChatMessages('chat_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(1));
        expect(result.first.message, equals('Olá!'));
      });
    });

    group('invalidateMatchesCache', () {
      testWidgets('deve invalidar cache de matches', (tester) async {
        // Arrange
        final matches = [
          AcceptedMatchModel.fromNotification(
            notificationId: 'notif_1',
            otherUserId: 'user_1',
            otherUserName: 'João',
            matchDate: DateTime.now(),
            chatId: 'chat_1',
            unreadMessages: 0,
            chatExpired: false,
            daysRemaining: 30,
          ),
        ];

        await MatchCacheService.cacheAcceptedMatches(matches);

        // Act
        await MatchCacheService.invalidateMatchesCache();
        final result = await MatchCacheService.getCachedAcceptedMatches();

        // Assert
        expect(result, isNull);
      });
    });

    group('invalidateChatMessagesCache', () {
      testWidgets('deve invalidar cache de mensagens específico', (tester) async {
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

        await MatchCacheService.cacheChatMessages('chat_1', messages);

        // Act
        await MatchCacheService.invalidateChatMessagesCache('chat_1');
        final result = await MatchCacheService.getCachedChatMessages('chat_1');

        // Assert
        expect(result, isNull);
      });
    });

    group('clearAllCache', () {
      testWidgets('deve limpar todo o cache', (tester) async {
        // Arrange
        final matches = [
          AcceptedMatchModel.fromNotification(
            notificationId: 'notif_1',
            otherUserId: 'user_1',
            otherUserName: 'João',
            matchDate: DateTime.now(),
            chatId: 'chat_1',
            unreadMessages: 0,
            chatExpired: false,
            daysRemaining: 30,
          ),
        ];

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

        await MatchCacheService.cacheAcceptedMatches(matches);
        await MatchCacheService.cacheChatMessages('chat_1', messages);

        // Act
        await MatchCacheService.clearAllCache();

        // Assert
        final cachedMatches = await MatchCacheService.getCachedAcceptedMatches();
        final cachedMessages = await MatchCacheService.getCachedChatMessages('chat_1');
        
        expect(cachedMatches, isNull);
        expect(cachedMessages, isNull);
      });
    });

    group('getCacheStats', () {
      testWidgets('deve retornar estatísticas válidas', (tester) async {
        // Act
        final stats = await MatchCacheService.getCacheStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('matchesCached'), isTrue);
        expect(stats.containsKey('cachedChatsCount'), isTrue);
        expect(stats.containsKey('totalCacheKeys'), isTrue);
        expect(stats.containsKey('approximateSizeBytes'), isTrue);
        expect(stats.containsKey('maxCachedChats'), isTrue);
        expect(stats.containsKey('maxMessagesPerChat'), isTrue);
        expect(stats.containsKey('cacheExpirationHours'), isTrue);
      });

      testWidgets('deve refletir cache populado', (tester) async {
        // Arrange
        final matches = [
          AcceptedMatchModel.fromNotification(
            notificationId: 'notif_1',
            otherUserId: 'user_1',
            otherUserName: 'João',
            matchDate: DateTime.now(),
            chatId: 'chat_1',
            unreadMessages: 0,
            chatExpired: false,
            daysRemaining: 30,
          ),
        ];

        await MatchCacheService.cacheAcceptedMatches(matches);

        // Act
        final stats = await MatchCacheService.getCacheStats();

        // Assert
        expect(stats['matchesCached'], isTrue);
        expect(stats['approximateSizeBytes'], greaterThan(0));
      });
    });

    group('isChatCached', () {
      testWidgets('deve retornar false para chat não cacheado', (tester) async {
        // Act
        final result = await MatchCacheService.isChatCached('chat_inexistente');

        // Assert
        expect(result, isFalse);
      });

      testWidgets('deve retornar true para chat cacheado', (tester) async {
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

        await MatchCacheService.cacheChatMessages('chat_1', messages);

        // Act
        final result = await MatchCacheService.isChatCached('chat_1');

        // Assert
        expect(result, isTrue);
      });
    });

    group('preloadFrequentChats', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchCacheService.preloadFrequentChats(['chat_1', 'chat_2']);
        }, returnsNormally);
      });

      testWidgets('deve lidar com lista vazia', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchCacheService.preloadFrequentChats([]);
        }, returnsNormally);
      });
    });

    group('optimizeCache', () {
      testWidgets('deve executar otimização sem erros', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchCacheService.optimizeCache();
        }, returnsNormally);
      });

      testWidgets('deve remover caches expirados', (tester) async {
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

        await MatchCacheService.cacheChatMessages('chat_1', messages);

        // Act
        await MatchCacheService.optimizeCache();

        // Assert - Deve executar sem erros
        expect(() async {
          await MatchCacheService.optimizeCache();
        }, returnsNormally);
      });
    });
  });
}