import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_sanitizer.dart';
import '../utils/enhanced_logger.dart';

/// Modelo de dados para preferências de interação
/// Garante tipo-segurança e serialização consistente
class PreferencesData {
  final bool allowInteractions;
  final DateTime updatedAt;
  final String version;
  final DateTime? lastSanitizedAt;
  final String? sanitizationVersion;
  
  const PreferencesData({
    required this.allowInteractions,
    required this.updatedAt,
    this.version = '2.0.0',
    this.lastSanitizedAt,
    this.sanitizationVersion,
  });
  
  /// Cria instância com valores padrão
  factory PreferencesData.defaultValues({
    bool allowInteractions = true,
  }) {
    final now = DateTime.now();
    return PreferencesData(
      allowInteractions: allowInteractions,
      updatedAt: now,
      version: '2.0.0',
      lastSanitizedAt: now,
      sanitizationVersion: '2.0.0',
    );
  }
  
  /// Cria instância a partir de dados do Firestore com sanitização automática
  factory PreferencesData.fromFirestore(Map<String, dynamic> data) {
    try {
      EnhancedLogger.info('Creating PreferencesData from Firestore', 
        tag: 'PREFERENCES_DATA',
        data: {
          'originalKeys': data.keys.toList(),
          'allowInteractionsType': data['allowInteractions']?.runtimeType.toString(),
        }
      );
      
      // Sanitizar dados antes de criar o objeto
      final sanitizedData = DataSanitizer.sanitizePreferencesData(data);
      
      // Extrair campos com valores padrão seguros
      final allowInteractions = DataSanitizer.sanitizeBoolean(
        sanitizedData['allowInteractions'], 
        true
      );
      
      final updatedAt = _extractDateTimeNonNull(
        sanitizedData['updatedAt'], 
        DateTime.now()
      );
      
      final version = sanitizedData['version'] as String? ?? 
                     sanitizedData['dataVersion'] as String? ?? 
                     '2.0.0';
      
      final lastSanitizedAt = _extractDateTime(
        sanitizedData['lastSanitizedAt'], 
        null
      );
      
      final sanitizationVersion = sanitizedData['sanitizationVersion'] as String?;
      
      final result = PreferencesData(
        allowInteractions: allowInteractions,
        updatedAt: updatedAt,
        version: version,
        lastSanitizedAt: lastSanitizedAt,
        sanitizationVersion: sanitizationVersion,
      );
      
      EnhancedLogger.success('PreferencesData created successfully', 
        tag: 'PREFERENCES_DATA',
        data: {
          'allowInteractions': result.allowInteractions,
          'version': result.version,
          'sanitized': lastSanitizedAt != null,
        }
      );
      
      return result;
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to create PreferencesData from Firestore', 
        tag: 'PREFERENCES_DATA',
        error: e,
        stackTrace: stackTrace,
        data: {'originalData': data}
      );
      
      // Retornar valores padrão em caso de erro
      return PreferencesData.defaultValues();
    }
  }
  
  /// Converte para formato do Firestore
  Map<String, dynamic> toFirestore() {
    final data = {
      'allowInteractions': allowInteractions,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
    };
    
    if (lastSanitizedAt != null) {
      data['lastSanitizedAt'] = Timestamp.fromDate(lastSanitizedAt!);
    }
    
    if (sanitizationVersion != null) {
      data['sanitizationVersion'] = sanitizationVersion!;
    }
    
    // Validar dados antes de retornar
    if (!DataSanitizer.validateSanitizedData(data)) {
      EnhancedLogger.error('Invalid data in toFirestore', 
        tag: 'PREFERENCES_DATA',
        data: data
      );
      throw Exception('Invalid preferences data for Firestore');
    }
    
    EnhancedLogger.info('PreferencesData converted to Firestore format', 
      tag: 'PREFERENCES_DATA',
      data: {
        'allowInteractions': allowInteractions,
        'hasTimestamp': data['updatedAt'] is Timestamp,
      }
    );
    
    return data;
  }
  
  /// Cria cópia com valores atualizados
  PreferencesData copyWith({
    bool? allowInteractions,
    DateTime? updatedAt,
    String? version,
    DateTime? lastSanitizedAt,
    String? sanitizationVersion,
  }) {
    return PreferencesData(
      allowInteractions: allowInteractions ?? this.allowInteractions,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      lastSanitizedAt: lastSanitizedAt ?? this.lastSanitizedAt,
      sanitizationVersion: sanitizationVersion ?? this.sanitizationVersion,
    );
  }
  
  /// Verifica se os dados foram sanitizados
  bool get wasSanitized => lastSanitizedAt != null && sanitizationVersion != null;
  
  /// Verifica se é uma versão atual
  bool get isCurrentVersion => version == '2.0.0';
  
  /// Extrai DateTime de forma segura
  static DateTime? _extractDateTime(dynamic value, DateTime? defaultValue) {
    if (value == null) {
      return defaultValue;
    }
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        EnhancedLogger.warning('Failed to parse DateTime from string', 
          tag: 'PREFERENCES_DATA',
          data: {'value': value, 'error': e.toString()}
        );
        return defaultValue;
      }
    }
    
    EnhancedLogger.warning('Unknown DateTime type', 
      tag: 'PREFERENCES_DATA',
      data: {
        'type': value.runtimeType.toString(),
        'value': value.toString(),
      }
    );
    
    return defaultValue;
  }
  
  /// Extrai DateTime garantindo valor não-nulo
  static DateTime _extractDateTimeNonNull(dynamic value, DateTime defaultValue) {
    return _extractDateTime(value, defaultValue) ?? defaultValue;
  }
  
  @override
  String toString() {
    return 'PreferencesData('
           'allowInteractions: $allowInteractions, '
           'updatedAt: $updatedAt, '
           'version: $version, '
           'wasSanitized: $wasSanitized'
           ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PreferencesData &&
           other.allowInteractions == allowInteractions &&
           other.updatedAt == updatedAt &&
           other.version == version &&
           other.lastSanitizedAt == lastSanitizedAt &&
           other.sanitizationVersion == sanitizationVersion;
  }
  
  @override
  int get hashCode {
    return allowInteractions.hashCode ^
           updatedAt.hashCode ^
           version.hashCode ^
           lastSanitizedAt.hashCode ^
           sanitizationVersion.hashCode;
  }
}