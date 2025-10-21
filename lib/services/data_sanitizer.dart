import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para sanitização e validação de dados
/// Resolve problemas de tipos incorretos (Timestamp vs Bool, etc.)
class DataSanitizer {
  static const String _tag = 'DATA_SANITIZER';
  
  /// Sanitiza dados completos de preferências
  static Map<String, dynamic> sanitizePreferencesData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    final corrections = <String>[];
    
    EnhancedLogger.info('Starting preferences data sanitization', 
      tag: _tag, 
      data: {'originalFields': data.keys.toList()}
    );
    
    // Sanitizar campos boolean específicos
    final booleanFields = [
      'allowInteractions',
      'isProfileComplete',
      'isDeusEPaiMember',
      'readyForPurposefulRelationship',
      'hasSinaisPreparationSeal',
    ];
    
    for (final field in booleanFields) {
      if (data.containsKey(field)) {
        final originalValue = data[field];
        final sanitizedValue = sanitizeBoolean(originalValue, _getDefaultForField(field));
        
        sanitized[field] = sanitizedValue;
        
        if (originalValue != sanitizedValue) {
          corrections.add('$field: ${originalValue.runtimeType} → bool');
          
          EnhancedLogger.info('Field sanitized', 
            tag: _tag, 
            data: {
              'field': field,
              'originalType': originalValue.runtimeType.toString(),
              'originalValue': originalValue.toString(),
              'sanitizedValue': sanitizedValue,
            }
          );
        }
      }
    }
    
    // Sanitizar completionTasks
    if (data.containsKey('completionTasks')) {
      final originalTasks = data['completionTasks'];
      final sanitizedTasks = sanitizeCompletionTasks(originalTasks);
      
      sanitized['completionTasks'] = sanitizedTasks;
      
      if (originalTasks != sanitizedTasks) {
        corrections.add('completionTasks: sanitized');
        
        EnhancedLogger.info('CompletionTasks sanitized', 
          tag: _tag, 
          data: {
            'originalType': originalTasks.runtimeType.toString(),
            'sanitizedTasks': sanitizedTasks,
          }
        );
      }
    }
    
    // Preservar outros campos sem modificação
    for (final entry in data.entries) {
      if (!sanitized.containsKey(entry.key) && entry.key != 'completionTasks') {
        sanitized[entry.key] = entry.value;
      }
    }
    
    // Adicionar metadados de sanitização
    if (corrections.isNotEmpty) {
      sanitized['lastSanitizedAt'] = Timestamp.fromDate(DateTime.now());
      sanitized['sanitizationVersion'] = '2.0.0';
      
      EnhancedLogger.success('Data sanitization completed', 
        tag: _tag, 
        data: {
          'correctionsApplied': corrections,
          'totalFields': sanitized.length,
        }
      );
    } else {
      EnhancedLogger.info('No sanitization needed', tag: _tag);
    }
    
    return sanitized;
  }
  
  /// Sanitiza um valor para boolean
  static bool sanitizeBoolean(dynamic value, bool defaultValue) {
    if (value == null) {
      return defaultValue;
    }
    
    if (value is bool) {
      return value;
    }
    
    if (value is Timestamp) {
      // Timestamp geralmente indica dados antigos que devem ser true
      EnhancedLogger.info('Converting Timestamp to boolean', 
        tag: _tag, 
        data: {
          'timestamp': value.toString(),
          'convertedTo': true,
        }
      );
      return true;
    }
    
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      if (lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes') {
        return true;
      }
      if (lowerValue == 'false' || lowerValue == '0' || lowerValue == 'no' || lowerValue.isEmpty) {
        return false;
      }
      // Para strings ambíguas, usar valor padrão
      EnhancedLogger.warning('Ambiguous string value for boolean', 
        tag: _tag, 
        data: {
          'value': value,
          'defaultUsed': defaultValue,
        }
      );
      return defaultValue;
    }
    
    if (value is num) {
      return value != 0;
    }
    
    // Para outros tipos, usar valor padrão
    EnhancedLogger.warning('Unknown type for boolean conversion', 
      tag: _tag, 
      data: {
        'type': value.runtimeType.toString(),
        'value': value.toString(),
        'defaultUsed': defaultValue,
      }
    );
    
    return defaultValue;
  }
  
  /// Sanitiza completionTasks
  static Map<String, bool> sanitizeCompletionTasks(dynamic tasks) {
    if (tasks == null) {
      return _getDefaultCompletionTasks();
    }
    
    if (tasks is! Map) {
      EnhancedLogger.warning('CompletionTasks is not a Map', 
        tag: _tag, 
        data: {
          'type': tasks.runtimeType.toString(),
          'value': tasks.toString(),
        }
      );
      return _getDefaultCompletionTasks();
    }
    
    final sanitized = <String, bool>{};
    final taskMap = tasks as Map<String, dynamic>;
    
    // Tarefas esperadas
    final expectedTasks = ['photos', 'identity', 'biography', 'preferences', 'certification'];
    
    for (final taskName in expectedTasks) {
      if (taskMap.containsKey(taskName)) {
        sanitized[taskName] = sanitizeBoolean(taskMap[taskName], false);
      } else {
        sanitized[taskName] = false;
      }
    }
    
    // Adicionar tarefas extras que possam existir
    for (final entry in taskMap.entries) {
      if (!sanitized.containsKey(entry.key)) {
        sanitized[entry.key] = sanitizeBoolean(entry.value, false);
      }
    }
    
    return sanitized;
  }
  
  /// Valida integridade dos dados sanitizados
  static bool validateSanitizedData(Map<String, dynamic> data) {
    try {
      // Verificar campos boolean obrigatórios
      final requiredBooleans = ['allowInteractions'];
      
      for (final field in requiredBooleans) {
        if (!data.containsKey(field) || data[field] is! bool) {
          EnhancedLogger.error('Validation failed: missing or invalid boolean field', 
            tag: _tag, 
            data: {
              'field': field,
              'value': data[field],
              'type': data[field]?.runtimeType.toString(),
            }
          );
          return false;
        }
      }
      
      // Verificar completionTasks
      if (data.containsKey('completionTasks')) {
        final tasks = data['completionTasks'];
        if (tasks is! Map<String, bool>) {
          EnhancedLogger.error('Validation failed: completionTasks is not Map<String, bool>', 
            tag: _tag, 
            data: {
              'type': tasks.runtimeType.toString(),
              'value': tasks.toString(),
            }
          );
          return false;
        }
      }
      
      EnhancedLogger.info('Data validation passed', tag: _tag);
      return true;
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Validation error', 
        tag: _tag, 
        error: e, 
        stackTrace: stackTrace,
        data: {'dataKeys': data.keys.toList()}
      );
      return false;
    }
  }
  
  /// Obtém valor padrão para um campo específico
  static bool _getDefaultForField(String field) {
    switch (field) {
      case 'allowInteractions':
        return true; // Por padrão, permitir interações
      case 'isProfileComplete':
        return false; // Por padrão, perfil não está completo
      case 'isDeusEPaiMember':
        return false; // Por padrão, não é membro
      case 'readyForPurposefulRelationship':
        return false; // Por padrão, não está pronto
      case 'hasSinaisPreparationSeal':
        return false; // Por padrão, não tem selo
      default:
        return false; // Padrão geral
    }
  }
  
  /// Obtém completionTasks padrão
  static Map<String, bool> _getDefaultCompletionTasks() {
    return {
      'photos': false,
      'identity': false,
      'biography': false,
      'preferences': false,
      'certification': false,
    };
  }
  
  /// Cria dados limpos para um novo perfil
  static Map<String, dynamic> createCleanPreferencesData({
    required bool allowInteractions,
    required String profileId,
  }) {
    final now = DateTime.now();
    
    return {
      'allowInteractions': allowInteractions,
      'updatedAt': Timestamp.fromDate(now),
      'lastSanitizedAt': Timestamp.fromDate(now),
      'sanitizationVersion': '2.0.0',
      'dataVersion': '2.0.0',
    };
  }
}