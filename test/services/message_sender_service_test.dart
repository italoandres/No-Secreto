import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/message_sender_service.dart';
import '../../lib/models/chat_message_model.dart';

void main() {
  group('MessageSenderService', () {
    group('validateMessage', () {
      testWidgets('deve validar mensagem válida', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Olá! Como você está?',
          matchDate: matchDate,
        );
        
        expect(result, isNull); // Null significa válida
      });

      testWidgets('deve rejeitar mensagem vazia', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: '',
          matchDate: matchDate,
        );
        
        expect(result, isNotNull);
        expect(result!.result, MessageSendResult.messageEmpty);
      });

      testWidgets('deve rejeitar mensagem só com espaços', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: '   ',
          matchDate: matchDate,
        );
        
        expect(result, isNotNull);
        expect(result!.result, MessageSendResult.messageEmpty);
      });

      testWidgets('deve rejeitar mensagem muito longa', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        final longMessage = 'a' * 1001; // Mais que o limite de 1000
        
        final result = MessageSenderService.validateMessage(
          messageText: longMessage,
          matchDate: matchDate,
        );
        
        expect(result, isNotNull);
        expect(result!.result, MessageSendResult.messageTooLong);
      });

      testWidgets('deve rejeitar chat expirado', (tester) async {
        final expiredMatchDate = DateTime.now().subtract(const Duration(days: 35));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Mensagem válida',
          matchDate: expiredMatchDate,
        );
        
        expect(result, isNotNull);
        expect(result!.result, MessageSendResult.chatExpired);
      });

      testWidgets('deve aceitar mensagem no limite de caracteres', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        // Criar uma mensagem realista de exatamente 1000 caracteres
        final baseText = 'Esta é uma mensagem de teste que vai verificar se o sistema aceita mensagens no limite máximo de caracteres permitidos. ';
        final repetitions = (1000 / baseText.length).ceil();
        final longMessage = (baseText * repetitions).substring(0, 1000);
        
        final result = MessageSenderService.validateMessage(
          messageText: longMessage,
          matchDate: matchDate,
        );
        
        expect(result, isNull); // Deve ser válida
      });
    });

    group('canSendMessage', () {
      testWidgets('deve retornar true para mensagem válida', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final canSend = MessageSenderService.canSendMessage(
          messageText: 'Mensagem válida',
          matchDate: matchDate,
        );
        
        expect(canSend, isTrue);
      });

      testWidgets('deve retornar false para mensagem inválida', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final canSend = MessageSenderService.canSendMessage(
          messageText: '',
          matchDate: matchDate,
        );
        
        expect(canSend, isFalse);
      });

      testWidgets('deve retornar false para chat expirado', (tester) async {
        final expiredMatchDate = DateTime.now().subtract(const Duration(days: 35));
        
        final canSend = MessageSenderService.canSendMessage(
          messageText: 'Mensagem válida',
          matchDate: expiredMatchDate,
        );
        
        expect(canSend, isFalse);
      });
    });

    group('MessageSendResult', () {
      testWidgets('deve ter mensagens corretas', (tester) async {
        expect(MessageSendResult.success.message, 'Mensagem enviada com sucesso');
        expect(MessageSendResult.chatExpired.message, contains('expirou'));
        expect(MessageSendResult.messageEmpty.message, contains('Digite uma mensagem'));
        expect(MessageSendResult.messageTooLong.message, contains('muito longa'));
        expect(MessageSendResult.networkError.message, contains('conexão'));
        expect(MessageSendResult.validationError.message, contains('inválido'));
        expect(MessageSendResult.unknownError.message, contains('inesperado'));
      });

      testWidgets('deve identificar sucesso corretamente', (tester) async {
        expect(MessageSendResult.success.isSuccess, isTrue);
        expect(MessageSendResult.success.isError, isFalse);
        
        expect(MessageSendResult.chatExpired.isSuccess, isFalse);
        expect(MessageSendResult.chatExpired.isError, isTrue);
      });
    });

    group('MessageSendResponse', () {
      testWidgets('deve criar resposta de sucesso', (tester) async {
        final message = ChatMessageModel(
          id: 'test_id',
          chatId: 'test_chat',
          senderId: 'user_123',
          senderName: 'João',
          message: 'Teste',
          timestamp: DateTime.now(),
          isRead: false,
          type: MessageType.text,
        );
        
        final response = MessageSendResponse.success(message);
        
        expect(response.isSuccess, isTrue);
        expect(response.isError, isFalse);
        expect(response.result, MessageSendResult.success);
        expect(response.sentMessage, equals(message));
      });

      testWidgets('deve criar resposta de erro', (tester) async {
        final response = MessageSendResponse.error(MessageSendResult.messageEmpty);
        
        expect(response.isSuccess, isFalse);
        expect(response.isError, isTrue);
        expect(response.result, MessageSendResult.messageEmpty);
        expect(response.sentMessage, isNull);
      });

      testWidgets('deve criar resposta de erro com exceção', (tester) async {
        final exception = Exception('Erro de teste');
        final response = MessageSendResponse.error(MessageSendResult.networkError, exception);
        
        expect(response.isSuccess, isFalse);
        expect(response.isError, isTrue);
        expect(response.result, MessageSendResult.networkError);
        expect(response.error, equals(exception));
      });
    });

    group('getStats', () {
      testWidgets('deve retornar estatísticas corretas', (tester) async {
        final stats = MessageSenderService.getStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['maxMessageLength'], 1000);
        expect(stats['maxRetryAttempts'], 3);
        expect(stats['retryDelaySeconds'], 2);
        expect(stats['supportedTypes'], isA<List>());
        expect(stats['supportedTypes'], contains('text'));
        expect(stats['supportedTypes'], contains('image'));
        expect(stats['supportedTypes'], contains('system'));
      });
    });

    group('Validação de Conteúdo', () {
      testWidgets('deve aceitar mensagem normal', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Oi! Tudo bem? Como foi seu dia?',
          matchDate: matchDate,
        );
        
        expect(result, isNull);
      });

      testWidgets('deve aceitar mensagem com emojis', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Olá! 😊 Como você está? 💕',
          matchDate: matchDate,
        );
        
        expect(result, isNull);
      });

      testWidgets('deve aceitar mensagem com quebras de linha', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Oi!\nTudo bem?\nComo foi seu dia?',
          matchDate: matchDate,
        );
        
        expect(result, isNull);
      });

      testWidgets('deve aceitar URL de imagem válida', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'https://example.com/image.jpg',
          matchDate: matchDate,
          messageType: MessageType.image,
        );
        
        expect(result, isNull);
      });
    });

    group('Tipos de Mensagem', () {
      testWidgets('deve validar mensagem de texto', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Mensagem de texto normal',
          matchDate: matchDate,
          messageType: MessageType.text,
        );
        
        expect(result, isNull);
      });

      testWidgets('deve validar mensagem de sistema', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Mensagem do sistema',
          matchDate: matchDate,
          messageType: MessageType.system,
        );
        
        expect(result, isNull);
      });
    });

    group('Casos Extremos', () {
      testWidgets('deve lidar com texto só com espaços e quebras', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: '   \n\n   \t  ',
          matchDate: matchDate,
        );
        
        expect(result, isNotNull);
        expect(result!.result, MessageSendResult.messageEmpty);
      });

      testWidgets('deve aceitar mensagem com espaços nas bordas', (tester) async {
        final matchDate = DateTime.now().subtract(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: '   Mensagem válida   ',
          matchDate: matchDate,
        );
        
        expect(result, isNull);
      });

      testWidgets('deve lidar com data de match no futuro', (tester) async {
        final futureMatchDate = DateTime.now().add(const Duration(days: 10));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Mensagem válida',
          matchDate: futureMatchDate,
        );
        
        expect(result, isNull); // Deve ser válida
      });

      testWidgets('deve lidar com data de match exatamente no limite', (tester) async {
        final limitMatchDate = DateTime.now().subtract(const Duration(days: 30));
        
        final result = MessageSenderService.validateMessage(
          messageText: 'Mensagem válida',
          matchDate: limitMatchDate,
        );
        
        // Pode ser válida ou inválida dependendo da hora exata
        // O importante é não dar erro
        expect(result?.result, anyOf(isNull, MessageSendResult.chatExpired));
      });
    });
  });
}