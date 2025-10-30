import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../models/auth/auth_method.dart';

/// Serviço para armazenamento seguro de configurações de autenticação
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyAuthMethod = 'auth_method';
  static const String _keyPasswordHash = 'password_hash';
  static const String _keyTimeoutMinutes = 'timeout_minutes';
  static const String _keyLastAuthTime = 'last_auth_time';
  static const String _keyAutoBiometricEnabled = 'auto_biometric_enabled';

  // App Lock Enabled
  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _keyAppLockEnabled, value: enabled.toString());
  }

  Future<bool> getAppLockEnabled() async {
    final value = await _storage.read(key: _keyAppLockEnabled);
    return value == 'true';
  }

  // Auth Method
  Future<void> setAuthMethod(AuthMethod method) async {
    await _storage.write(key: _keyAuthMethod, value: method.name);
  }

  Future<AuthMethod> getAuthMethod() async {
    final value = await _storage.read(key: _keyAuthMethod);
    if (value == null) return AuthMethod.none;

    try {
      return AuthMethod.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return AuthMethod.none;
    }
  }

  // Password Hash
  Future<void> setPasswordHash(String password) async {
    // Gerar hash seguro com bcrypt
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    await _storage.write(key: _keyPasswordHash, value: hash);
  }

  Future<String?> getPasswordHash() async {
    return await _storage.read(key: _keyPasswordHash);
  }

  Future<bool> verifyPassword(String password) async {
    final hash = await getPasswordHash();
    if (hash == null) return false;

    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      print('Erro ao verificar senha: $e');
      return false;
    }
  }

  // Timeout Minutes
  Future<void> setTimeoutMinutes(int minutes) async {
    await _storage.write(key: _keyTimeoutMinutes, value: minutes.toString());
  }

  Future<int> getTimeoutMinutes() async {
    final value = await _storage.read(key: _keyTimeoutMinutes);
    return value != null ? int.tryParse(value) ?? 2 : 2;
  }

  // Last Auth Time
  Future<void> setLastAuthTime(DateTime time) async {
    await _storage.write(
        key: _keyLastAuthTime, value: time.millisecondsSinceEpoch.toString());
  }

  Future<DateTime?> getLastAuthTime() async {
    final value = await _storage.read(key: _keyLastAuthTime);
    if (value == null) return null;

    final timestamp = int.tryParse(value);
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Auto Biometric Enabled (preferência do usuário)
  Future<void> setAutoBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyAutoBiometricEnabled, value: enabled.toString());
  }

  Future<bool> getAutoBiometricEnabled() async {
    final value = await _storage.read(key: _keyAutoBiometricEnabled);
    // Por padrão, retorna false (usuário precisa optar por biometria automática)
    return value == 'true';
  }

  // Clear All
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear apenas senha (manter outras configurações)
  Future<void> clearPassword() async {
    await _storage.delete(key: _keyPasswordHash);
  }
}
