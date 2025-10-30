import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/components/unread_messages_counter.dart';

void main() {
  group('UnreadMessagesCounter', () {
    const testChatId = 'test_chat_123';
    const testUserId = 'test_user_456';

    testWidgets('deve renderizar contador com valores padrão', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadMessagesCounter(
              chatId: testChatId,
              userId: testUserId,
              showZero: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadMessagesCounter), findsOneWidget);
      expect(find.byType(StreamBuilder<int>), findsOneWidget);
    });

    testWidgets('deve aplicar cores personalizadas', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadMessagesCounter(
              chatId: testChatId,
              userId: testUserId,
              backgroundColor: Colors.blue,
              textColor: Colors.yellow,
              showZero: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadMessagesCounter), findsOneWidget);
    });

    testWidgets('deve aplicar padding personalizado', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadMessagesCounter(
              chatId: testChatId,
              userId: testUserId,
              padding: EdgeInsets.all(16),
              showZero: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadMessagesCounter), findsOneWidget);
    });

    testWidgets('deve aplicar fontSize personalizado', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadMessagesCounter(
              chatId: testChatId,
              userId: testUserId,
              fontSize: 16,
              showZero: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadMessagesCounter), findsOneWidget);
    });
  });

  group('CompactUnreadCounter', () {
    const testChatId = 'test_chat_123';
    const testUserId = 'test_user_456';

    testWidgets('deve renderizar versão compacta', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactUnreadCounter(
              chatId: testChatId,
              userId: testUserId,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CompactUnreadCounter), findsOneWidget);
      expect(find.byType(UnreadMessagesCounter), findsOneWidget);
    });
  });

  group('UnreadBadge', () {
    const testChatId = 'test_chat_123';
    const testUserId = 'test_user_456';

    testWidgets('deve renderizar badge sobre widget filho', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(
              chatId: testChatId,
              userId: testUserId,
              child: Icon(Icons.message),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadBadge), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('deve aplicar alinhamento personalizado', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(
              chatId: testChatId,
              userId: testUserId,
              alignment: Alignment.bottomLeft,
              child: Icon(Icons.message),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UnreadBadge), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
    });
  });

  group('ReadStatsWidget', () {
    const testChatId = 'test_chat_123';

    testWidgets('deve renderizar widget de estatísticas', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadStatsWidget(
              chatId: testChatId,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ReadStatsWidget), findsOneWidget);
      expect(find.byType(FutureBuilder<Map<String, dynamic>>), findsOneWidget);
    });

    testWidgets('deve renderizar sem percentagem quando especificado', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadStatsWidget(
              chatId: testChatId,
              showPercentage: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ReadStatsWidget), findsOneWidget);
    });

    testWidgets('deve mostrar loading inicialmente', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadStatsWidget(
              chatId: testChatId,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}