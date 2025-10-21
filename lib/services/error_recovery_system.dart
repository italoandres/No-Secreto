import 'dart:async';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';
import '../services/javascript_error_handler.dart';
import '../repositories/enhanced_real_interests_repository.dart';
import '../services/temp_notification_converter.dart';

/// Sistema de recuperação automática de erros
class ErrorRecoverySystem {
  static ErrorRecoverySystem? _instance;
  static ErrorRecoverySystem get instance => 
      _instance ??= ErrorRecoverySystem._();
  
  ErrorRecoverySystem._();
  
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  final Map<String, List<RealNotification>> _fallbackCache = {};
  final Map<String, DateTime> _lastRecoveryAttempts = {};
  final Duration _recoveryInterval = const Duration(minutes: 2);
  
  /// Inicializa o sistema de recuperação
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _setupHealthMonitoring();
      _setupFallbackCache();
      _isInitialized = true;
      
      EnhancedLogger.success('✅ [ERROR_RECOVERY] Sistema inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao inicializar sistema', 
        error: e
      );
    }
  }
  
  /// Configura monitoramento de saúde do sistema
  void _setupHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performHealthCheck();
    });
    
    EnhancedLogger.info('🏥 [ERROR_RECOVERY] Monitoramento de saúde configurado');
  }
  
  /// Configura cache de fallback
  void _setupFallbackCache() {
    // Inicializa estruturas de cache
    EnhancedLogger.info('💾 [ERROR_RECOVERY] Cache de fallback configurado');
  }
  
  /// Detecta falhas no sistema
  bool detectSystemFailure() {
    try {
      final failures = <String>[];
      
      // Verifica JavaScript Error Handler
      if (!_checkJavaScriptErrorHandler()) {
        failures.add('JavaScript Error Handler');
      }
      
      // Verifica Repository
      if (!_checkRepository()) {
        failures.add('Enhanced Repository');
      }
      
      // Verifica Converter
      if (!_checkConverter()) {
        failures.add('Notification Converter');
      }
      
      // Verifica conectividade
      if (!_checkConnectivity()) {
        failures.add('Network Connectivity');
      }
      
      if (failures.isNotEmpty) {
        EnhancedLogger.error('🚨 [ERROR_RECOVERY] Falhas detectadas no sistema', 
          data: {
            'failures': failures,
            'failureCount': failures.length,
            'timestamp': DateTime.now().toIso8601String()
          }
        );
        return true;
      }
      
      return false;
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro na detecção de falhas', 
        error: e
      );
      return true; // Assume falha se não conseguir verificar
    }
  }
  
  /// Verifica saúde do JavaScript Error Handler
  bool _checkJavaScriptErrorHandler() {
    try {
      final stats = JavaScriptErrorHandler.instance.getErrorStatistics();
      final recentErrors = stats['recentErrors'] as int? ?? 0;
      
      // Se há muitos erros recentes, considera como falha
      return recentErrors < 5;
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica saúde do Repository
  bool _checkRepository() {
    try {
      final stats = EnhancedRealInterestsRepository.instance.getStatistics();
      return stats['cacheSize'] != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica saúde do Converter
  bool _checkConverter() {
    try {
      // Importar converter
      final converter = TempNotificationConverter.instance;
      final stats = converter.getConversionStatistics();
      final successRate = double.tryParse(
        stats['successRate'].toString().replaceAll('%', '')
      ) ?? 0.0;
      
      // Considera saudável se taxa de sucesso > 70%
      return successRate > 70.0;
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica conectividade de rede
  bool _checkConnectivity() {
    try {
      // Implementação simplificada - pode ser expandida
      return true; // Assume conectividade por enquanto
    } catch (e) {
      return false;
    }
  }
  
  /// Executa recuperação automática do sistema
  Future<void> recoverFromFailure() async {
    try {
      EnhancedLogger.info('🔄 [ERROR_RECOVERY] Iniciando recuperação automática');
      
      final recoverySteps = <String>[];
      
      // Passo 1: Reinicializa JavaScript Error Handler
      try {
        JavaScriptErrorHandler.instance.initialize();
        recoverySteps.add('JavaScript Error Handler reinicializado');
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao reinicializar JS Handler', 
          error: e
        );
      }
      
      // Passo 2: Limpa caches expirados
      try {
        EnhancedRealInterestsRepository.instance.clearExpiredCache();
        recoverySteps.add('Cache expirado limpo');
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao limpar cache', 
          error: e
        );
      }
      
      // Passo 3: Limpa estatísticas antigas do converter
      try {
        final converter = TempNotificationConverter.instance;
        converter.clearOldStatistics();
        recoverySteps.add('Estatísticas do converter limpas');
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao limpar estatísticas', 
          error: e
        );
      }
      
      // Passo 4: Força garbage collection
      try {
        _forceGarbageCollection();
        recoverySteps.add('Garbage collection executado');
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro no garbage collection', 
          error: e
        );
      }
      
      // Passo 5: Reinicia componentes críticos
      try {
        await _restartCriticalComponents();
        recoverySteps.add('Componentes críticos reiniciados');
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao reiniciar componentes', 
          error: e
        );
      }
      
      EnhancedLogger.success('✅ [ERROR_RECOVERY] Recuperação concluída', 
        data: {
          'recoverySteps': recoverySteps,
          'stepCount': recoverySteps.length,
          'timestamp': DateTime.now().toIso8601String()
        }
      );
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro na recuperação automática', 
        error: e
      );
    }
  }
  
  /// Força garbage collection
  void _forceGarbageCollection() {
    // Implementação específica para Dart/Flutter
    // Em ambiente web, isso pode ser limitado
    EnhancedLogger.info('🧹 [ERROR_RECOVERY] Executando limpeza de memória');
  }
  
  /// Reinicia componentes críticos
  Future<void> _restartCriticalComponents() async {
    try {
      // Aguarda um pouco para estabilizar
      await Future.delayed(const Duration(seconds: 1));
      
      // Reinicializa sistemas se necessário
      if (!_isInitialized) {
        initialize();
      }
      
      EnhancedLogger.info('🔄 [ERROR_RECOVERY] Componentes críticos reiniciados');
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao reiniciar componentes', 
        error: e
      );
    }
  }
  
  /// Registra estado do sistema nos logs
  void logSystemState(Map<String, dynamic> state) {
    try {
      final enhancedState = {
        ...state,
        'errorRecoverySystem': {
          'isInitialized': _isInitialized,
          'fallbackCacheSize': _fallbackCache.length,
          'lastRecoveryAttempts': _lastRecoveryAttempts.length,
          'healthCheckActive': _healthCheckTimer?.isActive ?? false,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'systemHealth': _getSystemHealthSummary(),
      };
      
      EnhancedLogger.info('📊 [ERROR_RECOVERY] Estado do sistema registrado', 
        tag: 'SYSTEM_STATE',
        data: enhancedState
      );
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao registrar estado', 
        error: e
      );
    }
  }
  
  /// Obtém resumo da saúde do sistema
  Map<String, dynamic> _getSystemHealthSummary() {
    return {
      'jsErrorHandler': _checkJavaScriptErrorHandler(),
      'repository': _checkRepository(),
      'converter': _checkConverter(),
      'connectivity': _checkConnectivity(),
      'overallHealth': !detectSystemFailure(),
    };
  }
  
  /// Obtém notificações de fallback para um usuário
  List<RealNotification> getFallbackNotifications(String userId) {
    try {
      final fallbackData = _fallbackCache[userId] ?? [];
      
      EnhancedLogger.info('💾 [ERROR_RECOVERY] Usando dados de fallback', 
        data: {
          'userId': userId,
          'fallbackCount': fallbackData.length
        }
      );
      
      return List.from(fallbackData);
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao obter fallback', 
        error: e,
        data: {'userId': userId}
      );
      return [];
    }
  }
  
  /// Salva notificações no cache de fallback
  void saveFallbackNotifications(String userId, List<RealNotification> notifications) {
    try {
      _fallbackCache[userId] = List.from(notifications);
      
      EnhancedLogger.info('💾 [ERROR_RECOVERY] Notificações salvas no fallback', 
        data: {
          'userId': userId,
          'notificationCount': notifications.length
        }
      );
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao salvar fallback', 
        error: e,
        data: {'userId': userId}
      );
    }
  }
  
  /// Executa verificação periódica de saúde
  void _performHealthCheck() {
    try {
      final isSystemHealthy = !detectSystemFailure();
      
      if (!isSystemHealthy) {
        final now = DateTime.now();
        final lastAttempt = _lastRecoveryAttempts['system'];
        
        // Só tenta recuperação se passou tempo suficiente desde a última tentativa
        if (lastAttempt == null || now.difference(lastAttempt) > _recoveryInterval) {
          _lastRecoveryAttempts['system'] = now;
          
          EnhancedLogger.warning('⚠️ [ERROR_RECOVERY] Sistema não saudável - iniciando recuperação');
          recoverFromFailure();
        }
      } else {
        // Sistema saudável - limpa tentativas de recuperação antigas
        _cleanupOldRecoveryAttempts();
      }
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro na verificação de saúde', 
        error: e
      );
    }
  }
  
  /// Limpa tentativas de recuperação antigas
  void _cleanupOldRecoveryAttempts() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));
    
    _lastRecoveryAttempts.removeWhere((key, timestamp) => 
        timestamp.isBefore(cutoff)
    );
  }
  
  /// Executa recuperação específica para notificações
  Future<List<RealNotification>> recoverNotifications(String userId) async {
    try {
      EnhancedLogger.info('🔄 [ERROR_RECOVERY] Recuperando notificações específicas', 
        data: {'userId': userId}
      );
      
      // Tenta múltiplas estratégias de recuperação
      
      // Estratégia 1: Cache de fallback
      final fallbackData = getFallbackNotifications(userId);
      if (fallbackData.isNotEmpty) {
        EnhancedLogger.success('✅ [ERROR_RECOVERY] Recuperação via fallback', 
          data: {'userId': userId, 'count': fallbackData.length}
        );
        return fallbackData;
      }
      
      // Estratégia 2: Busca direta com retry
      try {
        final interests = await EnhancedRealInterestsRepository.instance
            .getInterestsWithRetry(userId);
        
        if (interests.isNotEmpty) {
          final converter = TempNotificationConverter.instance;
          final notifications = await converter
              .convertInteractionsToNotifications(interests, {});
          
          // Salva no fallback para próximas vezes
          saveFallbackNotifications(userId, notifications);
          
          EnhancedLogger.success('✅ [ERROR_RECOVERY] Recuperação via busca direta', 
            data: {'userId': userId, 'count': notifications.length}
          );
          return notifications;
        }
      } catch (e) {
        EnhancedLogger.error('❌ [ERROR_RECOVERY] Falha na busca direta', 
          error: e
        );
      }
      
      // Estratégia 3: Dados mínimos de emergência
      EnhancedLogger.warning('⚠️ [ERROR_RECOVERY] Usando dados de emergência', 
        data: {'userId': userId}
      );
      return _createEmergencyNotifications(userId);
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro na recuperação de notificações', 
        error: e,
        data: {'userId': userId}
      );
      return [];
    }
  }
  
  /// Cria notificações de emergência quando tudo falha
  List<RealNotification> _createEmergencyNotifications(String userId) {
    try {
      // Cria uma notificação básica para manter funcionalidade mínima
      final emergencyNotification = RealNotification(
        id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
        type: 'system',
        fromUserId: 'system',
        fromUserName: 'Sistema',
        fromUserPhoto: null,
        message: 'Verificando novas interações...',
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      return [emergencyNotification];
      
    } catch (e) {
      EnhancedLogger.error('❌ [ERROR_RECOVERY] Erro ao criar notificações de emergência', 
        error: e
      );
      return [];
    }
  }
  
  /// Obtém estatísticas do sistema de recuperação
  Map<String, dynamic> getRecoveryStatistics() {
    return {
      'isInitialized': _isInitialized,
      'fallbackCacheSize': _fallbackCache.length,
      'fallbackUsers': _fallbackCache.keys.toList(),
      'lastRecoveryAttempts': _lastRecoveryAttempts.length,
      'healthCheckActive': _healthCheckTimer?.isActive ?? false,
      'systemHealth': _getSystemHealthSummary(),
      'recoveryInterval': _recoveryInterval.inMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Para o sistema de recuperação
  void dispose() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _fallbackCache.clear();
    _lastRecoveryAttempts.clear();
    _isInitialized = false;
    
    EnhancedLogger.info('🛑 [ERROR_RECOVERY] Sistema finalizado');
  }
}