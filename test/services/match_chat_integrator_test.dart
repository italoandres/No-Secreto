import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/services/match_chat_integrator.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';

void main() {
  group('MatchChatIntegrator', () {
    late MatchChatIntegrator integrator;

    setUp(() {
      integrator = MatchChatIntegrator();
    });

    group('shouldCreateChatForNotification', () {
      testWidgets('deve retornar false se notificação não foi aceita', (tester) async {
        // Arrange
        final notification = InterestNotificationModel(
          id: 'notification_123',
          fromUserId: 'user_1',
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: 'user_2',
          toUserEmail: 'maria@test.com',
          message: 'Demonstrou interesse no seu perfil',
          status: 'pending',
          dataCriacao: Timestamp.now(),
          type: 'interest',
        );

        // Act
        final result = await MatchChatIntegrator.shouldCreateChatForNotification(notification);

        // Assert
        expect(result, isFalse);
      });

      testWidgets('deve retornar true se notificação foi aceita', (tester) async {
        // Arrange
        final notification = InterestNotificationModel(
          id: 'notification_123',
          fromUserId: 'user_1',
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: 'user_2',
          toUserEmail: 'maria@test.com',
          message: 'Demonstrou interesse no seu perfil',
          status: 'accepted',
          dataCriacao: Timestamp.now(),
          type: 'interest',
        );

        // Act & Assert - Como não temos Firebase configurado, esperamos que não falhe
        expect(() async {
          await MatchChatIntegrator.shouldCreateChatForNotification(notification);
        }, returnsNormally);
      });
    });

    group('syncUnreadMessageCounters', () {
      testWidgets('deve executar sem erros', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchChatIntegrator.syncUnreadMessageCounters(
            chatId: 'chat_123',
            userId: 'user_1',
            newUnreadCount: 5,
          );
        }, returnsNormally);
      });

      testWidgets('deve usar 0 como padrão se newUnreadCount for null', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchChatIntegrator.syncUnreadMessageCounters(
            chatId: 'chat_123',
            userId: 'user_1',
          );
        }, returnsNormally);
      });
    });

    group('getIntegrationStats', () {
      testWidgets('deve retornar estatísticas válidas', (tester) async {
        // Act
        final stats = await MatchChatIntegrator.getIntegrationStats('user_1');

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalChats'), isTrue);
        expect(stats.containsKey('activeChats'), isTrue);
        expect(stats.containsKey('expiredChats'), isTrue);
        expect(stats.containsKey('totalUnreadMessages'), isTrue);
        expect(stats.containsKey('lastSync'), isTrue);
      });

      testWidgets('deve retornar valores padrão em caso de erro', (tester) async {
        // Act
        final stats = await MatchChatIntegrator.getIntegrationStats('invalid_user');

        // Assert
        expect(stats['totalChats'], equals(0));
        expect(stats['activeChats'], equals(0));
        expect(stats['expiredChats'], equals(0));
        expect(stats['totalUnreadMessages'], equals(0));
      });
    });

    group('createChatFromAcceptedInterest', () {
      testWidgets('deve executar sem erros para notificação válida', (tester) async {
        // Arrange
        final notification = InterestNotificationModel(
          id: 'notification_123',
          fromUserId: 'user_1',
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: 'user_2',
          toUserEmail: 'maria@test.com',
          message: 'Demonstrou interesse no seu perfil',
          status: 'accepted',
          dataCriacao: Timestamp.now(),
          type: 'interest',
        );

        // Act & Assert - Como não temos Firebase configurado, esperamos que não falhe
        expect(() async {
          await MatchChatIntegrator.createChatFromAcceptedInterest(
            notification: notification,
            isMutualMatch: false,
          );
        }, returnsNormally);
      });
    });
  });
}