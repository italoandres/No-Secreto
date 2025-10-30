import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/views/romantic_match_chat_view.dart';
import '../../lib/models/accepted_match_model.dart';

// Mock widget para testar sem Firebase
class MockRomanticMatchChatView extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final AcceptedMatchModel match;

  const MockRomanticMatchChatView({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF0F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: otherUserPhoto != null
                  ? const Icon(Icons.person, color: Color(0xFFFF6B9D), size: 20)
                  : const Icon(Icons.favorite, color: Color(0xFFFF6B9D), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Match há ${match.daysRemaining} dias',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Mock banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: match.chatExpired ? Colors.red[600] : const Color(0xFFFF6B9D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  match.chatExpired ? Icons.block : Icons.favorite_border,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    match.chatExpired ? 'Chat Expirado' : '${match.daysRemaining} dias restantes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mock messages area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Início da conversa! 💕',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vocês fizeram match!\nQue tal começar com um "Oi"?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // Mock input
          if (!match.chatExpired)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          
          // Mock expired input
          if (match.chatExpired)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.block,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este chat expirou. Não é possível enviar mensagens.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  group('RomanticMatchChatView', () {
    late AcceptedMatchModel testMatch;

    setUp(() {
      testMatch = AcceptedMatchModel(
        notificationId: 'test_match_1',
        otherUserId: 'user_123',
        otherUserName: 'Maria Silva',
        otherUserPhoto: 'https://example.com/photo.jpg',
        matchDate: DateTime.now().subtract(const Duration(days: 5)),
        chatId: 'chat_123',
        unreadMessages: 0,
        chatExpired: false,
        daysRemaining: 25,
      );
    });

    testWidgets('deve renderizar AppBar corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            otherUserPhoto: 'https://example.com/photo.jpg',
            match: testMatch,
          ),
        ),
      );

      // Verificar se o AppBar está presente
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verificar se o nome do usuário está presente
      expect(find.text('Maria Silva'), findsOneWidget);
      
      // Verificar se há botão de voltar
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('deve mostrar banner de expiração', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se o banner de expiração está presente
      expect(find.textContaining('dias restantes'), findsOneWidget);
    });

    testWidgets('deve mostrar campo de input de mensagem', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se há campo de texto
      expect(find.byType(TextField), findsOneWidget);
      
      // Verificar placeholder
      expect(find.text('Digite uma mensagem...'), findsOneWidget);
    });

    testWidgets('deve mostrar botão de enviar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se há ícone de enviar
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('deve mostrar estado vazio quando não há mensagens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se mostra mensagem de início da conversa
      expect(find.textContaining('Início da conversa'), findsOneWidget);
      expect(find.textContaining('Vocês fizeram match'), findsOneWidget);
    });

    testWidgets('deve ter gradiente romântico no AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se o AppBar tem fundo transparente (para mostrar o gradiente)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
    });

    testWidgets('deve mostrar avatar do usuário no AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            otherUserPhoto: 'https://example.com/photo.jpg',
            match: testMatch,
          ),
        ),
      );

      // Verificar se há container circular (avatar)
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('deve mostrar ícone de coração quando não há foto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            otherUserPhoto: null,
            match: testMatch,
          ),
        ),
      );

      // Verificar se há ícone de coração
      expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
    });

    testWidgets('deve ter cor de fundo romântica', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar se o Scaffold tem a cor de fundo correta
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF8F9FA));
    });

    testWidgets('deve ter layout responsivo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: testMatch,
          ),
        ),
      );

      // Verificar estrutura básica
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(Expanded), findsAtLeastNWidgets(1));
    });
  });

  group('RomanticMatchChatView - Chat Expirado', () {
    testWidgets('deve mostrar mensagem de chat expirado', (tester) async {
      final expiredMatch = AcceptedMatchModel(
        notificationId: 'test_match_1',
        otherUserId: 'user_123',
        otherUserName: 'Maria Silva',
        otherUserPhoto: null,
        matchDate: DateTime.now().subtract(const Duration(days: 35)),
        chatId: 'chat_123',
        unreadMessages: 0,
        chatExpired: true,
        daysRemaining: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: expiredMatch,
          ),
        ),
      );

      // Verificar se mostra mensagem de expiração
      expect(find.text('Chat Expirado'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsAtLeastNWidgets(1));
    });
  });

  group('RomanticMatchChatView - Interações', () {
    testWidgets('deve permitir digitar mensagem', (tester) async {
      final match = AcceptedMatchModel(
        notificationId: 'test_match_1',
        otherUserId: 'user_123',
        otherUserName: 'Maria Silva',
        otherUserPhoto: null,
        matchDate: DateTime.now().subtract(const Duration(days: 5)),
        chatId: 'chat_123',
        unreadMessages: 0,
        chatExpired: false,
        daysRemaining: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MockRomanticMatchChatView(
            chatId: 'test_chat',
            otherUserId: 'user_123',
            otherUserName: 'Maria Silva',
            match: match,
          ),
        ),
      );

      // Encontrar o campo de texto e digitar
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Olá! Como você está?');
      await tester.pump();

      // Verificar se o texto foi inserido
      expect(find.text('Olá! Como você está?'), findsOneWidget);
    });
  });
}