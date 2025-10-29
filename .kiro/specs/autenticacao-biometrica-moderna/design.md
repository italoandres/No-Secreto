# Design Document

## Overview

Este documento descreve o design técnico para implementar um sistema moderno de autenticação biométrica no aplicativo. O sistema priorizará métodos de autenticação nativos do dispositivo (impressão digital, reconhecimento facial, íris) com fallback para senha numérica, proporcionando uma experiência de segurança moderna e conveniente.

## Architecture

### Componentes Principais

1. **BiometricAuthService** - Serviço central que gerencia toda a lógica de autenticação
2. **AppLockScreen** - Tela de bloqueio que solicita autenticação
3. **SecuritySettingsWidget** - Widget de configurações de segurança (já existe parcialmente)
4. **AppLifecycleObserver** - Observer que detecta quando o app vai para background/foreground
5. **SecureStorageService** - Serviço para armazenamento seguro de configurações

### Fluxo de Autenticação

```
App Inicia
    ↓
Verificar se proteção está ativada
    ↓
    ├─ Não → Permitir acesso
    ↓
    └─ Sim → Verificar métodos disponíveis
        ↓
        ├─ Biometria disponível → Solicitar biometria
        │   ↓
        │   ├─ Sucesso → Permitir acesso
        │   ↓
        │   └─ Falha (3x) → Fallback para senha
        ↓
        └─ Apenas senha → Solicitar senha
            ↓
            ├─ Sucesso → Permitir acesso
            ↓
            └─ Falha → Tentar novamente
```

## Components and Interfaces

### 1. BiometricAuthService

```dart
class BiometricAuthService {
  // Singleton
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  
  // Propriedades
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticated = false;
  DateTime? _lastAuthTime;
  
  // Métodos principais
  Future<bool> canCheckBiometrics();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticate({String reason});
  Future<bool> isDeviceSupported();
  
  // Configurações
  Future<void> enableAppLock({bool useBiometric});
  Future<void> disableAppLock();
  Future<bool> isAppLockEnabled();
  Future<AuthMethod> getPreferredAuthMethod();
  
  // Senha
  Future<void> setPassword(String password);
  Future<bool> verifyPassword(String password);
  Future<void> clearPassword();
  
  // Sessão
  bool isSessionValid();
  void updateLastAuthTime();
  int getTimeoutMinutes();
  Future<void> setTimeoutMinutes(int minutes);
}

enum AuthMethod {
  none,
  biometric,
  password,
  biometricWithPasswordFallback
}

enum BiometricType {
  face,
  fingerprint,
  iris,
  weak,
  strong
}
```

### 2. AppLockScreen

```dart
class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool canUseBiometric;
  final AuthMethod authMethod;
  
  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _showPasswordInput = false;
  int _failedAttempts = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.canUseBiometric) {
      _authenticateWithBiometric();
    }
  }
  
  Future<void> _authenticateWithBiometric();
  Future<void> _authenticateWithPassword(String password);
  void _switchToPasswordFallback();
  Widget _buildBiometricUI();
  Widget _buildPasswordUI();
}
```

### 3. SecuritySettingsWidget (Atualizado)

```dart
class SecuritySettingsWidget extends StatefulWidget {
  @override
  State<SecuritySettingsWidget> createState() => _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState extends State<SecuritySettingsWidget> {
  bool _isEnabled = false;
  AuthMethod _authMethod = AuthMethod.none;
  List<BiometricType> _availableBiometrics = [];
  int _timeoutMinutes = 2;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricAvailability();
  }
  
  Future<void> _loadSettings();
  Future<void> _checkBiometricAvailability();
  Widget _buildAuthMethodSelector();
  Widget _buildBiometricInfo();
  Widget _buildTimeoutSelector();
  Widget _buildPasswordSetup();
}
```

### 4. SecureStorageService

```dart
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Keys
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyAuthMethod = 'auth_method';
  static const String _keyPasswordHash = 'password_hash';
  static const String _keyTimeoutMinutes = 'timeout_minutes';
  
  // Métodos
  Future<void> setAppLockEnabled(bool enabled);
  Future<bool> getAppLockEnabled();
  
  Future<void> setAuthMethod(AuthMethod method);
  Future<AuthMethod> getAuthMethod();
  
  Future<void> setPasswordHash(String hash);
  Future<String?> getPasswordHash();
  
  Future<void> setTimeoutMinutes(int minutes);
  Future<int> getTimeoutMinutes();
  
  Future<void> clearAll();
}
```

### 5. AppLifecycleObserver

```dart
class AppLifecycleObserver extends WidgetsBindingObserver {
  final BiometricAuthService _authService = BiometricAuthService();
  DateTime? _backgroundTime;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _backgroundTime = DateTime.now();
        break;
        
      case AppLifecycleState.resumed:
        _checkIfAuthNeeded();
        break;
        
      default:
        break;
    }
  }
  
  void _checkIfAuthNeeded() {
    if (_backgroundTime != null) {
      final duration = DateTime.now().difference(_backgroundTime!);
      final timeoutMinutes = _authService.getTimeoutMinutes();
      
      if (duration.inMinutes >= timeoutMinutes) {
        // Mostrar tela de autenticação
        _showAuthScreen();
      }
    }
  }
  
  void _showAuthScreen();
}
```

## Data Models

### AuthConfig

```dart
class AuthConfig {
  final bool isEnabled;
  final AuthMethod method;
  final int timeoutMinutes;
  final DateTime? lastAuthTime;
  
  AuthConfig({
    required this.isEnabled,
    required this.method,
    this.timeoutMinutes = 2,
    this.lastAuthTime,
  });
  
  Map<String, dynamic> toJson();
  factory AuthConfig.fromJson(Map<String, dynamic> json);
}
```

### BiometricInfo

```dart
class BiometricInfo {
  final bool isAvailable;
  final List<BiometricType> types;
  final String displayName;
  final IconData icon;
  
  BiometricInfo({
    required this.isAvailable,
    required this.types,
    required this.displayName,
    required this.icon,
  });
  
  String get description {
    if (!isAvailable) return 'Biometria não disponível';
    if (types.contains(BiometricType.face)) return 'Reconhecimento Facial';
    if (types.contains(BiometricType.fingerprint)) return 'Impressão Digital';
    if (types.contains(BiometricType.iris)) return 'Reconhecimento de Íris';
    return 'Biometria';
  }
  
  IconData get iconData {
    if (types.contains(BiometricType.face)) return Icons.face;
    if (types.contains(BiometricType.fingerprint)) return Icons.fingerprint;
    if (types.contains(BiometricType.iris)) return Icons.remove_red_eye;
    return Icons.security;
  }
}
```

## Error Handling

### Tipos de Erros

1. **BiometricNotAvailable** - Dispositivo não suporta biometria
2. **BiometricNotEnrolled** - Usuário não configurou biometria no dispositivo
3. **AuthenticationFailed** - Falha na autenticação (biométrica ou senha)
4. **TooManyAttempts** - Muitas tentativas falhadas
5. **SystemError** - Erro do sistema operacional

### Estratégias de Tratamento

```dart
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
}

enum AuthErrorType {
  biometricNotAvailable,
  biometricNotEnrolled,
  authenticationFailed,
  tooManyAttempts,
  systemError,
  passwordIncorrect,
}
```

### Fluxo de Tratamento de Erros

```
Erro de Autenticação
    ↓
Identificar tipo de erro
    ↓
    ├─ BiometricNotAvailable → Usar apenas senha
    ├─ BiometricNotEnrolled → Mostrar mensagem + usar senha
    ├─ AuthenticationFailed → Permitir retry (até 3x)
    ├─ TooManyAttempts → Fallback para senha
    ├─ PasswordIncorrect → Permitir retry + opção de recuperação
    └─ SystemError → Fallback para senha + log do erro
```

## Testing Strategy

### Unit Tests

1. **BiometricAuthService**
   - Testar detecção de biometria disponível
   - Testar autenticação com sucesso
   - Testar autenticação com falha
   - Testar fallback para senha
   - Testar validação de sessão

2. **SecureStorageService**
   - Testar armazenamento e recuperação de configurações
   - Testar hash de senha
   - Testar limpeza de dados

3. **Password Hashing**
   - Testar geração de hash
   - Testar verificação de senha
   - Testar que senhas diferentes geram hashes diferentes

### Integration Tests

1. **Fluxo Completo de Configuração**
   - Ativar proteção com biometria
   - Ativar proteção com senha
   - Desativar proteção
   - Alterar método de autenticação

2. **Fluxo de Autenticação**
   - Abrir app e autenticar com biometria
   - Abrir app e autenticar com senha
   - Falhar biometria e usar fallback
   - Timeout de sessão

3. **Lifecycle**
   - App vai para background e volta antes do timeout
   - App vai para background e volta após timeout
   - App é fechado e reaberto

### Widget Tests

1. **AppLockScreen**
   - Renderização com biometria
   - Renderização com senha
   - Transição de biometria para senha (fallback)
   - Feedback visual de erro

2. **SecuritySettingsWidget**
   - Exibição de métodos disponíveis
   - Toggle de ativação/desativação
   - Seleção de método de autenticação
   - Configuração de timeout

## Security Considerations

### Armazenamento Seguro

- Usar `flutter_secure_storage` para todas as configurações sensíveis
- Nunca armazenar senhas em texto plano
- Usar bcrypt ou argon2 para hash de senhas
- Limpar dados ao fazer logout

### Proteção contra Ataques

- Limitar tentativas de autenticação (3 tentativas antes de fallback)
- Implementar delay progressivo após falhas (1s, 2s, 5s)
- Registrar tentativas falhadas para auditoria
- Não revelar se o erro foi na biometria ou na senha

### Privacidade

- Não enviar dados biométricos para servidor
- Toda autenticação biométrica é local
- Configurações de segurança são locais ao dispositivo
- Opção de desativar completamente a proteção

## Dependencies

```yaml
dependencies:
  local_auth: ^2.1.7  # Autenticação biométrica
  flutter_secure_storage: ^9.0.0  # Armazenamento seguro
  crypto: ^3.0.3  # Para hashing
  bcrypt: ^1.1.3  # Para hash de senha seguro
```

## UI/UX Design

### Tela de Bloqueio (AppLockScreen)

```
┌─────────────────────────────┐
│                             │
│         [Logo App]          │
│                             │
│    🔒 App Protegido         │
│                             │
│    [Ícone Biometria]        │
│                             │
│  "Toque para autenticar"    │
│   "com impressão digital"   │
│                             │
│  [Botão: Usar Senha]        │
│                             │
└─────────────────────────────┘
```

### Configurações de Segurança

```
┌─────────────────────────────┐
│ 🔐 Segurança                │
├─────────────────────────────┤
│                             │
│ Proteção do App      [ON]   │
│ App protegido com            │
│ impressão digital            │
│                             │
├─────────────────────────────┤
│                             │
│ Método de Autenticação      │
│ ○ Biometria + Senha         │
│ ○ Apenas Senha              │
│                             │
├─────────────────────────────┤
│                             │
│ Timeout de Sessão           │
│ Solicitar autenticação após │
│ [2 minutos ▼]               │
│                             │
├─────────────────────────────┤
│                             │
│ [Alterar Senha]             │
│                             │
└─────────────────────────────┘
```

## Implementation Notes

### Priorização de Métodos

1. Verificar se dispositivo suporta biometria
2. Se sim, usar biometria como método principal
3. Sempre configurar senha como fallback
4. Permitir usuário escolher "apenas senha" se preferir

### Compatibilidade

- Android: Suporta impressão digital, face, íris
- iOS: Suporta Touch ID e Face ID
- Fallback universal: Senha numérica de 4-8 dígitos

### Performance

- Autenticação biométrica deve ser instantânea
- Não bloquear UI durante verificação
- Cache de sessão para evitar autenticações repetidas
- Timeout configurável (padrão: 2 minutos)
