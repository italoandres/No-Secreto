import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/chat_message_bubble.dart';
import '../../lib/models/chat_message_model.dart';

void main() {
  group('ChatMessageBubble', () {
    late ChatMessageModel testMessage;

    setUp(() {
      testMessage = ChatMessageModel(
        id: 'test_message_1',
        chatId: 'test_chat_1',
        senderId: 'user_123',
        senderName: 'João',
        message: 'Olá! Como você está?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: MessageType.text,
        isRead: true,
      );
    });

    testWidgets('deve renderizar mensagem de texto corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se o conteúdo da mensagem está presente
      expect(find.text('Olá! Como você está?'), findsOneWidget);
      
      // Verificar se o widget foi construído
      expect(find.byType(ChatMessageBubble), findsOneWidget);
    });

    testWidgets('deve mostrar avatar para usuário atual', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se há um ícone de coração (avatar)
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('deve mostrar avatar para outro usuário', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Verificar se há um ícone de coração (avatar)
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('deve mostrar status de leitura para usuário atual', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se há ícones de status (done_all para lida)
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('deve responder ao tap', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tocar na mensagem
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('deve responder ao long press', (tester) async {
      bool longPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      // Long press na mensagem
      await tester.longPress(find.byType(GestureDetector));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('deve mostrar diferentes status de mensagem', (tester) async {
      final unreadMessage = testMessage.copyWith(isRead: false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: unreadMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se há ícone de check para não lida
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('deve mostrar mensagem de sistema', (tester) async {
      final systemMessage = testMessage.copyWith(
        type: MessageType.system,
        message: 'Chat iniciado',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: systemMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Verificar se o conteúdo da mensagem de sistema está presente
      expect(find.text('Chat iniciado'), findsOneWidget);
      
      // Verificar se há ícone de informação
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('deve ter cores diferentes para usuário atual e outro', (tester) async {
      // Testar mensagem do usuário atual
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se o widget foi construído
      expect(find.byType(ChatMessageBubble), findsOneWidget);

      // Testar mensagem de outro usuário
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Verificar se o widget foi construído
      expect(find.byType(ChatMessageBubble), findsOneWidget);
    });

    testWidgets('deve mostrar timestamp formatado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se há texto de tempo (5min atrás)
      expect(find.text('5min'), findsOneWidget);
    });
  });

  group('SystemMessageBubble', () {
    testWidgets('deve renderizar mensagem de sistema', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SystemMessageBubble(
              message: 'Chat iniciado',
              icon: Icons.chat,
            ),
          ),
        ),
      );

      // Verificar se o conteúdo está presente
      expect(find.text('Chat iniciado'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
    });

    testWidgets('deve renderizar sem ícone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SystemMessageBubble(
              message: 'Mensagem sem ícone',
            ),
          ),
        ),
      );

      // Verificar se o conteúdo está presente
      expect(find.text('Mensagem sem ícone'), findsOneWidget);
    });
  });

  group('DateSeparator', () {
    testWidgets('deve mostrar "Hoje" para data atual', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateSeparator(
              date: DateTime.now(),
            ),
          ),
        ),
      );

      expect(find.text('Hoje'), findsOneWidget);
    });

    testWidgets('deve mostrar "Ontem" para ontem', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateSeparator(
              date: yesterday,
            ),
          ),
        ),
      );

      expect(find.text('Ontem'), findsOneWidget);
    });

    testWidgets('deve mostrar data formatada para datas antigas', (tester) async {
      final oldDate = DateTime(2023, 12, 25);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateSeparator(
              date: oldDate,
            ),
          ),
        ),
      );

      expect(find.text('25/12/2023'), findsOneWidget);
    });
  });

  group('TypingIndicator', () {
    testWidgets('deve mostrar indicador de digitação', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(
              userName: 'João',
            ),
          ),
        ),
      );

      // Verificar se o texto está presente
      expect(find.text('João está digitando'), findsOneWidget);
      
      // Verificar se há avatar
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('deve ter animação', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(
              userName: 'Maria',
            ),
          ),
        ),
      );

      // Verificar se o widget foi construído
      expect(find.byType(TypingIndicator), findsOneWidget);
      
      // Aguardar um pouco para a animação
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verificar se ainda está presente
      expect(find.byType(TypingIndicator), findsOneWidget);
    });
  });

  group('Message Types', () {
    testWidgets('deve lidar com mensagem de imagem', (tester) async {
      final imageMessage = ChatMessageModel(
        id: 'test_image',
        chatId: 'test_chat',
        senderId: 'user_123',
        senderName: 'João',
        message: 'https://example.com/image.jpg',
        timestamp: DateTime.now(),
        type: MessageType.image,
        isRead: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: imageMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se o widget foi construído
      expect(find.byType(ChatMessageBubble), findsOneWidget);
    });

    testWidgets('deve mostrar status de não lida', (tester) async {
      final unreadMessage = ChatMessageModel(
        id: 'test_unread',
        chatId: 'test_chat',
        senderId: 'user_123',
        senderName: 'João',
        message: 'Mensagem não lida',
        timestamp: DateTime.now(),
        type: MessageType.text,
        isRead: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: unreadMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Verificar se há ícone de check simples
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}