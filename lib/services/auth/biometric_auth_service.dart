import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../../models/auth/auth_method.dart';
import '../../models/auth/auth_config.dart';
import '../../models/auth/biometric_info.dart';
import '../../models/auth/auth_exception.dart';
import 'secure_storage_service.dart';

/// Serviço central para gerenciar autenticação biométrica e por senha
class BiometricAuthService {
  // Singleton
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _storage = SecureStorageService();

  bool _isAuthenticated = false;
  DateTime? _lastAuthTime;

  // ========== Detecção de Biometria ==========

  /// Verifica se o dispositivo suporta biometria
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Erro ao verificar suporte a biometria: $e');
      return false;
    }
  }

  /// Verifica se o dispositivo é suportado
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Erro ao verificar dispositivo: $e');
      return false;
    }
  }

  /// Obtém lista de biometrias disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Erro ao obter biometrias disponíveis: $e');
      return [];
    }
  }

  /// Obtém informações sobre biometria disponível
  Future<BiometricInfo> getBiometricInfo() async {
    final canCheck = await canCheckBiometrics();
    if (!canCheck) {
      return BiometricInfo(isAvailable: false, types: []);
    }

    final types = await getAvailableBiometrics();
    return BiometricInfo(
      isAvailable: types.isNotEmpty,
      types: types,
    );
  }

  // ========== Autenticação Biométrica ==========

  /// Autentica usando biometria
  Future<bool> authenticate({
    String reason = 'Autentique-se para acessar o aplicativo',
  }) async {
    try {
      final canCheck = await canCheckBiometrics();
      
      if (!canCheck) {
        throw AuthException.biometricNotAvailable();
      }

      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        throw AuthException.biometricNotEnrolled();
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticação Biométrica',
            cancelButton: 'Cancelar',
            biometricHint: 'Verificar identidade',
            biometricNotRecognized: 'Biometria não reconhecida',
            biometricSuccess: 'Sucesso',
            deviceCredentialsRequiredTitle: 'Credenciais necessárias',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
            goToSettingsButton: 'Configurações',
            goToSettingsDescription:
                'Configure a biometria nas configurações',
            lockOut: 'Reative a biometria',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
        _lastAuthTime = DateTime.now();
        await _storage.setLastAuthTime(_lastAuthTime!);
      }

      return authenticated;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException.systemError(e.toString());
    }
  }

  // ========== Configurações ==========

  /// Ativa proteção do app
  Future<void> enableAppLock({
    required AuthMethod method,
    String? password,
  }) async {
    // Se método requer senha, validar que foi fornecida
    if ((method == AuthMethod.password ||
            method == AuthMethod.biometricWithPasswordFallback) &&
        (password == null || password.isEmpty)) {
      throw AuthException(
        type: AuthErrorType.passwordNotSet,
        message: 'Senha é obrigatória para este método',
        canRetry: false,
      );
    }

    // Se método usa biometria, verificar disponibilidade
    if (method == AuthMethod.biometric ||
        method == AuthMethod.biometricWithPasswordFallback) {
      final info = await getBiometricInfo();
      if (!info.isAvailable) {
        throw AuthException.biometricNotAvailable();
      }
    }

    // Salvar configurações
    await _storage.setAppLockEnabled(true);
    await _storage.setAuthMethod(method);

    // Salvar senha se fornecida
    if (password != null && password.isNotEmpty) {
      await _storage.setPasswordHash(password);
    }
  }

  /// Desativa proteção do app
  Future<void> disableAppLock() async {
    await _storage.setAppLockEnabled(false);
    await _storage.setAuthMethod(AuthMethod.none);
    _isAuthenticated = false;
    _lastAuthTime = null;
  }

  /// Verifica se proteção está ativada
  Future<bool> isAppLockEnabled() async {
    return await _storage.getAppLockEnabled();
  }

  /// Obtém método de autenticação configurado
  Future<AuthMethod> getPreferredAuthMethod() async {
    return await _storage.getAuthMethod();
  }

  /// Obtém configuração completa
  Future<AuthConfig> getAuthConfig() async {
    final isEnabled = await isAppLockEnabled();
    final method = await getPreferredAuthMethod();
    final timeoutMinutes = await getTimeoutMinutes();
    final lastAuthTime = await _storage.getLastAuthTime();

    return AuthConfig(
      isEnabled: isEnabled,
      method: method,
      timeoutMinutes: timeoutMinutes,
      lastAuthTime: lastAuthTime,
    );
  }

  // ========== Senha ==========

  /// Define senha
  Future<void> setPassword(String password) async {
    if (password.length < 4) {
      throw AuthException(
        type: AuthErrorType.passwordIncorrect,
        message: 'Senha deve ter pelo menos 4 caracteres',
        canRetry: true,
      );
    }

    await _storage.setPasswordHash(password);
  }

  /// Verifica senha
  Future<bool> verifyPassword(String password) async {
    final isCorrect = await _storage.verifyPassword(password);

    if (isCorrect) {
      _isAuthenticated = true;
      _lastAuthTime = DateTime.now();
      await _storage.setLastAuthTime(_lastAuthTime!);
    }

    return isCorrect;
  }

  /// Limpa senha
  Future<void> clearPassword() async {
    await _storage.clearPassword();
  }

  /// Verifica se senha está configurada
  Future<bool> hasPassword() async {
    final hash = await _storage.getPasswordHash();
    return hash != null && hash.isNotEmpty;
  }

  // ========== Sessão ==========

  /// Verifica se sessão está válida
  bool isSessionValid() {
    if (!_isAuthenticated || _lastAuthTime == null) {
      return false;
    }

    // Verificar se não excedeu o timeout
    // (será implementado com o timeout configurável)
    return true;
  }

  /// Atualiza timestamp da última autenticação
  void updateLastAuthTime() {
    _lastAuthTime = DateTime.now();
    _storage.setLastAuthTime(_lastAuthTime!);
  }

  /// Obtém timeout em minutos
  Future<int> getTimeoutMinutes() async {
    return await _storage.getTimeoutMinutes();
  }

  /// Define timeout em minutos
  Future<void> setTimeoutMinutes(int minutes) async {
    await _storage.setTimeoutMinutes(minutes);
  }

  /// Verifica se precisa autenticar baseado no timeout
  Future<bool> needsAuthentication() async {
    final isEnabled = await isAppLockEnabled();
    if (!isEnabled) return false;

    if (!_isAuthenticated || _lastAuthTime == null) {
      return true;
    }

    final timeoutMinutes = await getTimeoutMinutes();
    final now = DateTime.now();
    final difference = now.difference(_lastAuthTime!);

    return difference.inMinutes >= timeoutMinutes;
  }

  /// Invalida sessão (logout)
  void invalidateSession() {
    _isAuthenticated = false;
    _lastAuthTime = null;
  }

  // ========== Preferência de Biometria Automática ==========

  /// Define se biometria deve ser chamada automaticamente
  Future<void> setAutoBiometricEnabled(bool enabled) async {
    await _storage.setAutoBiometricEnabled(enabled);
  }

  /// Verifica se biometria automática está habilitada
  Future<bool> getAutoBiometricEnabled() async {
    return await _storage.getAutoBiometricEnabled();
  }

  /// Limpa todas as configurações
  Future<void> clearAll() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    _lastAuthTime = null;
  }
}
