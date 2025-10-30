import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/match_error_handler.dart';

void main() {
  group('MatchError', () {
    testWidgets('deve criar erro com parâmetros obrigatórios', (tester) async {
      // Arrange & Act
      final error = MatchError(
        type: MatchErrorType.networkError,
        message: 'Erro de rede',
      );

      // Assert
      expect(error.type, equals(MatchErrorType.networkError));
      expect(error.message, equals('Erro de rede'));
      expect(error.details, isNull);
      expect(error.timestamp, isA<DateTime>());
      expect(error.userId, isNull);
      expect(error.chatId, isNull);
    });

    testWidgets('deve criar erro com todos os parâmetros', (tester) async {
      // Arrange
      final timestamp = DateTime.now();
      
      // Act
      final error = MatchError(
        type: MatchErrorType.chatExpired,
        message: 'Chat expirado',
        details: 'Detalhes do erro',
        timestamp: timestamp,
        userId: 'user_123',
        chatId: 'chat_456',
      );

      // Assert
      expect(error.type, equals(MatchErrorType.chatExpired));
      expect(error.message, equals('Chat expirado'));
      expect(error.details, equals('Detalhes do erro'));
      expect(error.timestamp, equals(timestamp));
      expect(error.userId, equals('user_123'));
      expect(error.chatId, equals('chat_456'));
    });

    testWidgets('deve converter para JSON corretamente', (tester) async {
      // Arrange
      final error = MatchError(
        type: MatchErrorType.messageValidation,
        message: 'Mensagem inválida',
        details: 'Detalhes',
        userId: 'user_123',
        chatId: 'chat_456',
      );

      // Act
      final json = error.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['type'], contains('messageValidation'));
      expect(json['message'], equals('Mensagem inválida'));
      expect(json['details'], equals('Detalhes'));
      expect(json['userId'], equals('user_123'));
      expect(json['chatId'], equals('chat_456'));
      expect(json['timestamp'], isA<String>());
    });

    testWidgets('deve ter toString informativo', (tester) async {
      // Arrange
      final error = MatchError(
        type: MatchErrorType.userNotFound,
        message: 'Usuário não encontrado',
        details: 'ID inválido',
      );

      // Act
      final string = error.toString();

      // Assert
      expect(string, contains('MatchError'));
      expect(string, contains('userNotFound'));
      expect(string, contains('Usuário não encontrado'));
      expect(string, contains('ID inválido'));
    });
  });

  group('MatchErrorHandler', () {
    setUp(() {
      MatchErrorHandler.clearErrorHistory();
    });

    testWidgets('deve tratar erro genérico', (tester) async {
      // Arrange
      final error = Exception('Erro genérico');

      // Act & Assert
      expect(() {
        MatchErrorHandler.handleError(error, showSnackbar: false);
      }, returnsNormally);
    });

    testWidgets('deve adicionar erro ao histórico', (tester) async {
      // Arrange
      final error = Exception('Erro de teste');

      // Act
      MatchErrorHandler.handleError(error, showSnackbar: false);

      // Assert
      final history = MatchErrorHandler.getErrorHistory();
      expect(history.length, equals(1));
      expect(history.first.message, contains('Ocorreu um erro inesperado'));
    });

    testWidgets('deve identificar erro de rede', (tester) async {
      // Arrange
      final error = Exception('Network connection failed');

      // Act
      MatchErrorHandler.handleError(error, showSnackbar: false);

      // Assert
      final history = MatchErrorHandler.getErrorHistory();
      expect(history.first.type, equals(MatchErrorType.networkError));
      expect(history.first.message, contains('conexão'));
    });

    testWidgets('deve identificar erro de permissão', (tester) async {
      // Arrange
      final error = Exception('Permission denied');

      // Act
      MatchErrorHandler.handleError(error, showSnackbar: false);

      // Assert
      final history = MatchErrorHandler.getErrorHistory();
      expect(history.first.type, equals(MatchErrorType.permissionDenied));
      expect(history.first.message, contains('permissão'));
    });

    testWidgets('deve identificar chat expirado', (tester) async {
      // Arrange
      final error = Exception('Chat has expired');

      // Act
      MatchErrorHandler.handleError(error, showSnackbar: false);

      // Assert
      final history = MatchErrorHandler.getErrorHistory();
      expect(history.first.type, equals(MatchErrorType.chatExpired));
      expect(history.first.message, contains('expirou'));
    });

    testWidgets('deve limpar histórico', (tester) async {
      // Arrange
      MatchErrorHandler.handleError(Exception('Erro 1'), showSnackbar: false);
      MatchErrorHandler.handleError(Exception('Erro 2'), showSnackbar: false);

      // Act
      MatchErrorHandler.clearErrorHistory();

      // Assert
      expect(MatchErrorHandler.getErrorHistory().length, equals(0));
    });

    testWidgets('deve retornar estatísticas válidas', (tester) async {
      // Arrange
      MatchErrorHandler.handleError(Exception('Network error'), showSnackbar: false);
      MatchErrorHandler.handleError(Exception('Permission denied'), showSnackbar: false);

      // Act
      final stats = MatchErrorHandler.getErrorStats();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['totalErrors'], equals(2));
      expect(stats['errorsLast24Hours'], equals(2));
      expect(stats['errorsLastHour'], equals(2));
      expect(stats['errorsByType'], isA<Map<String, dynamic>>());
      expect(stats['mostCommonError'], isA<String>());
    });

    testWidgets('deve detectar erros frequentes', (tester) async {
      // Arrange
      for (int i = 0; i < 6; i++) {
        MatchErrorHandler.handleError(Exception('Erro $i'), showSnackbar: false);
      }

      // Act
      final hasFrequent = MatchErrorHandler.hasFrequentErrors();

      // Assert
      expect(hasFrequent, isTrue);
    });

    testWidgets('deve criar erro personalizado', (tester) async {
      // Act
      final error = MatchErrorHandler.createError(
        type: MatchErrorType.messageValidation,
        message: 'Mensagem muito longa',
        details: 'Máximo 500 caracteres',
        userId: 'user_123',
        chatId: 'chat_456',
      );

      // Assert
      expect(error.type, equals(MatchErrorType.messageValidation));
      expect(error.message, equals('Mensagem muito longa'));
      expect(error.details, equals('Máximo 500 caracteres'));
      expect(error.userId, equals('user_123'));
      expect(error.chatId, equals('chat_456'));
    });

    testWidgets('deve tratar erro de rede específico', (tester) async {
      // Act & Assert
      expect(() {
        MatchErrorHandler.handleError(
          MatchErrorHandler.createError(
            type: MatchErrorType.networkError,
            message: 'Problema de conexão',
          ),
          context: 'Carregando mensagens',
          showSnackbar: false,
        );
      }, returnsNormally);

      final history = MatchErrorHandler.getErrorHistory();
      expect(history.length, equals(1));
      expect(history.first.type, equals(MatchErrorType.networkError));
    });

    testWidgets('deve tratar erro de chat expirado específico', (tester) async {
      // Act & Assert
      expect(() {
        MatchErrorHandler.handleError(
          MatchErrorHandler.createError(
            type: MatchErrorType.chatExpired,
            message: 'Este chat expirou',
            chatId: 'chat_123',
          ),
          context: 'Enviando mensagem',
          showSnackbar: false,
        );
      }, returnsNormally);

      final history = MatchErrorHandler.getErrorHistory();
      expect(history.length, equals(1));
      expect(history.first.type, equals(MatchErrorType.chatExpired));
      expect(history.first.chatId, equals('chat_123'));
    });

    testWidgets('deve tratar erro de validação específico', (tester) async {
      // Act & Assert
      expect(() {
        MatchErrorHandler.handleError(
          MatchErrorHandler.createError(
            type: MatchErrorType.messageValidation,
            message: 'Mensagem muito longa',
            chatId: 'chat_123',
            userId: 'user_456',
          ),
          showSnackbar: false,
        );
      }, returnsNormally);

      final history = MatchErrorHandler.getErrorHistory();
      expect(history.length, equals(1));
      expect(history.first.type, equals(MatchErrorType.messageValidation));
      expect(history.first.message, equals('Mensagem muito longa'));
      expect(history.first.chatId, equals('chat_123'));
      expect(history.first.userId, equals('user_456'));
    });
  });
}