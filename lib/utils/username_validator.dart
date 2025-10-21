class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> suggestions;
  
  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestions = const [],
  });
}

class UsernameValidationResult {
  final bool isValid;
  final bool isAvailable;
  final String? errorMessage;
  final List<String> suggestions;
  final bool isChecking;
  
  const UsernameValidationResult({
    required this.isValid,
    required this.isAvailable,
    this.errorMessage,
    this.suggestions = const [],
    this.isChecking = false,
  });
  
  static const UsernameValidationResult empty = UsernameValidationResult(
    isValid: false,
    isAvailable: false,
    errorMessage: 'Username não pode estar vazio',
  );
  
  static const UsernameValidationResult checking = UsernameValidationResult(
    isValid: false,
    isAvailable: false,
    isChecking: true,
  );
}

class UsernameValidator {
  static const int minLength = 3;
  static const int maxLength = 20;
  
  static const List<String> reservedWords = [
    'admin', 'root', 'user', 'test', 'null', 'undefined',
    'api', 'www', 'mail', 'email', 'support', 'help',
    'info', 'contact', 'about', 'home', 'index',
    'deus', 'pai', 'jesus', 'cristo', 'santo', 'sagrado',
    'oficial', 'official', 'app', 'system', 'bot'
  ];
  
  /// Valida um username e retorna o resultado da validação
  static ValidationResult validate(String username) {
    // Remove @ se presente
    String cleanUsername = username.replaceAll('@', '').toLowerCase().trim();
    
    if (cleanUsername.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username não pode estar vazio',
      );
    }
    
    if (cleanUsername.length < minLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username deve ter pelo menos $minLength caracteres',
      );
    }
    
    if (cleanUsername.length > maxLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username deve ter no máximo $maxLength caracteres',
      );
    }
    
    if (!_hasValidCharacters(cleanUsername)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username pode conter apenas letras, números e underscore',
      );
    }
    
    if (_startsOrEndsWithUnderscore(cleanUsername)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username não pode começar ou terminar com underscore',
      );
    }
    
    if (_hasConsecutiveUnderscores(cleanUsername)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Username não pode ter underscores consecutivos',
      );
    }
    
    if (isReservedWord(cleanUsername)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Este username não está disponível',
        suggestions: _generateSuggestions(cleanUsername),
      );
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Verifica se o username contém apenas caracteres válidos
  static bool _hasValidCharacters(String username) {
    final validPattern = RegExp(r'^[a-z0-9_]+$');
    return validPattern.hasMatch(username);
  }
  
  /// Verifica se o username começa ou termina com underscore
  static bool _startsOrEndsWithUnderscore(String username) {
    return username.startsWith('_') || username.endsWith('_');
  }
  
  /// Verifica se o username tem underscores consecutivos
  static bool _hasConsecutiveUnderscores(String username) {
    return username.contains('__');
  }
  
  /// Verifica se é uma palavra reservada
  static bool isReservedWord(String username) {
    return reservedWords.contains(username.toLowerCase());
  }
  
  /// Gera sugestões baseadas no username fornecido
  static List<String> _generateSuggestions(String username) {
    List<String> suggestions = [];
    
    // Adicionar números
    for (int i = 1; i <= 99; i++) {
      suggestions.add('${username}$i');
      if (suggestions.length >= 5) break;
    }
    
    // Adicionar underscore com números
    for (int i = 1; i <= 99; i++) {
      suggestions.add('${username}_$i');
      if (suggestions.length >= 8) break;
    }
    
    // Adicionar prefixos comuns
    List<String> prefixes = ['the_', 'real_', 'official_'];
    for (String prefix in prefixes) {
      suggestions.add('$prefix$username');
      if (suggestions.length >= 10) break;
    }
    
    return suggestions.take(5).toList();
  }
  
  /// Formata o username adicionando @ se necessário
  static String formatUsername(String username) {
    String clean = username.replaceAll('@', '').toLowerCase().trim();
    return clean.isEmpty ? '' : '@$clean';
  }
  
  /// Remove @ do username
  static String cleanUsername(String username) {
    return username.replaceAll('@', '').toLowerCase().trim();
  }
  
  /// Verifica se um caractere é válido para username
  static bool isValidCharacter(String char) {
    final validPattern = RegExp(r'^[a-zA-Z0-9_]$');
    return validPattern.hasMatch(char);
  }
}