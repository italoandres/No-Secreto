import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Serviço de cache para perfis de usuário
///
/// Cache em memória + SharedPreferences
/// Reduz queries ao Firestore significativamente
class UserProfileCacheService {
  // Cache em memória (mais rápido)
  static final Map<String, UsuarioModel> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Tempo de expiração do cache (15 minutos)
  static const Duration _cacheExpiration = Duration(minutes: 15);

  // Prefixo para SharedPreferences
  static const String _keyPrefix = 'user_profile_cache_';

  // ============================================================================
  // CACHE EM MEMÓRIA (RÁPIDO)
  // ============================================================================

  /// Obter perfil do cache em memória
  static UsuarioModel? getFromMemory(String userId) {
    // Verificar se existe e não expirou
    if (_memoryCache.containsKey(userId)) {
      final timestamp = _cacheTimestamps[userId];
      if (timestamp != null && !_isExpired(timestamp)) {
        safePrint('✅ CACHE HIT (memória): $userId');
        return _memoryCache[userId];
      } else {
        // Expirou - remover
        safePrint('⏰ CACHE EXPIRED (memória): $userId');
        _memoryCache.remove(userId);
        _cacheTimestamps.remove(userId);
      }
    }

    safePrint('❌ CACHE MISS (memória): $userId');
    return null;
  }

  /// Salvar perfil no cache em memória
  static void saveToMemory(UsuarioModel user) {
    if (user.id != null) {
      _memoryCache[user.id!] = user;
      _cacheTimestamps[user.id!] = DateTime.now();
      safePrint('💾 CACHE SAVED (memória): ${user.id}');
    }
  }

  /// Limpar cache em memória
  static void clearMemory() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    safePrint('🗑️ CACHE CLEARED (memória)');
  }

  // ============================================================================
  // CACHE PERSISTENTE (SharedPreferences)
  // ============================================================================

  /// Obter perfil do cache persistente
  static Future<UsuarioModel?> getFromPersistent(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';

      final jsonString = prefs.getString(key);
      if (jsonString == null) {
        safePrint('❌ CACHE MISS (persistente): $userId');
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Verificar timestamp
      final timestamp = DateTime.parse(json['_cache_timestamp'] as String);
      if (_isExpired(timestamp)) {
        safePrint('⏰ CACHE EXPIRED (persistente): $userId');
        await prefs.remove(key);
        return null;
      }

      // Remover campo auxiliar antes de criar o modelo
      json.remove('_cache_timestamp');

      final user = UsuarioModel.fromJson(json);
      user.id = userId;

      safePrint('✅ CACHE HIT (persistente): $userId');

      // Colocar também na memória
      saveToMemory(user);

      return user;
    } catch (e) {
      safePrint('❌ Erro ao ler cache persistente: $e');
      return null;
    }
  }

  /// Salvar perfil no cache persistente
  static Future<void> saveToPersistent(UsuarioModel user) async {
    if (user.id == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix${user.id}';

      final json = user.toJson();
      json['_cache_timestamp'] = DateTime.now().toIso8601String();

      final jsonString = jsonEncode(json);
      await prefs.setString(key, jsonString);

      safePrint('💾 CACHE SAVED (persistente): ${user.id}');

      // Salvar também na memória
      saveToMemory(user);
    } catch (e) {
      safePrint('❌ Erro ao salvar cache persistente: $e');
    }
  }

  /// Limpar cache persistente
  static Future<void> clearPersistent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int removed = 0;
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
          removed++;
        }
      }

      safePrint('🗑️ CACHE CLEARED (persistente): $removed perfis');
    } catch (e) {
      safePrint('❌ Erro ao limpar cache persistente: $e');
    }
  }

  /// Remover perfil específico do cache
  static Future<void> remove(String userId) async {
    // Memória
    _memoryCache.remove(userId);
    _cacheTimestamps.remove(userId);

    // Persistente
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$userId');
      safePrint('🗑️ CACHE REMOVED: $userId');
    } catch (e) {
      safePrint('❌ Erro ao remover do cache: $e');
    }
  }

  // ============================================================================
  // MÉTODOS UNIFICADOS (USA MEMÓRIA PRIMEIRO, DEPOIS PERSISTENTE)
  // ============================================================================

  /// Obter perfil do cache (tenta memória primeiro, depois persistente)
  static Future<UsuarioModel?> get(String userId) async {
    // 1. Tentar memória (mais rápido)
    final fromMemory = getFromMemory(userId);
    if (fromMemory != null) {
      return fromMemory;
    }

    // 2. Tentar persistente
    final fromPersistent = await getFromPersistent(userId);
    return fromPersistent;
  }

  /// Salvar perfil no cache (memória + persistente)
  static Future<void> save(UsuarioModel user) async {
    saveToMemory(user);
    await saveToPersistent(user);
  }

  /// Limpar todo o cache
  static Future<void> clearAllCache() async {
    clearMemory();
    await clearPersistent();
  }

  // ============================================================================
  // MÉTODOS DE COMPATIBILIDADE (para UsuarioRepository)
  // ============================================================================

  /// Alias para get() - compatibilidade com UsuarioRepository
  Future<UsuarioModel?> getUser(String userId) async {
    return await UserProfileCacheService.get(userId);
  }

  /// Alias para save() - compatibilidade com UsuarioRepository
  Future<void> saveUser(UsuarioModel user) async {
    await UserProfileCacheService.save(user);
  }

  /// Alias para remove() - compatibilidade com UsuarioRepository
  Future<void> invalidateUser(String userId) async {
    await UserProfileCacheService.remove(userId);
  }

  /// Alias para clearAllCache() - compatibilidade com UsuarioRepository
  Future<void> clearAll() async {
    await UserProfileCacheService.clearAllCache();
  }

  /// Alias para getCacheStatistics() - compatibilidade com UsuarioRepository
  Future<Map<String, dynamic>> getStats() async {
    return await UserProfileCacheService.getCacheStatistics();
  }

  // ============================================================================
  // UTILITÁRIOS
  // ============================================================================

  /// Verificar se o timestamp expirou
  static bool _isExpired(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference > _cacheExpiration;
  }

  /// Obter estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(_keyPrefix)).length;

    return {
      'memoryCache': _memoryCache.length,
      'persistentCache': cacheKeys,
      'totalCache': _memoryCache.length + cacheKeys,
      'expirationMinutes': _cacheExpiration.inMinutes,
    };
  }

  /// Limpar cache expirado
  static Future<void> cleanExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int removed = 0;
      for (final key in keys) {
        if (!key.startsWith(_keyPrefix)) continue;

        final jsonString = prefs.getString(key);
        if (jsonString == null) continue;

        try {
          final json = jsonDecode(jsonString);
          final timestamp = DateTime.parse(json['_cache_timestamp'] as String);

          if (_isExpired(timestamp)) {
            await prefs.remove(key);
            removed++;
          }
        } catch (e) {
          // Se erro ao ler, remove o cache corrompido
          await prefs.remove(key);
          removed++;
        }
      }

      safePrint('🧹 CACHE CLEANUP: $removed perfis expirados removidos');
    } catch (e) {
      safePrint('❌ Erro ao limpar cache expirado: $e');
    }
  }
}