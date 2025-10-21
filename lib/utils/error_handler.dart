import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_logger.dart';

/// Sistema centralizado de tratamento de erros
class ErrorHandler {
  
  /// Trata erros de forma centralizada
  static void handleError(dynamic error, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
  }) {
    final errorInfo = _analyzeError(error);
    
    EnhancedLogger.error(
      'Error in ${context ?? 'unknown context'}',
      tag: 'ERROR_HANDLER',
      error: error,
      stackTrace: stackTrace,
      data: {
        'errorType': errorInfo.type,
        'userMessage': errorInfo.userMessage,
        'isRetryable': errorInfo.isRetryable,
        ...?additionalData,
      },
    );
    
    if (showUserMessage) {
      _showUserError(errorInfo);
    }
  }
  
  /// Executa uma operação com tratamento de erro automático
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
    bool showUserMessage = true,
    int maxRetries = 0,
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        final errorInfo = _analyzeError(error);
        
        // Se é um erro que pode ser tentado novamente e ainda temos tentativas
        if (errorInfo.isRetryable && attempts <= maxRetries) {
          EnhancedLogger.warning(
            'Retrying operation (attempt $attempts/${maxRetries + 1})',
            tag: 'ERROR_HANDLER',
            data: {
              'context': context,
              'error': error.toString(),
            },
          );
          
          // Aguarda um pouco antes de tentar novamente
          await Future.delayed(Duration(milliseconds: 500 * attempts));
          continue;
        }
        
        // Se chegou aqui, não vai tentar mais
        handleError(
          error,
          context: context,
          stackTrace: stackTrace,
          showUserMessage: showUserMessage,
        );
        
        return fallbackValue;
      }
    }
    
    return fallbackValue;
  }
  
  /// Analisa o erro e retorna informações estruturadas
  static ErrorInfo _analyzeError(dynamic error) {
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }
    
    if (error is FormatException) {
      return ErrorInfo(
        type: 'FormatException',
        userMessage: 'Dados em formato inválido. Tente novamente.',
        isRetryable: false,
        technicalMessage: error.message,
      );
    }
    
    if (error is TypeError) {
      return ErrorInfo(
        type: 'TypeError',
        userMessage: 'Erro interno do aplicativo. Nossa equipe foi notificada.',
        isRetryable: false,
        technicalMessage: error.toString(),
      );
    }
    
    if (error is NetworkImageLoadException) {
      return ErrorInfo(
        type: 'NetworkImageLoadException',
        userMessage: 'Erro ao carregar imagem. Verifique sua conexão.',
        isRetryable: true,
        technicalMessage: error.toString(),
      );
    }
    
    // Erro genérico
    return ErrorInfo(
      type: 'UnknownError',
      userMessage: 'Ocorreu um erro inesperado. Tente novamente.',
      isRetryable: true,
      technicalMessage: error.toString(),
    );
  }
  
  /// Trata erros específicos do Firebase
  static ErrorInfo _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return ErrorInfo(
          type: 'PermissionDenied',
          userMessage: 'Você não tem permissão para esta operação.',
          isRetryable: false,
          technicalMessage: error.message ?? '',
        );
        
      case 'unavailable':
        return ErrorInfo(
          type: 'ServiceUnavailable',
          userMessage: 'Serviço temporariamente indisponível. Tente novamente em alguns minutos.',
          isRetryable: true,
          technicalMessage: error.message ?? '',
        );
        
      case 'deadline-exceeded':
        return ErrorInfo(
          type: 'Timeout',
          userMessage: 'Operação demorou muito para responder. Tente novamente.',
          isRetryable: true,
          technicalMessage: error.message ?? '',
        );
        
      case 'not-found':
        return ErrorInfo(
          type: 'NotFound',
          userMessage: 'Dados não encontrados.',
          isRetryable: false,
          technicalMessage: error.message ?? '',
        );
        
      case 'already-exists':
        return ErrorInfo(
          type: 'AlreadyExists',
          userMessage: 'Este item já existe.',
          isRetryable: false,
          technicalMessage: error.message ?? '',
        );
        
      case 'resource-exhausted':
        return ErrorInfo(
          type: 'ResourceExhausted',
          userMessage: 'Muitas tentativas. Aguarde um momento antes de tentar novamente.',
          isRetryable: true,
          technicalMessage: error.message ?? '',
        );
        
      default:
        return ErrorInfo(
          type: 'FirebaseError',
          userMessage: 'Erro de conexão com o servidor. Verifique sua internet.',
          isRetryable: true,
          technicalMessage: '${error.code}: ${error.message}',
        );
    }
  }
  
  /// Mostra erro para o usuário
  static void _showUserError(ErrorInfo errorInfo) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Ops!',
        errorInfo.userMessage,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        icon: Icon(
          errorInfo.isRetryable ? Icons.refresh : Icons.error_outline,
          color: Colors.red[800],
        ),
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: errorInfo.isRetryable ? 4 : 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
  
  /// Mostra mensagem de sucesso
  static void showSuccess(String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Sucesso!',
        message,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        icon: Icon(Icons.check_circle, color: Colors.green[800]),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
  
  /// Mostra mensagem de aviso
  static void showWarning(String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Atenção',
        message,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        icon: Icon(Icons.warning, color: Colors.orange[800]),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
  
  /// Mostra mensagem informativa
  static void showInfo(String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Informação',
        message,
        backgroundColor: Colors.blue[100],
        colorText: Colors.blue[800],
        icon: Icon(Icons.info, color: Colors.blue[800]),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
  
  /// Mostra dialog de confirmação para retry
  static Future<bool> showRetryDialog(String message) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Informações estruturadas sobre um erro
class ErrorInfo {
  final String type;
  final String userMessage;
  final bool isRetryable;
  final String technicalMessage;
  
  ErrorInfo({
    required this.type,
    required this.userMessage,
    required this.isRetryable,
    required this.technicalMessage,
  });
}

/// Exception personalizada para erros de carregamento de imagem
class NetworkImageLoadException implements Exception {
  final String message;
  final String? url;
  final int? statusCode;
  
  NetworkImageLoadException(this.message, {this.url, this.statusCode});
  
  @override
  String toString() {
    return 'NetworkImageLoadException: $message${url != null ? ' (URL: $url)' : ''}${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}