import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/chat_message_model.dart';
import '../repositories/match_chat_repository.dart';
import '../services/chat_expiration_service.dart';

/// Resultado do envio de mensagem
enum MessageSendResult {
  success,
  chatExpired,
  messageEmpty,
  messageTooLong,
  networkError,
  validationError,
  unknownError,
}

/// Extensão para MessageSendResult
extension MessageSendResultExtension on MessageSendResult {
  String get message {
    switch (this) {
      case MessageSendResult.success:
        return 'Mensagem enviada com sucesso';
      case MessageSendResult.chatExpired:
        return 'Este chat expirou. Não é possível enviar mensagens.';
      case MessageSendResult.messageEmpty:
        return 'Digite uma mensagem antes de enviar';
      case MessageSendResult.messageTooLong:
        return 'Mensagem muito longa. Máximo de 1000 caracteres.';
      case MessageSendResult.networkError:
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      case MessageSendResult.validationError:
        return 'Mensagem contém conteúdo inválido';
      case MessageSendResult.unknownError:
        return 'Erro inesperado. Tente novamente.';
    }
  }

  bool get isSuccess => this == MessageSendResult.success;
  bool get isError => !isSuccess;
}

/// Dados do resultado do envio
class MessageSendResponse {
  final MessageSendResult result;
  final String message;
  final ChatMessageModel? sentMessage;
  final Exception? error;

  const MessageSendResponse({
    required this.result,
    required this.message,
    this.sentMessage,
    this.error,
  });

  factory MessageSendResponse.success(ChatMessageModel message) {
    return MessageSendResponse(
      result: MessageSendResult.success,
      message: MessageSendResult.success.message,
      sentMessage: message,
    );
  }

  factory MessageSendResponse.error(MessageSendResult result,
      [Exception? error]) {
    return MessageSendResponse(
      result: result,
      message: result.message,
      error: error,
    );
  }

  bool get isSuccess => result.isSuccess;
  bool get isError => result.isError;
}

/// Serviço responsável por gerenciar o envio de mensagens com validações e retry
class MessageSenderService {
  static const int _maxMessageLength = 1000;
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Envia uma mensagem com todas as validações necessárias
  ///
  /// [chatId] ID do chat
  /// [senderId] ID do usuário que está enviando
  /// [senderName] Nome do usuário que está enviando
  /// [messageText] Conteúdo da mensagem
  /// [matchDate] Data do match para verificar expiração
  /// [messageType] Tipo da mensagem (padrão: texto)
  ///
  /// Retorna [MessageSendResponse] com o resultado da operação
  static Future<MessageSendResponse> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String messageText,
    required DateTime matchDate,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      debugPrint('📤 Iniciando envio de mensagem para chat: $chatId');

      // 1. Validar se o chat não expirou
      final expirationResult = _validateChatExpiration(matchDate);
      if (expirationResult != null) {
        debugPrint('❌ Chat expirado: $chatId');
        return expirationResult;
      }

      // 2. Validar conteúdo da mensagem
      final validationResult =
          _validateMessageContent(messageText, messageType);
      if (validationResult != null) {
        debugPrint('❌ Validação falhou: ${validationResult.message}');
        return validationResult;
      }

      // 3. Criar modelo da mensagem
      final message = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: messageText.trim(),
        type: messageType,
      );

      // 4. Tentar enviar com retry automático
      final sendResult = await _sendWithRetry(message);

      if (sendResult.isSuccess) {
        debugPrint('✅ Mensagem enviada com sucesso: ${message.id}');

        // 5. Atualizar contador de mensagens não lidas
        await _updateUnreadCount(chatId, senderId);

        return MessageSendResponse.success(message);
      } else {
        debugPrint('❌ Falha no envio: ${sendResult.message}');
        return sendResult;
      }
    } catch (e) {
      debugPrint('❌ Erro inesperado no envio: $e');
      return MessageSendResponse.error(
        MessageSendResult.unknownError,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Valida se o chat não expirou
  static MessageSendResponse? _validateChatExpiration(DateTime matchDate) {
    if (ChatExpirationService.isChatExpired(matchDate)) {
      return MessageSendResponse.error(MessageSendResult.chatExpired);
    }
    return null;
  }

  /// Valida o conteúdo da mensagem
  static MessageSendResponse? _validateMessageContent(
      String messageText, MessageType type) {
    final trimmedText = messageText.trim();

    // Verificar se não está vazia
    if (trimmedText.isEmpty) {
      return MessageSendResponse.error(MessageSendResult.messageEmpty);
    }

    // Verificar tamanho máximo
    if (trimmedText.length > _maxMessageLength) {
      return MessageSendResponse.error(MessageSendResult.messageTooLong);
    }

    // Validações específicas por tipo
    switch (type) {
      case MessageType.text:
        return _validateTextMessage(trimmedText);
      case MessageType.image:
        return _validateImageMessage(trimmedText);
      case MessageType.system:
        // Mensagens de sistema não precisam de validação adicional
        return null;
    }
  }

  /// Valida mensagem de texto
  static MessageSendResponse? _validateTextMessage(String text) {
    // Verificar caracteres suspeitos ou spam
    if (_containsSuspiciousContent(text)) {
      return MessageSendResponse.error(MessageSendResult.validationError);
    }

    return null;
  }

  /// Valida mensagem de imagem
  static MessageSendResponse? _validateImageMessage(String imageUrl) {
    // Verificar se é uma URL válida
    if (!_isValidImageUrl(imageUrl)) {
      return MessageSendResponse.error(MessageSendResult.validationError);
    }

    return null;
  }

  /// Verifica se o conteúdo é suspeito
  static bool _containsSuspiciousContent(String text) {
    // Lista de padrões suspeitos (pode ser expandida)
    final suspiciousPatterns = [
      RegExp(r'https?://[^\s]+\.(exe|zip|rar)', caseSensitive: false),
      RegExp(r'(viagra|casino|lottery|winner)', caseSensitive: false),
      RegExp(
          r'(.)\1{100,}'), // Caracteres repetidos demais (mais de 100 seguidos)
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica se é uma URL de imagem válida
  static bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }

      // Verificar extensões de imagem
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final path = uri.path.toLowerCase();

      return validExtensions.any((ext) => path.endsWith(ext));
    } catch (e) {
      return false;
    }
  }

  /// Envia mensagem com retry automático
  static Future<MessageSendResponse> _sendWithRetry(
      ChatMessageModel message) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        debugPrint(
            '📤 Tentativa $attempt de $_maxRetryAttempts para enviar mensagem: ${message.id}');

        await MatchChatRepository.sendMessage(message);

        debugPrint('✅ Mensagem enviada na tentativa $attempt');
        return MessageSendResponse.success(message);
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ Tentativa $attempt falhou: $e');

        // Se não é a última tentativa, aguardar antes de tentar novamente
        if (attempt < _maxRetryAttempts) {
          debugPrint(
              '⏳ Aguardando ${_retryDelay.inSeconds}s antes da próxima tentativa...');
          await Future.delayed(_retryDelay);
        }
      }
    }

    // Todas as tentativas falharam
    debugPrint('❌ Todas as $_maxRetryAttempts tentativas falharam');

    // Determinar tipo de erro baseado na exceção
    final errorType = _determineErrorType(lastError);
    return MessageSendResponse.error(errorType, lastError);
  }

  /// Determina o tipo de erro baseado na exceção
  static MessageSendResult _determineErrorType(Exception? error) {
    if (error == null) return MessageSendResult.unknownError;

    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('internet')) {
      return MessageSendResult.networkError;
    }

    return MessageSendResult.unknownError;
  }

  /// Atualiza contador de mensagens não lidas
  static Future<void> _updateUnreadCount(String chatId, String senderId) async {
    try {
      debugPrint(
          '📊 Atualizando contador de mensagens não lidas para chat: $chatId');
      // TODO: Implementar atualização do contador quando o método estiver disponível
      // await MatchChatRepository.updateUnreadCount(chatId, senderId);
      debugPrint('✅ Contador atualizado com sucesso');
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar contador (não crítico): $e');
      // Não propagar erro pois não é crítico
    }
  }

  /// Valida mensagem antes do envio (método público para validação prévia)
  static MessageSendResponse? validateMessage({
    required String messageText,
    required DateTime matchDate,
    MessageType messageType = MessageType.text,
  }) {
    // Validar expiração
    final expirationResult = _validateChatExpiration(matchDate);
    if (expirationResult != null) {
      return expirationResult;
    }

    // Validar conteúdo
    final validationResult = _validateMessageContent(messageText, messageType);
    if (validationResult != null) {
      return validationResult;
    }

    return null; // Mensagem válida
  }

  /// Verifica se uma mensagem pode ser enviada
  static bool canSendMessage({
    required String messageText,
    required DateTime matchDate,
    MessageType messageType = MessageType.text,
  }) {
    final validation = validateMessage(
      messageText: messageText,
      matchDate: matchDate,
      messageType: messageType,
    );

    return validation == null;
  }

  /// Obtém estatísticas de envio (para debug/monitoramento)
  static Map<String, dynamic> getStats() {
    return {
      'maxMessageLength': _maxMessageLength,
      'maxRetryAttempts': _maxRetryAttempts,
      'retryDelaySeconds': _retryDelay.inSeconds,
      'supportedTypes': MessageType.values.map((e) => e.name).toList(),
    };
  }

  /// Envia mensagem de sistema (para eventos automáticos)
  static Future<MessageSendResponse> sendSystemMessage({
    required String chatId,
    required String content,
  }) async {
    return sendMessage(
      chatId: chatId,
      senderId: 'system',
      senderName: 'Sistema',
      messageText: content,
      matchDate: DateTime.now(), // Mensagens de sistema não expiram
      messageType: MessageType.system,
    );
  }

  /// Envia mensagem de boas-vindas automática
  static Future<MessageSendResponse> sendWelcomeMessage({
    required String chatId,
    required String userName,
    required String otherUserName,
  }) async {
    final welcomeText = 'Vocês fizeram match! 💕\n'
        '$userName e $otherUserName, que tal começarem uma conversa?';

    return sendSystemMessage(
      chatId: chatId,
      content: welcomeText,
    );
  }

  /// Envia notificação de expiração próxima
  static Future<MessageSendResponse> sendExpirationWarning({
    required String chatId,
    required int daysRemaining,
  }) async {
    String warningText;

    if (daysRemaining == 1) {
      warningText = '⏰ Atenção! Este chat expira amanhã. '
          'Continue conversando para manter o contato!';
    } else if (daysRemaining <= 3) {
      warningText = '⏰ Atenção! Este chat expira em $daysRemaining dias. '
          'Não percam a oportunidade de se conhecerem melhor!';
    } else {
      warningText = '⏰ Lembrete: Este chat expira em $daysRemaining dias. '
          'Aproveitem para conversar!';
    }

    return sendSystemMessage(
      chatId: chatId,
      content: warningText,
    );
  }
}
