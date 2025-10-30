import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/match_chat_model.dart';

void main() {
  group('MatchChatModel', () {
    const user1Id = 'user1';
    const user2Id = 'user2';
    
    test('should create new chat with correct properties', () {
      final chat = MatchChatModel.create(
        user1Id: user1Id,
        user2Id: user2Id,
      );
      
      expect(chat.user1Id, equals(user1Id));
      expect(chat.user2Id, equals(user2Id));
      expect(chat.id, equals('chat_user1_user2'));
      expect(chat.isExpired, isFalse);
      expect(chat.unreadCount[user1Id], equals(0));
      expect(chat.unreadCount[user2Id], equals(0));
      expect(chat.daysRemaining, equals(30));
    });
    
    test('should generate consistent chat ID regardless of user order', () {
      final chat1 = MatchChatModel.create(user1Id: user1Id, user2Id: user2Id);
      final chat2 = MatchChatModel.create(user1Id: user2Id, user2Id: user1Id);
      
      expect(chat1.id, equals(chat2.id));
    });
    
    test('should correctly identify other user', () {
      final chat = MatchChatModel.create(user1Id: user1Id, user2Id: user2Id);
      
      expect(chat.getOtherUserId(user1Id), equals(user2Id));
      expect(chat.getOtherUserId(user2Id), equals(user1Id));
    });
    
    test('should correctly calculate expiration', () {
      final now = DateTime.now();
      final chat = MatchChatModel(
        id: 'test',
        user1Id: user1Id,
        user2Id: user2Id,
        createdAt: now.subtract(const Duration(days: 31)),
        expiresAt: now.subtract(const Duration(days: 1)),
        isExpired: false,
        unreadCount: {},
      );
      
      expect(chat.hasExpired, isTrue);
      expect(chat.daysRemaining, equals(0));
    });
    
    test('should serialize to and from Map correctly', () {
      final originalChat = MatchChatModel.create(
        user1Id: user1Id,
        user2Id: user2Id,
      );
      
      final map = originalChat.toMap();
      expect(map['id'], equals(originalChat.id));
      expect(map['user1Id'], equals(user1Id));
      expect(map['user2Id'], equals(user2Id));
      
      // Note: In real tests, you'd need to mock Timestamp
      // For now, we'll test the structure
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('expiresAt'), isTrue);
    });
    
    test('should handle unread count correctly', () {
      final chat = MatchChatModel.create(user1Id: user1Id, user2Id: user2Id);
      final updatedChat = chat.copyWith(
        unreadCount: {user1Id: 5, user2Id: 2},
      );
      
      expect(updatedChat.getUnreadCount(user1Id), equals(5));
      expect(updatedChat.getUnreadCount(user2Id), equals(2));
      expect(updatedChat.getUnreadCount('unknown'), equals(0));
    });
    
    test('should create copy with updated fields', () {
      final originalChat = MatchChatModel.create(
        user1Id: user1Id,
        user2Id: user2Id,
      );
      
      const newMessage = 'Hello!';
      final updatedChat = originalChat.copyWith(
        lastMessage: newMessage,
        isExpired: true,
      );
      
      expect(updatedChat.lastMessage, equals(newMessage));
      expect(updatedChat.isExpired, isTrue);
      expect(updatedChat.id, equals(originalChat.id)); // Unchanged fields
    });
  });
}