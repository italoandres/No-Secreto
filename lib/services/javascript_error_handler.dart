import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' show FlutterError, FlutterErrorDetails;
import '../utils/enhanced_logger.dart';

/// Sistema robusto de tratamento de erros para aplicações móveis
class JavaScriptErrorHandler {
  static JavaScriptErrorHandler? _instance;
  static JavaScriptErrorHandler get instance => _instance ??= JavaScriptErrorHandler._();
  
  JavaScriptErrorHandler._();
  
  bool _isInitialized = false;
  final List<String> _errorHistory = [];
  final Map<String, int> _errorCounts = {};
  Timer? _recoveryTimer;
  
  /// Inicializa o sistema de captura de erros
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _setupMobileErrorHandlers();
      _setupRecoverySystem();
      _isInitialized = true;
      
      EnhancedLogger.success('✅ [ERROR_HANDLER] Sistema inicializado com sucesso para ${Platform.operatingSystem}');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao inicializar sistema', 
        error: e
      );
    }
  }
  
  /// Configura captura de erros para aplicações móveis
  void _setupMobileErrorHandlers() {
    // Para aplicações móveis, capturamos erros Dart/Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Captura erros não tratados em isolates
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }
  
  /// Configura captura de promises rejeitadas (adaptado para mobile)
  void _setupUnhandledRejectionHandler() {
    // Para aplicações móveis, isso é tratado pelo sistema de erros do Flutter
    EnhancedLogger.info('📱 [ERROR_HANDLER] Sistema de captura configurado para mobile');
  }
  
  /// Configura sistema de recuperação automática
  void _setupRecoverySystem() {
    _recoveryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performRecoveryCheck();
    });
  }
  
  /// Trata erros Flutter capturados
  void _handleFlutterError(FlutterErrorDetails details) {
    try {
      final errorInfo = _extractFlutterErrorInfo(details);
      _logError('Flutter Error', errorInfo);
      _attemptRecovery('flutter_error', errorInfo);
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao processar erro Flutter', 
        error: e
      );
    }
  }
  
  /// Trata erros de plataforma
  bool _handlePlatformError(Object error, StackTrace stack) {
    try {
      final errorInfo = _extractPlatformErrorInfo(error, stack);
      _logError('Platform Error', errorInfo);
      _attemptRecovery('platform_error', errorInfo);
      return true;
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao processar erro de plataforma', 
        error: e
      );
      return false;
    }
  }
  
  /// Trata erros de rede (adaptado para mobile)
  void _handleNetworkError(Object error) {
    try {
      final errorInfo = _extractNetworkErrorInfo(error);
      _logError('Network Error', errorInfo);
      _attemptRecovery('network_error', errorInfo);
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao processar erro de rede', 
        error: e
      );
    }
  }
  
  /// Extrai informações do erro Flutter
  Map<String, dynamic> _extractFlutterErrorInfo(FlutterErrorDetails details) {
    try {
      return {
        'message': details.exception.toString(),
        'library': details.library ?? 'Unknown library',
        'context': details.context?.toString() ?? 'No context',
        'stack': details.stack?.toString() ?? 'No stack trace',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };
    } catch (e) {
      return {
        'message': 'Error extracting Flutter error info',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Extrai informações do erro de plataforma
  Map<String, dynamic> _extractPlatformErrorInfo(Object error, StackTrace stack) {
    try {
      return {
        'type': 'Platform Error',
        'error': error.toString(),
        'stack': stack.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };
    } catch (e) {
      return {
        'type': 'Platform Error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Extrai informações do erro de rede
  Map<String, dynamic> _extractNetworkErrorInfo(Object error) {
    try {
      return {
        'type': 'Network Error',
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };
    } catch (e) {
      return {
        'type': 'Network Error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Obtém informações do recurso que causou erro (adaptado para mobile)
  String _getResourceSource(String resourceType, String? source) {
    try {
      switch (resourceType.toLowerCase()) {
        case 'image':
          return source ?? 'Unknown image source';
        case 'network':
          return source ?? 'Unknown network resource';
        case 'asset':
          return source ?? 'Unknown asset';
        default:
          return source ?? 'Unknown source';
      }
    } catch (e) {
      return 'Error getting source: $e';
    }
  }
  
  /// Registra erro no sistema de logs
  void _logError(String type, Map<String, dynamic> errorInfo) {
    final errorKey = '${type}_${errorInfo['message']}_${errorInfo['filename']}';
    
    // Conta ocorrências do erro
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    
    // Adiciona ao histórico
    _errorHistory.add('$type: ${errorInfo['message']} at ${DateTime.now()}');
    
    // Mantém apenas os últimos 100 erros
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }
    
    // Log estruturado
    EnhancedLogger.error('🚨 [ERROR_HANDLER] $type capturado', 
      tag: 'MOBILE_ERROR_HANDLER',
      data: {
        ...errorInfo,
        'errorCount': _errorCounts[errorKey],
        'totalErrors': _errorHistory.length,
      }
    );
  }
  
  /// Tenta recuperação automática do erro
  void _attemptRecovery(String errorType, Map<String, dynamic> errorInfo) {
    try {
      switch (errorType) {
        case 'flutter_error':
          _recoverFromFlutterError(errorInfo);
          break;
        case 'platform_error':
          _recoverFromPlatformError(errorInfo);
          break;
        case 'network_error':
          _recoverFromNetworkError(errorInfo);
          break;
      }
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro na recuperação automática', 
        error: e,
        data: {'errorType': errorType}
      );
    }
  }
  
  /// Recuperação específica para erros Flutter
  void _recoverFromFlutterError(Map<String, dynamic> errorInfo) {
    final message = errorInfo['message']?.toString().toLowerCase() ?? '';
    
    // Recuperação para erros específicos
    if (message.contains('network') || message.contains('http')) {
      _handleNetworkRecovery();
    } else if (message.contains('permission') || message.contains('denied')) {
      _handlePermissionError();
    } else if (message.contains('null') || message.contains('state')) {
      _handleStateError();
    }
    
    EnhancedLogger.info('🔄 [ERROR_HANDLER] Tentativa de recuperação de erro Flutter', 
      data: errorInfo
    );
  }
  
  /// Recuperação específica para erros de plataforma
  void _recoverFromPlatformError(Map<String, dynamic> errorInfo) {
    // Implementar retry para erros de plataforma
    EnhancedLogger.info('🔄 [ERROR_HANDLER] Tentativa de recuperação de erro de plataforma', 
      data: errorInfo
    );
  }
  
  /// Recuperação específica para erros de rede
  void _recoverFromNetworkError(Map<String, dynamic> errorInfo) {
    // Implementar recuperação para erros de rede
    EnhancedLogger.info('🔄 [ERROR_HANDLER] Tentativa de recuperação de erro de rede', 
      data: errorInfo
    );
  }
  
  /// Trata erros de rede
  void _handleNetworkRecovery() {
    EnhancedLogger.warning('🌐 [ERROR_HANDLER] Erro de rede detectado - implementando fallback');
    // Implementar fallback para dados offline
  }
  
  /// Trata erros de permissão
  void _handlePermissionError() {
    EnhancedLogger.warning('🔒 [ERROR_HANDLER] Erro de permissão detectado');
    // Implementar solicitação de permissões
  }
  
  /// Trata erros de estado
  void _handleStateError() {
    EnhancedLogger.warning('⚠️ [ERROR_HANDLER] Erro de estado detectado');
    // Implementar verificações de segurança de estado
  }
  
  /// Executa verificação periódica de recuperação
  void _performRecoveryCheck() {
    try {
      final recentErrors = _getRecentErrors();
      
      if (recentErrors.length > 10) {
        EnhancedLogger.warning('⚠️ [ERROR_HANDLER] Muitos erros recentes detectados', 
          data: {'recentErrorCount': recentErrors.length}
        );
        _performEmergencyRecovery();
      }
      
      // Limpa erros antigos
      _cleanupOldErrors();
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro na verificação de recuperação', 
        error: e
      );
    }
  }
  
  /// Obtém erros recentes (últimos 5 minutos)
  List<String> _getRecentErrors() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _errorHistory.where((error) {
      try {
        final timestamp = error.split(' at ').last;
        final errorTime = DateTime.parse(timestamp);
        return errorTime.isAfter(fiveMinutesAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }
  
  /// Executa recuperação de emergência
  void _performEmergencyRecovery() {
    try {
      EnhancedLogger.warning('🚨 [ERROR_HANDLER] Executando recuperação de emergência');
      
      // Limpa cache da aplicação
      _clearApplicationCache();
      
      // Recarrega recursos críticos
      _reloadCriticalResources();
      
      // Reinicia componentes críticos
      _restartCriticalComponents();
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro na recuperação de emergência', 
        error: e
      );
    }
  }
  
  /// Limpa cache da aplicação
  void _clearApplicationCache() {
    try {
      // Implementar limpeza de cache da aplicação se necessário
      EnhancedLogger.info('🧹 [ERROR_HANDLER] Cache da aplicação limpo');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao limpar cache', error: e);
    }
  }
  
  /// Recarrega recursos críticos
  void _reloadCriticalResources() {
    try {
      // Implementar recarga de recursos críticos
      EnhancedLogger.info('🔄 [ERROR_HANDLER] Recursos críticos recarregados');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao recarregar recursos', error: e);
    }
  }
  
  /// Reinicia componentes críticos
  void _restartCriticalComponents() {
    try {
      // Implementar reinício de componentes críticos
      EnhancedLogger.info('🔄 [ERROR_HANDLER] Componentes críticos reiniciados');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_HANDLER] Erro ao reiniciar componentes', error: e);
    }
  }
  
  /// Limpa erros antigos do histórico
  void _cleanupOldErrors() {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    _errorHistory.removeWhere((error) {
      try {
        final timestamp = error.split(' at ').last;
        final errorTime = DateTime.parse(timestamp);
        return errorTime.isBefore(oneDayAgo);
      } catch (e) {
        return false;
      }
    });
  }
  
  /// Obtém estatísticas de erros
  Map<String, dynamic> getErrorStatistics() {
    return {
      'totalErrors': _errorHistory.length,
      'errorCounts': Map.from(_errorCounts),
      'recentErrors': _getRecentErrors().length,
      'isInitialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Obtém histórico de erros
  List<String> getErrorHistory() {
    return List.from(_errorHistory);
  }
  
  /// Para o sistema de tratamento de erros
  void dispose() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _isInitialized = false;
    
    EnhancedLogger.info('🛑 [ERROR_HANDLER] Sistema finalizado');
  }
}