/// Utilitário para validação de contextos de stories
///
/// Esta classe fornece métodos para validar e normalizar contextos,
/// garantindo que apenas contextos válidos sejam utilizados no sistema.
class ContextValidator {
  /// Lista de contextos válidos no sistema
  static const List<String> _validContexts = [
    'principal',
    'sinais_rebeca',
    'sinais_isaque',
    'nosso_proposito'
  ];

  /// Verifica se um contexto é válido
  ///
  /// [contexto] - O contexto a ser validado
  /// Retorna true se o contexto for válido, false caso contrário
  static bool isValidContext(String? contexto) {
    if (contexto == null || contexto.isEmpty) {
      return false;
    }
    return _validContexts.contains(contexto);
  }

  /// Retorna o contexto padrão do sistema
  static String getDefaultContext() => 'principal';

  /// Normaliza um contexto, retornando o contexto padrão se inválido
  ///
  /// [contexto] - O contexto a ser normalizado
  /// Retorna o contexto se válido, ou o contexto padrão se inválido
  static String normalizeContext(String? contexto) {
    return isValidContext(contexto) ? contexto! : getDefaultContext();
  }

  /// Obtém todos os contextos válidos
  static List<String> getValidContexts() => List.from(_validContexts);

  /// Valida e loga operação de contexto
  ///
  /// [contexto] - O contexto a ser validado
  /// [operation] - Nome da operação sendo executada
  /// [debugEnabled] - Se deve fazer log de debug
  static bool validateAndLog(String? contexto, String operation,
      {bool debugEnabled = true}) {
    final isValid = isValidContext(contexto);

    if (debugEnabled) {
      if (isValid) {
        print('✅ CONTEXT_VALIDATOR: $operation - Contexto válido: "$contexto"');
      } else {
        print(
            '❌ CONTEXT_VALIDATOR: $operation - Contexto inválido: "$contexto" (será normalizado para "${getDefaultContext()}")');
      }
    }

    return isValid;
  }

  /// Obtém a coleção do Firestore baseada no contexto
  ///
  /// [contexto] - O contexto para determinar a coleção
  /// Retorna o nome da coleção correspondente ao contexto
  static String getCollectionForContext(String contexto) {
    final normalizedContext = normalizeContext(contexto);

    switch (normalizedContext) {
      case 'sinais_isaque':
        return 'stories_sinais_isaque';
      case 'sinais_rebeca':
        return 'stories_sinais_rebeca';
      case 'principal':
      default:
        return 'stories_files';
    }
  }

  /// Valida se um contexto corresponde à coleção esperada
  ///
  /// [contexto] - O contexto a ser validado
  /// [collection] - A coleção esperada
  static bool validateContextForCollection(
      String? contexto, String collection) {
    final normalizedContext = normalizeContext(contexto);
    final expectedCollection = getCollectionForContext(normalizedContext);
    return expectedCollection == collection;
  }
}
