import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para dados de usuário em cache
class UserDataCache {
  final String userId;
  final String name;
  final String username;
  final String email;
  final DateTime cachedAt;
  final bool isValid;
  final Map<String, dynamic> fullData;
  
  UserDataCache({
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    required this.cachedAt,
    required this.isValid,
    required this.fullData,
  });
  
  /// Cria instância a partir de dados do Firebase
  factory UserDataCache.fromFirestore(String userId, Map<String, dynamic> data) {
    return UserDataCache(
      userId: userId,
      name: data['nome'] as String? ?? data['name'] as String? ?? 'Usuário',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      cachedAt: DateTime.now(),
      isValid: true,
      fullData: Map<String, dynamic>.from(data),
    );
  }
  
  /// Verifica se o cache ainda é válido (5 minutos)
  bool get isCacheValid {
    final now = DateTime.now();
    final difference = now.difference(cachedAt);
    return difference.inMinutes < 5 && isValid;
  }
}

/// Sistema de cache para dados de usuário
class UserDataCacheSystem {
  static final Map<String, UserDataCache> _cache = {};
  
  /// Duração do cache em minutos
  static const int CACHE_DURATION_MINUTES = 5;
  
  /// Busca dados do usuário com cache
  static Future<UserDataCache?> getUserData(String userId) async {
    print('📦 [CACHE] Buscando dados para userId: $userId');
    
    // Verificar cache primeiro
    if (_cache.containsKey(userId)) {
      final cached = _cache[userId]!;
      if (cached.isCacheValid) {
        print('📦 [CACHE] Dados encontrados no cache: ${cached.name}');
        return cached;
      } else {
        print('📦 [CACHE] Cache expirado, removendo...');
        _cache.remove(userId);
      }
    }
    
    // Buscar no Firebase
    try {
      print('📦 [CACHE] Buscando no Firebase...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = UserDataCache.fromFirestore(userId, userDoc.data()!);
        
        // Salvar no cache
        _cache[userId] = userData;
        
        print('📦 [CACHE] Dados salvos no cache: ${userData.name}');
        return userData;
      } else {
        print('📦 [CACHE] Usuário não encontrado no Firebase');
        return null;
      }
    } catch (e) {
      print('❌ [CACHE] Erro ao buscar usuário: $e');
      return null;
    }
  }
  
  /// Busca apenas o nome do usuário
  static Future<String> getUserName(String userId) async {
    final userData = await getUserData(userId);
    return userData?.name ?? 'Usuário não encontrado';
  }
  
  /// Pré-carrega dados de múltiplos usuários
  static Future<void> preloadUsers(List<String> userIds) async {
    print('📦 [CACHE] Pré-carregando ${userIds.length} usuários...');
    
    final futures = userIds.map((userId) => getUserData(userId));
    await Future.wait(futures);
    
    print('📦 [CACHE] Pré-carregamento concluído');
  }
  
  /// Invalida cache de um usuário específico
  static void invalidateUser(String userId) {
    if (_cache.containsKey(userId)) {
      _cache.remove(userId);
      print('📦 [CACHE] Cache invalidado para userId: $userId');
    }
  }
  
  /// Limpa todo o cache
  static void clearCache() {
    final count = _cache.length;
    _cache.clear();
    print('📦 [CACHE] Cache limpo ($count entradas removidas)');
  }
  
  /// Limpa cache expirado
  static void cleanExpiredCache() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    _cache.forEach((userId, userData) {
      if (!userData.isCacheValid) {
        toRemove.add(userId);
      }
    });
    
    for (final userId in toRemove) {
      _cache.remove(userId);
    }
    
    if (toRemove.isNotEmpty) {
      print('📦 [CACHE] Cache expirado limpo (${toRemove.length} entradas)');
    }
  }
  
  /// Retorna estatísticas do cache
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    _cache.forEach((userId, userData) {
      if (userData.isCacheValid) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    });
    
    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'cacheHitRate': validEntries / (_cache.length > 0 ? _cache.length : 1),
    };
  }
  
  /// Força atualização de um usuário
  static Future<UserDataCache?> forceRefreshUser(String userId) async {
    print('📦 [CACHE] Forçando atualização para userId: $userId');
    
    // Remover do cache
    _cache.remove(userId);
    
    // Buscar novamente
    return await getUserData(userId);
  }
  
  /// Verifica se um usuário está no cache
  static bool isUserCached(String userId) {
    return _cache.containsKey(userId) && _cache[userId]!.isCacheValid;
  }
  
  /// Retorna todos os usuários em cache
  static List<UserDataCache> getAllCachedUsers() {
    return _cache.values.where((user) => user.isCacheValid).toList();
  }
}