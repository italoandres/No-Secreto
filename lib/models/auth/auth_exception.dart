/// Tipos de erros de autenticação
enum AuthErrorType {
  biometricNotAvailable,
  biometricNotEnrolled,
  authenticationFailed,
  tooManyAttempts,
  systemError,
  passwordIncorrect,
  passwordNotSet,
}

/// Exceção personalizada para erros de autenticação
class AuthException implements Exception {
  final AuthErrorType type;
  final String message;
  final bool canRetry;
  final bool shouldFallback;

  AuthException({
    required this.type,
    required this.message,
    this.canRetry = true,
    this.shouldFallback = false,
  });

  @override
  String toString() => message;

  factory AuthException.biometricNotAvailable() {
    return AuthException(
      type: AuthErrorType.biometricNotAvailable,
      message: 'Biometria não está disponível neste dispositivo',
      canRetry: false,
      shouldFallback: true,
    );
  }

  factory AuthException.biometricNotEnrolled() {
    return AuthException(
      type: AuthErrorType.biometricNotEnrolled,
      message: 'Configure a biometria nas configurações do dispositivo',
      canRetry: false,
      shouldFallback: true,
    );
  }

  factory AuthException.authenticationFailed() {
    return AuthException(
      type: AuthErrorType.authenticationFailed,
      message: 'Autenticação falhou. Tente novamente.',
      canRetry: true,
      shouldFallback: false,
    );
  }

  factory AuthException.tooManyAttempts() {
    return AuthException(
      type: AuthErrorType.tooManyAttempts,
      message: 'Muitas tentativas falhadas. Use a senha.',
      canRetry: false,
      shouldFallback: true,
    );
  }

  factory AuthException.systemError(String details) {
    return AuthException(
      type: AuthErrorType.systemError,
      message: 'Erro do sistema: $details',
      canRetry: true,
      shouldFallback: true,
    );
  }

  factory AuthException.passwordIncorrect() {
    return AuthException(
      type: AuthErrorType.passwordIncorrect,
      message: 'Senha incorreta',
      canRetry: true,
      shouldFallback: false,
    );
  }

  factory AuthException.passwordNotSet() {
    return AuthException(
      type: AuthErrorType.passwordNotSet,
      message: 'Senha não configurada',
      canRetry: false,
      shouldFallback: false,
    );
  }
}
