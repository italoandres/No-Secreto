import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/enhanced_logger.dart';

/// Tipos de erro específicos do sistema de matches
enum MatchErrorType {
  networkError,
  chatExpired,
  messageValidation,
  permissionDenied,
  userNotFound,
  chatNotFound,
  messageNotFound,
  firebaseError,
  unknownError,
}

/// Classe para representar erros do sistema de matches
class MatchError {
  final MatchErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;
  final String? userId;
  final String? chatId;

  MatchError({
    required this.type,
    required this.message,
    this.details,
    DateTime? timestamp,
    this.userId,
    this.chatId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'chatId': chatId,
    };
  }

  @override
  String toString() {
    return 'MatchError(type: $type, message: $message, details: $details)';
  }
}

/// Serviço centralizado para tratamento de erros do sistema de matches
class MatchErrorHandler {
  static final List<MatchError> _errorHistory = [];
  static const int _maxHistorySize = 100;

  /// Tratar erro e exibir mensagem apropriada ao usuário
  static void handleError(
    dynamic error, {
    String? context,
    String? userId,
    String? chatId,
    bool showSnackbar = true,
    VoidCallback? onRetry,
  }) {
    final matchError = _parseError(error, context: context, userId: userId, chatId: chatId);
    
    // Adicionar ao histórico
    _addToHistory(matchError);
    
    // Log do erro
    EnhancedLogger.error(
      'Match Error: ${matchError.message}${matchError.details != null ? ' - ${matchError.details}' : ''}',
      tag: 'MATCH_ERROR_HANDLER',
    );

    // Exibir mensagem ao usuário
    if (showSnackbar) {
      _showErrorSnackbar(matchError, onRetry: onRetry);
    }
  }

  /// Converter erro genérico em MatchError
  static MatchError _parseError(
    dynamic error, {
    String? context,
    String? userId,
    String? chatId,
  }) {
    if (error is MatchError) {
      return error;
    }

    String errorMessage = error.toString().toLowerCase();
    MatchErrorType type = MatchErrorType.unknownError;
    String userMessage = 'Ocorreu um erro inesperado';
    String? details = error.toString();

    // Identificar tipo de erro baseado na mensagem
    if (errorMessage.contains('network') || 
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      type = MatchErrorType.networkError;
      userMessage = 'Problema de conexão. Verifique sua internet.';
    } else if (errorMessage.contains('permission') || 
               errorMessage.contains('denied')) {
      type = MatchErrorType.permissionDenied;
      userMessage = 'Você não tem permissão para esta ação.';
    } else if (errorMessage.contains('user') && 
               errorMessage.contains('not found')) {
      type = MatchErrorType.userNotFound;
      userMessage = 'Usuário não encontrado.';
    } else if (errorMessage.contains('chat') && 
               errorMessage.contains('not found')) {
      type = MatchErrorType.chatNotFound;
      userMessage = 'Chat não encontrado.';
    } else if (errorMessage.contains('message') && 
               errorMessage.contains('not found')) {
      type = MatchErrorType.messageNotFound;
      userMessage = 'Mensagem não encontrada.';
    } else if (errorMessage.contains('expired')) {
      type = MatchErrorType.chatExpired;
      userMessage = 'Este chat expirou.';
    } else if (errorMessage.contains('firebase') || 
               errorMessage.contains('firestore')) {
      type = MatchErrorType.firebaseError;
      userMessage = 'Erro no servidor. Tente novamente.';
    } else if (errorMessage.contains('validation')) {
      type = MatchErrorType.messageValidation;
      userMessage = 'Dados inválidos. Verifique as informações.';
    }

    // Adicionar contexto se fornecido
    if (context != null) {
      userMessage = '$userMessage ($context)';
    }

    return MatchError(
      type: type,
      message: userMessage,
      details: details,
      userId: userId,
      chatId: chatId,
    );
  }

  /// Exibir snackbar com erro
  static void _showErrorSnackbar(MatchError error, {VoidCallback? onRetry}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Erro',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: Icon(
          _getErrorIcon(error.type),
          color: Colors.white,
        ),
        mainButton: onRetry != null
            ? TextButton(
                onPressed: () {
                  Get.closeCurrentSnackbar();
                  onRetry();
                },
                child: const Text(
                  'TENTAR NOVAMENTE',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : null,
      );
    }
  }

  /// Obter ícone apropriado para o tipo de erro
  static IconData _getErrorIcon(MatchErrorType type) {
    switch (type) {
      case MatchErrorType.networkError:
        return Icons.wifi_off;
      case MatchErrorType.chatExpired:
        return Icons.access_time;
      case MatchErrorType.messageValidation:
        return Icons.warning;
      case MatchErrorType.permissionDenied:
        return Icons.block;
      case MatchErrorType.userNotFound:
      case MatchErrorType.chatNotFound:
      case MatchErrorType.messageNotFound:
        return Icons.search_off;
      case MatchErrorType.firebaseError:
        return Icons.cloud_off;
      case MatchErrorType.unknownError:
      default:
        return Icons.error;
    }
  }

  /// Adicionar erro ao histórico
  static void _addToHistory(MatchError error) {
    _errorHistory.add(error);
    
    // Manter apenas os últimos erros
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  /// Obter histórico de erros
  static List<MatchError> getErrorHistory() {
    return List.unmodifiable(_errorHistory);
  }

  /// Limpar histórico de erros
  static void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Obter estatísticas de erros
  static Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 1));

    final errors24h = _errorHistory.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final errors1h = _errorHistory.where((e) => e.timestamp.isAfter(lastHour)).toList();

    // Contar por tipo
    final errorsByType = <MatchErrorType, int>{};
    for (final error in _errorHistory) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'errorsLast24Hours': errors24h.length,
      'errorsLastHour': errors1h.length,
      'errorsByType': errorsByType.map((k, v) => MapEntry(k.toString(), v)),
      'mostCommonError': errorsByType.isNotEmpty 
          ? errorsByType.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString()
          : null,
    };
  }

  /// Verificar se há muitos erros recentes (possível problema sistêmico)
  static bool hasFrequentErrors({Duration? timeWindow, int? threshold}) {
    timeWindow ??= const Duration(minutes: 5);
    threshold ??= 5;

    final cutoff = DateTime.now().subtract(timeWindow);
    final recentErrors = _errorHistory.where((e) => e.timestamp.isAfter(cutoff)).length;

    return recentErrors >= threshold;
  }

  /// Criar erro personalizado
  static MatchError createError({
    required MatchErrorType type,
    required String message,
    String? details,
    String? userId,
    String? chatId,
  }) {
    return MatchError(
      type: type,
      message: message,
      details: details,
      userId: userId,
      chatId: chatId,
    );
  }

  /// Tratar erro de rede especificamente
  static void handleNetworkError({
    String? context,
    VoidCallback? onRetry,
  }) {
    handleError(
      createError(
        type: MatchErrorType.networkError,
        message: 'Problema de conexão. Verifique sua internet.',
      ),
      context: context,
      onRetry: onRetry,
    );
  }

  /// Tratar erro de chat expirado
  static void handleChatExpiredError({
    String? chatId,
    String? context,
  }) {
    handleError(
      createError(
        type: MatchErrorType.chatExpired,
        message: 'Este chat expirou. Não é possível enviar mensagens.',
        chatId: chatId,
      ),
      context: context,
      showSnackbar: true,
    );
  }

  /// Tratar erro de validação de mensagem
  static void handleMessageValidationError({
    required String message,
    String? chatId,
    String? userId,
  }) {
    handleError(
      createError(
        type: MatchErrorType.messageValidation,
        message: message,
        chatId: chatId,
        userId: userId,
      ),
      showSnackbar: true,
    );
  }
}