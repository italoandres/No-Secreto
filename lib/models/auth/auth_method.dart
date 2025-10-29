/// Métodos de autenticação disponíveis
enum AuthMethod {
  /// Sem proteção
  none,

  /// Apenas biometria (sem fallback)
  biometric,

  /// Apenas senha
  password,

  /// Biometria com fallback para senha
  biometricWithPasswordFallback,
}

extension AuthMethodExtension on AuthMethod {
  String get displayName {
    switch (this) {
      case AuthMethod.none:
        return 'Sem Proteção';
      case AuthMethod.biometric:
        return 'Biometria';
      case AuthMethod.password:
        return 'Senha';
      case AuthMethod.biometricWithPasswordFallback:
        return 'Biometria + Senha';
    }
  }

  String get description {
    switch (this) {
      case AuthMethod.none:
        return 'App sem proteção';
      case AuthMethod.biometric:
        return 'Protegido com biometria';
      case AuthMethod.password:
        return 'Protegido com senha';
      case AuthMethod.biometricWithPasswordFallback:
        return 'Protegido com biometria e senha como fallback';
    }
  }
}
