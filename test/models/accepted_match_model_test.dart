import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/accepted_match_model.dart';

void main() {
  group('AcceptedMatchModel', () {
    const notificationId = 'notif_123';
    const otherUserId = 'user_456';
    const otherUserName = 'Maria Silva';
    const otherUserPhoto = 'https://example.com/photo.jpg';
    const chatId = 'chat_123_456';
    final matchDate = DateTime.now().subtract(const Duration(days: 5));
    
    test('should create from notification with correct properties', () {
      final match = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 3,
        daysRemaining: 25,
      );
      
      expect(match.notificationId, equals(notificationId));
      expect(match.otherUserId, equals(otherUserId));
      expect(match.otherUserName, equals(otherUserName));
      expect(match.otherUserPhoto, equals(otherUserPhoto));
      expect(match.chatId, equals(chatId));
      expect(match.unreadMessages, equals(3));
      expect(match.daysRemaining, equals(25));
    });
    
    test('should identify unread messages correctly', () {
      final matchWithUnread = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 5,
      );
      
      final matchWithoutUnread = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 0,
      );
      
      expect(matchWithUnread.hasUnreadMessages, isTrue);
      expect(matchWithoutUnread.hasUnreadMessages, isFalse);
    });
    
    test('should identify chat activity correctly', () {
      final activeChat = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        chatExpired: false,
        daysRemaining: 15,
      );
      
      final expiredChat = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        chatExpired: true,
        daysRemaining: 0,
      );
      
      expect(activeChat.isChatActive, isTrue);
      expect(expiredChat.isChatActive, isFalse);
    });
    
    test('should format chat status correctly', () {
      final expiredMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        chatExpired: true,
      );
      
      final oneDayMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        daysRemaining: 1,
      );
      
      final multipleDaysMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        daysRemaining: 15,
      );
      
      expect(expiredMatch.chatStatus, equals('Chat Expirado'));
      expect(oneDayMatch.chatStatus, equals('1 dia restante'));
      expect(multipleDaysMatch.chatStatus, equals('15 dias restantes'));
    });
    
    test('should determine status color correctly', () {
      final expiredMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        chatExpired: true,
      );
      
      final urgentMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        daysRemaining: 1,
      );
      
      final warningMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        daysRemaining: 5,
      );
      
      final activeMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        daysRemaining: 20,
      );
      
      expect(expiredMatch.statusColor, equals('red'));
      expect(urgentMatch.statusColor, equals('red'));
      expect(warningMatch.statusColor, equals('orange'));
      expect(activeMatch.statusColor, equals('green'));
    });
    
    test('should format unread text correctly', () {
      final noUnread = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 0,
      );
      
      final someUnread = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 5,
      );
      
      final manyUnread = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 150,
      );
      
      expect(noUnread.unreadText, equals(''));
      expect(someUnread.unreadText, equals('5'));
      expect(manyUnread.unreadText, equals('99+'));
    });
    
    test('should format name correctly', () {
      final normalName = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: 'João',
        matchDate: matchDate,
        chatId: chatId,
      );
      
      final longName = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: 'Nome Muito Longo Para Caber Na Tela',
        matchDate: matchDate,
        chatId: chatId,
      );
      
      final emptyName = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: '',
        matchDate: matchDate,
        chatId: chatId,
      );
      
      expect(normalName.formattedName, equals('João'));
      expect(longName.formattedName, equals('Nome Muito Longo Pa...'));
      expect(emptyName.formattedName, equals('Usuário'));
    });
    
    test('should serialize to and from Map correctly', () {
      final originalMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 3,
        daysRemaining: 25,
      );
      
      final map = originalMatch.toMap();
      final recreatedMatch = AcceptedMatchModel.fromMap(map);
      
      expect(recreatedMatch.notificationId, equals(originalMatch.notificationId));
      expect(recreatedMatch.otherUserId, equals(originalMatch.otherUserId));
      expect(recreatedMatch.otherUserName, equals(originalMatch.otherUserName));
      expect(recreatedMatch.otherUserPhoto, equals(originalMatch.otherUserPhoto));
      expect(recreatedMatch.chatId, equals(originalMatch.chatId));
      expect(recreatedMatch.unreadMessages, equals(originalMatch.unreadMessages));
      expect(recreatedMatch.daysRemaining, equals(originalMatch.daysRemaining));
    });
    
    test('should create copy with updated fields', () {
      final originalMatch = AcceptedMatchModel.fromNotification(
        notificationId: notificationId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 0,
      );
      
      final updatedMatch = originalMatch.copyWith(
        unreadMessages: 5,
        daysRemaining: 10,
      );
      
      expect(updatedMatch.unreadMessages, equals(5));
      expect(updatedMatch.daysRemaining, equals(10));
      expect(updatedMatch.notificationId, equals(originalMatch.notificationId)); // Unchanged
    });
  });
}