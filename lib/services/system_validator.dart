import 'dart:async';
import '../models/real_notification_model.dart';
import '../services/unified_notification_cache.dart';
import '../repositories/single_source_notification_repository.dart';
import '../services/conflict_resolver.dart';
import '../utils/enhanced_logger.dart';

/// Status de validação do sistema
enum ValidationStatus {
  healthy,      // Sistema funcionando normalmente
  warning,      // Problemas menores detectados
  critical,     // Problemas críticos que precisam atenção
  error         // Erros que impedem funcionamento
}

/// Resultado de validação
class ValidationResult {
  final ValidationStatus status;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final List<String> recommendations;

  ValidationResult({
    required this.status,
    required this.message,
    required this.details,
    required this.timestamp,
    this.recommendations = const [],
  });

  bool get isHealthy => status == ValidationStatus.healthy;
  bool get hasWarnings => status == ValidationStatus.warning;
  bool get isCritical => status == ValidationStatus.critical;
  bool get hasErrors => status == ValidationStatus.error;
}

/// Validador de sistema para notificações
class SystemValidator {
  static final SystemValidator _instance = SystemValidator._internal();
  factory SystemValidator() => _instance;
  SystemValidator._internal();

  final UnifiedNotificationCache _cache = UnifiedNotificationCache();
  final SingleSourceNotificationRepository _repository = SingleSourceNotificationRepository();
  final ConflictResolver _conflictResolver = ConflictResolver();
  
  final Map<String, Timer> _validationTimers = {};
  final Map<String, List<ValidationResult>> _validationHistory = {};

  /// Valida sistema completo para um usuário
  Future<ValidationResult> validateSystem(String userId) async {
    EnhancedLogger.log('🔍 [VALIDATOR] Validando sistema para: $userId');
    
    try {
      final checks = await Future.wait([
        _validateCache(userId),
        _validateRepository(userId),
        _validateConsistency(userId),
        _validatePerformance(userId),
      ]);
      
      final result = _aggregateValidationResults(checks);
      _storeValidationResult(userId, result);
      
      if (!result.isHealthy) {
        await _handleValidationIssues(userId, result);
      }
      
      return result;
      
    } catch (e) {
      EnhancedLogger.log('❌ [VALIDATOR] Erro na validação: $e');
      
      final errorResult = ValidationResult(
        status: ValidationStatus.error,
        message: 'Erro durante validação do sistema',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        recommendations: ['Verificar logs de erro', 'Reiniciar sistema'],
      );
      
      _storeValidationResult(userId, errorResult);
      return errorResult;
    }
  }

  /// Valida cache
  Future<ValidationResult> _validateCache(String userId) async {
    EnhancedLogger.log('📦 [VALIDATOR] Validando cache...');
    
    try {
      final hasCachedData = _cache.hasCachedData(userId);
      final cachedNotifications = _cache.getCachedNotifications(userId) ?? [];
      final cacheStats = _cache.getCacheStats();
      
      if (!hasCachedData) {
        return ValidationResult(
          status: ValidationStatus.warning,
          message: 'Cache vazio ou expirado',
          details: {
            'hasCachedData': hasCachedData,
            'cachedCount': cachedNotifications.length,
            'cacheStats': cacheStats,
          },
          timestamp: DateTime.now(),
          recommendations: ['Forçar atualização do cache'],
        );
      }
      
      return ValidationResult(
        status: ValidationStatus.healthy,
        message: 'Cache funcionando normalmente',
        details: {
          'hasCachedData': hasCachedData,
          'cachedCount': cachedNotifications.length,
          'cacheStats': cacheStats,
        },
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      return ValidationResult(
        status: ValidationStatus.error,
        message: 'Erro na validação do cache',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        recommendations: ['Reinicializar cache'],
      );
    }
  }

  /// Valida repositório
  Future<ValidationResult> _validateRepository(String userId) async {
    EnhancedLogger.log('🗄️ [VALIDATOR] Validando repositório...');
    
    try {
      final startTime = DateTime.now();
      final notifications = await _repository.getNotifications(userId);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final repositoryStats = _repository.getRepositoryStats();
      
      ValidationStatus status = ValidationStatus.healthy;
      final recommendations = <String>[];
      
      // Verifica tempo de resposta
      if (responseTime > 5000) {
        status = ValidationStatus.warning;
        recommendations.add('Otimizar performance do repositório');
      }
      
      // Verifica se há dados
      if (notifications.isEmpty && repositoryStats['cache']['totalNotifications'] == 0) {
        status = ValidationStatus.warning;
        recommendations.add('Verificar dados no Firebase');
      }
      
      return ValidationResult(
        status: status,
        message: 'Repositório validado',
        details: {
          'notificationCount': notifications.length,
          'responseTime': responseTime,
          'repositoryStats': repositoryStats,
        },
        timestamp: DateTime.now(),
        recommendations: recommendations,
      );
      
    } catch (e) {
      return ValidationResult(
        status: ValidationStatus.error,
        message: 'Erro na validação do repositório',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        recommendations: ['Verificar conexão com Firebase', 'Reinicializar repositório'],
      );
    }
  }

  /// Valida consistência entre sistemas
  Future<ValidationResult> _validateConsistency(String userId) async {
    EnhancedLogger.log('🔄 [VALIDATOR] Validando consistência...');
    
    try {
      final cachedData = _cache.getCachedNotifications(userId) ?? [];
      final repositoryData = await _repository.getNotifications(userId);
      
      final hasConflict = await _conflictResolver.detectConflict(userId, cachedData);
      final conflictStats = _conflictResolver.getConflictStats();
      
      ValidationStatus status = ValidationStatus.healthy;
      final recommendations = <String>[];
      
      if (hasConflict) {
        status = ValidationStatus.critical;
        recommendations.addAll([
          'Resolver conflitos detectados',
          'Forçar sincronização',
        ]);
      }
      
      // Verifica diferenças significativas
      final countDifference = (cachedData.length - repositoryData.length).abs();
      if (countDifference > 2) {
        status = ValidationStatus.warning;
        recommendations.add('Verificar sincronização entre cache e repositório');
      }
      
      return ValidationResult(
        status: status,
        message: hasConflict ? 'Conflitos detectados' : 'Sistema consistente',
        details: {
          'hasConflict': hasConflict,
          'cachedCount': cachedData.length,
          'repositoryCount': repositoryData.length,
          'countDifference': countDifference,
          'conflictStats': conflictStats,
        },
        timestamp: DateTime.now(),
        recommendations: recommendations,
      );
      
    } catch (e) {
      return ValidationResult(
        status: ValidationStatus.error,
        message: 'Erro na validação de consistência',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        recommendations: ['Reinicializar sistema de resolução de conflitos'],
      );
    }
  }

  /// Valida performance do sistema
  Future<ValidationResult> _validatePerformance(String userId) async {
    EnhancedLogger.log('⚡ [VALIDATOR] Validando performance...');
    
    try {
      final startTime = DateTime.now();
      
      // Testa múltiplas operações
      final futures = await Future.wait([
        _repository.getNotifications(userId),
        Future.value(_cache.getCachedNotifications(userId) ?? []),
        _conflictResolver.validateConsistency(userId),
      ]);
      
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      
      ValidationStatus status = ValidationStatus.healthy;
      final recommendations = <String>[];
      
      if (totalTime > 10000) {
        status = ValidationStatus.critical;
        recommendations.addAll([
          'Otimizar performance crítica',
          'Verificar conexão de rede',
          'Considerar cache mais agressivo',
        ]);
      } else if (totalTime > 5000) {
        status = ValidationStatus.warning;
        recommendations.add('Otimizar performance do sistema');
      }
      
      return ValidationResult(
        status: status,
        message: 'Performance validada',
        details: {
          'totalTime': totalTime,
          'operationsCompleted': futures.length,
        },
        timestamp: DateTime.now(),
        recommendations: recommendations,
      );
      
    } catch (e) {
      return ValidationResult(
        status: ValidationStatus.error,
        message: 'Erro na validação de performance',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        recommendations: ['Verificar recursos do sistema'],
      );
    }
  }

  /// Agrega resultados de validação
  ValidationResult _aggregateValidationResults(List<ValidationResult> results) {
    ValidationStatus overallStatus = ValidationStatus.healthy;
    final allDetails = <String, dynamic>{};
    final allRecommendations = <String>[];
    
    for (final result in results) {
      // Status mais crítico prevalece
      if (result.status.index > overallStatus.index) {
        overallStatus = result.status;
      }
      
      allDetails[result.message] = result.details;
      allRecommendations.addAll(result.recommendations);
    }
    
    String overallMessage;
    switch (overallStatus) {
      case ValidationStatus.healthy:
        overallMessage = 'Sistema funcionando normalmente';
        break;
      case ValidationStatus.warning:
        overallMessage = 'Sistema com avisos - atenção necessária';
        break;
      case ValidationStatus.critical:
        overallMessage = 'Sistema com problemas críticos';
        break;
      case ValidationStatus.error:
        overallMessage = 'Sistema com erros graves';
        break;
    }
    
    return ValidationResult(
      status: overallStatus,
      message: overallMessage,
      details: allDetails,
      timestamp: DateTime.now(),
      recommendations: allRecommendations.toSet().toList(),
    );
  }

  /// Processa problemas encontrados na validação
  Future<void> _handleValidationIssues(String userId, ValidationResult result) async {
    EnhancedLogger.log('🔧 [VALIDATOR] Processando problemas para: $userId');
    
    try {
      if (result.isCritical || result.hasErrors) {
        // Problemas críticos - ação imediata
        await _conflictResolver.forceConsistency(userId);
        await _repository.forceRefresh(userId);
      } else if (result.hasWarnings) {
        // Avisos - ação preventiva
        if (!_cache.hasCachedData(userId)) {
          await _repository.getNotifications(userId);
        }
      }
      
      EnhancedLogger.log('✅ [VALIDATOR] Problemas processados para: $userId');
      
    } catch (e) {
      EnhancedLogger.log('❌ [VALIDATOR] Erro ao processar problemas: $e');
    }
  }

  /// Armazena resultado de validação
  void _storeValidationResult(String userId, ValidationResult result) {
    _validationHistory.putIfAbsent(userId, () => []).add(result);
    
    // Mantém apenas os últimos 20 resultados
    final history = _validationHistory[userId]!;
    if (history.length > 20) {
      history.removeRange(0, history.length - 20);
    }
  }

  /// Configura validação automática
  void setupAutomaticValidation(String userId, {Duration interval = const Duration(minutes: 10)}) {
    EnhancedLogger.log('🤖 [VALIDATOR] Configurando validação automática para: $userId');
    
    _validationTimers[userId]?.cancel();
    
    _validationTimers[userId] = Timer.periodic(interval, (timer) {
      validateSystem(userId).catchError((e) {
        EnhancedLogger.log('❌ [VALIDATOR] Erro na validação automática: $e');
      });
    });
  }

  /// Obtém histórico de validações
  List<ValidationResult> getValidationHistory(String userId) {
    return _validationHistory[userId] ?? [];
  }

  /// Obtém estatísticas de validação
  Map<String, dynamic> getValidationStats() {
    final totalValidations = _validationHistory.values
        .fold<int>(0, (sum, list) => sum + list.length);
    
    final statusCounts = <ValidationStatus, int>{};
    for (final history in _validationHistory.values) {
      for (final result in history) {
        statusCounts[result.status] = (statusCounts[result.status] ?? 0) + 1;
      }
    }
    
    return {
      'totalUsers': _validationHistory.length,
      'totalValidations': totalValidations,
      'activeValidators': _validationTimers.length,
      'statusCounts': statusCounts.map((k, v) => MapEntry(k.toString(), v)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa recursos para um usuário
  void disposeUser(String userId) {
    EnhancedLogger.log('🧹 [VALIDATOR] Limpando recursos para: $userId');
    
    _validationTimers[userId]?.cancel();
    _validationTimers.remove(userId);
    
    _validationHistory.remove(userId);
  }

  /// Limpa todos os recursos
  void dispose() {
    EnhancedLogger.log('🧹 [VALIDATOR] Limpando todos os recursos');
    
    for (final timer in _validationTimers.values) {
      timer.cancel();
    }
    _validationTimers.clear();
    
    _validationHistory.clear();
  }
}