import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para busca unificada em todas as coleções de perfis
class UnifiedProfileSearch {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca unificada em todas as coleções de perfis
  static Future<List<SpiritualProfileModel>> searchAllProfiles({
    String? query,
    int limit = 30,
  }) async {
    final startTime = DateTime.now();
    
    try {
      EnhancedLogger.info('Starting unified profile search', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {'query': query, 'limit': limit}
      );

      List<SpiritualProfileModel> allProfiles = [];

      // 1. Buscar na coleção spiritual_profiles
      final spiritualProfiles = await _searchSpiritualProfiles(query, limit);
      allProfiles.addAll(spiritualProfiles);
      
      EnhancedLogger.info('Spiritual profiles found', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {'count': spiritualProfiles.length}
      );

      // 2. Buscar na coleção usuarios (perfis de vitrine)
      final userProfiles = await _searchUserProfiles(query, limit);
      allProfiles.addAll(userProfiles);
      
      EnhancedLogger.info('User profiles found', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {'count': userProfiles.length}
      );

      // 3. Remover duplicatas (caso um usuário tenha perfil em ambas as coleções)
      final uniqueProfiles = _removeDuplicates(allProfiles);
      
      // 4. Aplicar filtro de busca textual se necessário
      final filteredProfiles = _applyTextFilter(uniqueProfiles, query);
      
      // 5. Limitar resultados
      final finalResults = filteredProfiles.take(limit).toList();

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      EnhancedLogger.success('Unified search completed', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {
          'totalFound': allProfiles.length,
          'afterDeduplication': uniqueProfiles.length,
          'afterTextFilter': filteredProfiles.length,
          'finalResults': finalResults.length,
          'executionTime': executionTime,
        }
      );

      return finalResults;

    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      EnhancedLogger.error('Unified search failed', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        error: e,
        data: {'executionTime': executionTime}
      );
      
      return [];
    }
  }

  /// Busca na coleção spiritual_profiles
  static Future<List<SpiritualProfileModel>> _searchSpiritualProfiles(
    String? query, 
    int limit,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit * 2)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return SpiritualProfileModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            } catch (e) {
              EnhancedLogger.warning('Failed to parse spiritual profile', 
                tag: 'UNIFIED_PROFILE_SEARCH',
                data: {'docId': doc.id, 'error': e.toString()}
              );
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();

    } catch (e) {
      EnhancedLogger.error('Failed to search spiritual profiles', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        error: e
      );
      return [];
    }
  }

  /// Busca na coleção usuarios (perfis de vitrine)
  static Future<List<SpiritualProfileModel>> _searchUserProfiles(
    String? query, 
    int limit,
  ) async {
    try {
      // Buscar usuários ativos sem filtros complexos para evitar erro de índice
      final snapshot = await _firestore
          .collection('usuarios')
          .limit(limit * 3) // Buscar mais para filtrar depois
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              final userData = doc.data() as Map<String, dynamic>;
              
              // Converter UsuarioModel para SpiritualProfileModel
              return _convertUserToSpiritualProfile(doc.id, userData);
            } catch (e) {
              EnhancedLogger.warning('Failed to parse user profile', 
                tag: 'UNIFIED_PROFILE_SEARCH',
                data: {'docId': doc.id, 'error': e.toString()}
              );
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();

    } catch (e) {
      EnhancedLogger.error('Failed to search user profiles', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        error: e
      );
      return [];
    }
  }

  /// Converte dados de usuário para SpiritualProfileModel
  static SpiritualProfileModel _convertUserToSpiritualProfile(
    String docId, 
    Map<String, dynamic> userData,
  ) {
    return SpiritualProfileModel(
      id: docId,
      userId: docId,
      displayName: userData['nome'] as String? ?? 'Usuário',
      age: _calculateAge(userData['nascimento']),
      bio: userData['bio'] as String? ?? '',
      city: userData['cidade'] as String? ?? '',
      state: userData['estado'] as String? ?? '',
      photoUrl: userData['foto'] as String?,
      interests: _extractInterests(userData),
      isActive: userData['isActive'] as bool? ?? true,
      isVerified: userData['isVerified'] as bool? ?? false,
      hasCompletedCourse: userData['hasCompletedSinaisCourse'] as bool? ?? false,
      createdAt: _parseTimestamp(userData['createdAt']),
      updatedAt: _parseTimestamp(userData['updatedAt']),
      // Marcar como perfil de vitrine
      profileType: 'vitrine',
      searchKeywords: _generateSearchKeywords(userData),
    );
  }

  /// Calcula idade a partir da data de nascimento
  static int? _calculateAge(dynamic nascimento) {
    try {
      if (nascimento == null) return null;
      
      DateTime birthDate;
      if (nascimento is Timestamp) {
        birthDate = nascimento.toDate();
      } else if (nascimento is String) {
        birthDate = DateTime.parse(nascimento);
      } else {
        return null;
      }
      
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age > 0 ? age : null;
    } catch (e) {
      return null;
    }
  }

  /// Extrai interesses dos dados do usuário
  static List<String> _extractInterests(Map<String, dynamic> userData) {
    final interests = <String>[];
    
    // Adicionar informações relevantes como "interesses"
    if (userData['cidade'] != null) {
      interests.add(userData['cidade'] as String);
    }
    if (userData['estado'] != null) {
      interests.add(userData['estado'] as String);
    }
    
    return interests;
  }

  /// Gera keywords de busca para o perfil
  static List<String> _generateSearchKeywords(Map<String, dynamic> userData) {
    final keywords = <String>[];
    
    final nome = userData['nome'] as String? ?? '';
    final username = userData['username'] as String? ?? '';
    final cidade = userData['cidade'] as String? ?? '';
    final estado = userData['estado'] as String? ?? '';
    
    // Adicionar nome completo e partes
    if (nome.isNotEmpty) {
      keywords.add(nome.toLowerCase());
      keywords.addAll(nome.toLowerCase().split(' '));
    }
    
    // Adicionar username
    if (username.isNotEmpty) {
      keywords.add(username.toLowerCase());
    }
    
    // Adicionar localização
    if (cidade.isNotEmpty) {
      keywords.add(cidade.toLowerCase());
    }
    if (estado.isNotEmpty) {
      keywords.add(estado.toLowerCase());
    }
    
    return keywords.toSet().toList(); // Remove duplicatas
  }

  /// Parse timestamp do Firebase
  static DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) return DateTime.parse(timestamp);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove perfis duplicados (mesmo userId)
  static List<SpiritualProfileModel> _removeDuplicates(
    List<SpiritualProfileModel> profiles,
  ) {
    final seen = <String>{};
    final unique = <SpiritualProfileModel>[];
    
    for (final profile in profiles) {
      final key = profile.userId ?? profile.id ?? '';
      if (key.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        unique.add(profile);
      }
    }
    
    return unique;
  }

  /// Aplica filtro de texto nos perfis
  static List<SpiritualProfileModel> _applyTextFilter(
    List<SpiritualProfileModel> profiles,
    String? query,
  ) {
    if (query == null || query.isEmpty) {
      return profiles;
    }
    
    final queryLower = query.toLowerCase();
    
    // Debug: Log detalhado para query "itala"
    if (queryLower.contains('itala')) {
      EnhancedLogger.info('DEBUG: Filtering profiles for "itala"', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {'totalProfiles': profiles.length, 'query': queryLower}
      );
    }
    
    final filtered = profiles.where((profile) {
      final searchableText = [
        profile.displayName ?? '',
        profile.bio ?? '',
        profile.city ?? '',
        profile.state ?? '',
        ...(profile.interests ?? []),
        ...(profile.searchKeywords ?? []),
      ].join(' ').toLowerCase();
      
      // Busca por palavras individuais
      final queryWords = queryLower.split(' ')
          .where((word) => word.isNotEmpty)
          .toList();
      
      if (queryWords.isEmpty) return true;
      
      final matches = queryWords.any((word) => searchableText.contains(word));
      
      // Debug: Log específico para perfis que contenham "itala"
      if (queryLower.contains('itala') && 
          (profile.displayName ?? '').toLowerCase().contains('itala')) {
        EnhancedLogger.info('DEBUG: Found Itala profile in filter', 
          tag: 'UNIFIED_PROFILE_SEARCH',
          data: {
            'profileName': profile.displayName,
            'profileType': profile.profileType,
            'searchableText': searchableText,
            'queryWords': queryWords,
            'matches': matches,
          }
        );
      }
      
      return matches;
    }).toList();
    
    // Debug: Log resultado do filtro para "itala"
    if (queryLower.contains('itala')) {
      EnhancedLogger.info('DEBUG: Text filter completed for "itala"', 
        tag: 'UNIFIED_PROFILE_SEARCH',
        data: {
          'originalCount': profiles.length,
          'filteredCount': filtered.length,
          'profilesWithItala': filtered.where((p) => 
            (p.displayName ?? '').toLowerCase().contains('itala')).length
        }
      );
    }
    
    return filtered;
  }

  /// Testa a busca unificada com logs detalhados
  static Future<void> testUnifiedSearch() async {
    print('🔍 TESTE: Busca Unificada de Perfis');
    print('=' * 50);
    
    // Teste 1: Busca vazia
    print('\n📊 Teste 1: Busca vazia (todos os perfis)');
    final allProfiles = await searchAllProfiles(limit: 20);
    print('✅ Encontrados: ${allProfiles.length} perfis');
    
    for (final profile in allProfiles.take(3)) {
      print('   - ${profile.displayName} (${profile.profileType ?? 'spiritual'})');
    }
    
    // Teste 2: Busca por "itala"
    print('\n📊 Teste 2: Busca por "itala"');
    final italaProfiles = await searchAllProfiles(query: 'itala', limit: 10);
    print('✅ Encontrados: ${italaProfiles.length} perfis');
    
    for (final profile in italaProfiles) {
      print('   - ${profile.displayName} (${profile.profileType ?? 'spiritual'})');
    }
    
    // Teste 3: Busca por "it"
    print('\n📊 Teste 3: Busca por "it"');
    final itProfiles = await searchAllProfiles(query: 'it', limit: 10);
    print('✅ Encontrados: ${itProfiles.length} perfis');
    
    for (final profile in itProfiles.take(3)) {
      print('   - ${profile.displayName} (${profile.profileType ?? 'spiritual'})');
    }
    
    print('\n🎉 TESTE CONCLUÍDO!');
  }
}