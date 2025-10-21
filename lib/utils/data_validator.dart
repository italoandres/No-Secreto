import 'package:flutter/foundation.dart';
import 'enhanced_logger.dart';

/// Utilitário para validação e sanitização de dados
class DataValidator {
  
  /// Valida e sanitiza dados de perfil espiritual
  static Map<String, dynamic> validateSpiritualProfile(Map<String, dynamic> data) {
    final validatedData = Map<String, dynamic>.from(data);
    final issues = <String>[];
    
    try {
      // Validar campos boolean
      final booleanFields = [
        'isProfileComplete',
        'isDeusEPaiMember', 
        'readyForPurposefulRelationship',
        'hasSinaisPreparationSeal',
        'allowInteractions'
      ];
      
      for (final field in booleanFields) {
        if (validatedData[field] != null && validatedData[field] is! bool) {
          issues.add('$field has incorrect type: ${validatedData[field].runtimeType}');
          validatedData[field] = _safeBooleanConversion(validatedData[field]);
        }
      }
      
      // Validar campos de string
      final stringFields = ['purpose', 'nonNegotiableValue', 'faithPhrase', 'aboutMe', 'city'];
      for (final field in stringFields) {
        if (validatedData[field] != null) {
          if (validatedData[field] is! String) {
            issues.add('$field has incorrect type: ${validatedData[field].runtimeType}');
            validatedData[field] = validatedData[field].toString();
          }
          
          // Sanitizar string
          validatedData[field] = _sanitizeString(validatedData[field]);
        }
      }
      
      // Validar idade
      if (validatedData['age'] != null) {
        if (validatedData['age'] is! int && validatedData['age'] is! double) {
          final ageValue = int.tryParse(validatedData['age'].toString());
          if (ageValue != null && ageValue > 0 && ageValue < 150) {
            validatedData['age'] = ageValue;
          } else {
            issues.add('Invalid age value: ${validatedData['age']}');
            validatedData['age'] = null;
          }
        } else {
          final age = validatedData['age'] as num;
          if (age <= 0 || age >= 150) {
            issues.add('Age out of valid range: $age');
            validatedData['age'] = null;
          }
        }
      }
      
      // Validar URLs de imagem
      final imageFields = ['mainPhotoUrl', 'secondaryPhoto1Url', 'secondaryPhoto2Url'];
      for (final field in imageFields) {
        if (validatedData[field] != null) {
          final url = validatedData[field].toString();
          if (!_isValidImageUrl(url)) {
            issues.add('Invalid image URL for $field: $url');
            validatedData[field] = null;
          }
        }
      }
      
      // Validar completionTasks
      if (validatedData['completionTasks'] != null) {
        final tasks = validatedData['completionTasks'];
        if (tasks is Map<String, dynamic>) {
          final validatedTasks = <String, bool>{};
          for (final entry in tasks.entries) {
            if (entry.value is! bool) {
              issues.add('completionTasks.${entry.key} has incorrect type: ${entry.value.runtimeType}');
              validatedTasks[entry.key] = _safeBooleanConversion(entry.value);
            } else {
              validatedTasks[entry.key] = entry.value as bool;
            }
          }
          validatedData['completionTasks'] = validatedTasks;
        }
      }
      
      if (issues.isNotEmpty) {
        EnhancedLogger.warning('Data validation issues found', tag: 'VALIDATION', data: {
          'issues': issues,
          'dataKeys': validatedData.keys.toList(),
        });
      }
      
      return validatedData;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Error during data validation', 
        tag: 'VALIDATION', 
        error: e, 
        stackTrace: stackTrace,
        data: {'originalData': data}
      );
      return data; // Retorna dados originais em caso de erro
    }
  }
  
  /// Valida e sanitiza dados de usuário
  static Map<String, dynamic> validateUserData(Map<String, dynamic> data) {
    final validatedData = Map<String, dynamic>.from(data);
    final issues = <String>[];
    
    try {
      // Validar campos boolean
      final booleanFields = ['perfilIsComplete', 'isAdmin'];
      for (final field in booleanFields) {
        if (validatedData[field] != null && validatedData[field] is! bool) {
          issues.add('$field has incorrect type: ${validatedData[field].runtimeType}');
          validatedData[field] = _safeBooleanConversion(validatedData[field]);
        }
      }
      
      // Validar e sanitizar nome
      if (validatedData['nome'] != null) {
        if (validatedData['nome'] is! String) {
          validatedData['nome'] = validatedData['nome'].toString();
        }
        validatedData['nome'] = _sanitizeString(validatedData['nome']);
        
        if (validatedData['nome'].isEmpty) {
          issues.add('Nome is empty after sanitization');
        }
      }
      
      // Validar username
      if (validatedData['username'] != null) {
        if (validatedData['username'] is! String) {
          validatedData['username'] = validatedData['username'].toString();
        }
        validatedData['username'] = _sanitizeUsername(validatedData['username']);
      }
      
      // Validar email
      if (validatedData['email'] != null) {
        if (validatedData['email'] is! String) {
          validatedData['email'] = validatedData['email'].toString();
        }
        
        if (!_isValidEmail(validatedData['email'])) {
          issues.add('Invalid email format: ${validatedData['email']}');
        }
      }
      
      // Validar URLs de imagem
      final imageFields = ['imgUrl', 'imgBgUrl'];
      for (final field in imageFields) {
        if (validatedData[field] != null) {
          final url = validatedData[field].toString();
          if (!_isValidImageUrl(url)) {
            issues.add('Invalid image URL for $field: $url');
            validatedData[field] = null;
          }
        }
      }
      
      if (issues.isNotEmpty) {
        EnhancedLogger.warning('User data validation issues found', tag: 'VALIDATION', data: {
          'issues': issues,
          'userId': validatedData['id'],
        });
      }
      
      return validatedData;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Error during user data validation', 
        tag: 'VALIDATION', 
        error: e, 
        stackTrace: stackTrace,
        data: {'originalData': data}
      );
      return data;
    }
  }
  
  /// Conversão segura para boolean
  static bool _safeBooleanConversion(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
    }
    // Para Timestamp e outros tipos, considera true se não for null
    return true;
  }
  
  /// Sanitiza string removendo caracteres perigosos
  static String _sanitizeString(String input) {
    if (input.isEmpty) return input;
    
    // Remove caracteres de controle e normaliza espaços
    String sanitized = input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove caracteres de controle
        .replaceAll(RegExp(r'\s+'), ' ') // Normaliza espaços
        .trim();
    
    // Remove scripts potencialmente perigosos
    sanitized = sanitized
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    
    return sanitized;
  }
  
  /// Sanitiza username
  static String _sanitizeUsername(String username) {
    if (username.isEmpty) return username;
    
    // Remove @ se estiver no início
    String sanitized = username.startsWith('@') ? username.substring(1) : username;
    
    // Mantém apenas caracteres alfanuméricos, underscore e ponto
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '');
    
    // Remove pontos e underscores consecutivos
    sanitized = sanitized.replaceAll(RegExp(r'[._]{2,}'), '.');
    
    // Remove ponto/underscore do início e fim
    sanitized = sanitized.replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    
    return sanitized.toLowerCase();
  }
  
  /// Valida formato de email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Valida URL de imagem
  static bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Verifica se é uma URL válida
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }
      
      // Verifica se é do Firebase Storage (mais seguro)
      if (url.contains('firebasestorage.googleapis.com')) {
        return true;
      }
      
      // Para outras URLs, verifica extensão de imagem
      final path = uri.path.toLowerCase();
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      return imageExtensions.any((ext) => path.endsWith(ext));
    } catch (e) {
      return false;
    }
  }
  
  /// Valida se um username está disponível (formato)
  static bool isValidUsernameFormat(String username) {
    if (username.isEmpty || username.length < 3 || username.length > 30) {
      return false;
    }
    
    // Deve começar com letra ou número
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(username)) {
      return false;
    }
    
    // Deve terminar com letra ou número
    if (!RegExp(r'[a-zA-Z0-9]$').hasMatch(username)) {
      return false;
    }
    
    // Apenas letras, números, pontos e underscores
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return false;
    }
    
    // Não pode ter pontos ou underscores consecutivos
    if (RegExp(r'[._]{2,}').hasMatch(username)) {
      return false;
    }
    
    return true;
  }
  
  /// Gera sugestões de username baseado no nome
  static List<String> generateUsernameSuggestions(String name) {
    if (name.isEmpty) return [];
    
    final suggestions = <String>[];
    final baseName = _sanitizeUsername(name.toLowerCase());
    
    if (baseName.isEmpty) return [];
    
    // Sugestão básica
    suggestions.add(baseName);
    
    // Com números
    for (int i = 1; i <= 99; i++) {
      suggestions.add('${baseName}$i');
      if (suggestions.length >= 10) break;
    }
    
    // Com underscores
    suggestions.add('${baseName}_');
    suggestions.add('_$baseName');
    
    // Variações com partes do nome
    if (baseName.length > 6) {
      suggestions.add(baseName.substring(0, 6));
      suggestions.add('${baseName.substring(0, 4)}${DateTime.now().year % 100}');
    }
    
    return suggestions.take(10).toList();
  }
}