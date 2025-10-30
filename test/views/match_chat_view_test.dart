import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/views/match_chat_view.dart';

void main() {
  group('MatchChatView', () {
    testWidgets('should create MatchChatView with required parameters', (tester) async {
      const chatView = MatchChatView(
        chatId: 'test_chat',
        otherUserId: 'user123',
        otherUserName: 'João',
        daysRemaining: 15,
      );

      expect(chatView.chatId, equals('test_chat'));
      expect(chatView.otherUserId, equals('user123'));
      expect(chatView.otherUserName, equals('João'));
      expect(chatView.daysRemaining, equals(15));
      expect(chatView.otherUserPhoto, isNull);
    });

    testWidgets('should create MatchChatView with all parameters', (tester) async {
      const chatView = MatchChatView(
        chatId: 'chat_123',
        otherUserId: 'user_456',
        otherUserName: 'Maria Santos',
        otherUserPhoto: 'https://example.com/photo.jpg',
        daysRemaining: 7,
      );

      expect(chatView.chatId, equals('chat_123'));
      expect(chatView.otherUserId, equals('user_456'));
      expect(chatView.otherUserName, equals('Maria Santos'));
      expect(chatView.otherUserPhoto, equals('https://example.com/photo.jpg'));
      expect(chatView.daysRemaining, equals(7));
    });

    testWidgets('should handle zero days remaining', (tester) async {
      const chatView = MatchChatView(
        chatId: 'test_chat',
        otherUserId: 'user123',
        otherUserName: 'João',
        daysRemaining: 0,
      );

      expect(chatView.daysRemaining, equals(0));
    });

    testWidgets('should handle negative days remaining', (tester) async {
      const chatView = MatchChatView(
        chatId: 'test_chat',
        otherUserId: 'user123',
        otherUserName: 'João',
        daysRemaining: -1,
      );

      expect(chatView.daysRemaining, equals(-1));
    });

    testWidgets('should handle empty user name', (tester) async {
      const chatView = MatchChatView(
        chatId: 'test_chat',
        otherUserId: 'user123',
        otherUserName: '',
        daysRemaining: 15,
      );

      expect(chatView.otherUserName, equals(''));
    });

    testWidgets('should be a StatefulWidget', (tester) async {
      const chatView = MatchChatView(
        chatId: 'test_chat',
        otherUserId: 'user123',
        otherUserName: 'João',
        daysRemaining: 15,
      );

      expect(chatView, isA<StatefulWidget>());
    });
  });
}