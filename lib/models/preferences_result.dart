import 'preferences_data.dart';

/// Resultado de operações de preferências
/// Encapsula sucesso, erro e dados de forma tipo-segura
class PreferencesResult {
  final bool success;
  final String? errorMessage;
  final PreferencesData? data;
  final List<String> appliedCorrections;
  final PreferencesError? errorType;
  final Duration? operationDuration;
  final String? strategyUsed;

  const PreferencesResult({
    required this.success,
    this.errorMessage,
    this.data,
    this.appliedCorrections = const [],
    this.errorType,
    this.operationDuration,
    this.strategyUsed,
  });

  /// Cria resultado de sucesso
  factory PreferencesResult.success({
    required PreferencesData data,
    List<String> appliedCorrections = const [],
    Duration? operationDuration,
    String? strategyUsed,
  }) {
    return PreferencesResult(
      success: true,
      data: data,
      appliedCorrections: appliedCorrections,
      operationDuration: operationDuration,
      strategyUsed: strategyUsed,
    );
  }

  /// Cria resultado de erro
  factory PreferencesResult.error({
    required String errorMessage,
    required PreferencesError errorType,
    List<String> appliedCorrections = const [],
    Duration? operationDuration,
    String? strategyUsed,
  }) {
    return PreferencesResult(
      success: false,
      errorMessage: errorMessage,
      errorType: errorType,
      appliedCorrections: appliedCorrections,
      operationDuration: operationDuration,
      strategyUsed: strategyUsed,
    );
  }

  /// Cria resultado de erro de validação
  factory PreferencesResult.validationError(String message) {
    return PreferencesResult.error(
      errorMessage: message,
      errorType: PreferencesError.validationError,
    );
  }

  /// Cria resultado de erro de sanitização
  factory PreferencesResult.sanitizationError(String message) {
    return PreferencesResult.error(
      errorMessage: message,
      errorType: PreferencesError.sanitizationError,
    );
  }

  /// Cria resultado de erro de persistência
  factory PreferencesResult.persistenceError(String message) {
    return PreferencesResult.error(
      errorMessage: message,
      errorType: PreferencesError.persistenceError,
    );
  }

  /// Cria resultado de erro de rede
  factory PreferencesResult.networkError(String message) {
    return PreferencesResult.error(
      errorMessage: message,
      errorType: PreferencesError.networkError,
    );
  }

  /// Cria resultado de erro desconhecido
  factory PreferencesResult.unknownError(String message) {
    return PreferencesResult.error(
      errorMessage: message,
      errorType: PreferencesError.unknownError,
    );
  }

  /// Verifica se houve correções aplicadas
  bool get hadCorrections => appliedCorrections.isNotEmpty;

  /// Verifica se é um erro recuperável
  bool get isRecoverable {
    if (success) return false;

    switch (errorType) {
      case PreferencesError.networkError:
      case PreferencesError.persistenceError:
        return true;
      case PreferencesError.validationError:
      case PreferencesError.sanitizationError:
      case PreferencesError.unknownError:
      case null:
        return false;
    }
  }

  /// Obtém mensagem amigável para o usuário
  String get userFriendlyMessage {
    if (success) {
      return 'Preferências salvas com sucesso!';
    }

    switch (errorType) {
      case PreferencesError.networkError:
        return 'Problema de conexão. Tente novamente.';
      case PreferencesError.persistenceError:
        return 'Erro ao salvar. Tente novamente em alguns instantes.';
      case PreferencesError.validationError:
        return 'Dados inválidos. Verifique as informações.';
      case PreferencesError.sanitizationError:
        return 'Erro interno. Nossa equipe foi notificada.';
      case PreferencesError.unknownError:
      case null:
        return 'Erro inesperado. Nossa equipe foi notificada.';
    }
  }

  /// Converte para Map para logs
  Map<String, dynamic> toLogData() {
    return {
      'success': success,
      'errorMessage': errorMessage,
      'errorType': errorType?.toString(),
      'hasData': data != null,
      'correctionsCount': appliedCorrections.length,
      'appliedCorrections': appliedCorrections,
      'operationDuration': operationDuration?.inMilliseconds,
      'strategyUsed': strategyUsed,
    };
  }

  @override
  String toString() {
    if (success) {
      return 'PreferencesResult.success('
          'data: $data, '
          'corrections: ${appliedCorrections.length}, '
          'duration: ${operationDuration?.inMilliseconds}ms, '
          'strategy: $strategyUsed'
          ')';
    } else {
      return 'PreferencesResult.error('
          'type: $errorType, '
          'message: $errorMessage, '
          'corrections: ${appliedCorrections.length}'
          ')';
    }
  }
}

/// Tipos de erro para preferências
enum PreferencesError {
  validationError, // Dados de entrada inválidos
  sanitizationError, // Falha na correção de dados
  persistenceError, // Falha na persistência
  networkError, // Problemas de conectividade
  unknownError, // Erros não categorizados
}

/// Extensão para PreferencesError
extension PreferencesErrorExtension on PreferencesError {
  /// Obtém descrição do erro
  String get description {
    switch (this) {
      case PreferencesError.validationError:
        return 'Dados de entrada inválidos';
      case PreferencesError.sanitizationError:
        return 'Falha na correção de dados';
      case PreferencesError.persistenceError:
        return 'Falha na persistência';
      case PreferencesError.networkError:
        return 'Problemas de conectividade';
      case PreferencesError.unknownError:
        return 'Erro não categorizado';
    }
  }

  /// Verifica se é erro crítico
  bool get isCritical {
    switch (this) {
      case PreferencesError.sanitizationError:
      case PreferencesError.unknownError:
        return true;
      case PreferencesError.validationError:
      case PreferencesError.persistenceError:
      case PreferencesError.networkError:
        return false;
    }
  }
}
