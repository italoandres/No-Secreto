import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';

/// Filtro específico para perfis de vitrine de propósito completos
class VitrineProfileFilter {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca apenas perfis de vitrine completos com username cadastrado
  static Future<List<SpiritualProfileModel>> searchCompleteVitrineProfiles({
    String? query,
    int limit = 20,
  }) async {
    final startTime = DateTime.now();
    
    try {
      EnhancedLogger.info('Searching complete vitrine profiles only', 
        tag: 'VITRINE_PROFILE_FILTER',
        data: {'query': query, 'limit': limit}
      );

      // Buscar na coleção spiritual_profiles com filtros específicos para vitrine completa
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .where('isProfileComplete', isEqualTo: true) // Apenas perfis completos
          .limit(limit * 5) // Buscar mais para filtrar depois
          .get();

      List<SpiritualProfileModel> vitrineProfiles = [];

      for (final doc in snapshot.docs) {
        try {
          final userData = doc.data();
          
          // Verificar se é um perfil de vitrine completo
          if (_isCompleteVitrineProfile(userData)) {
            final profile = _convertToSpiritualProfile(doc.id, userData);
            
            // Aplicar filtro de busca textual se necessário
            if (_matchesSearchQuery(profile, query)) {
              vitrineProfiles.add(profile);
            }
          }
        } catch (e) {
          EnhancedLogger.warning('Failed to process user profile', 
            tag: 'VITRINE_PROFILE_FILTER',
            data: {'docId': doc.id, 'error': e.toString()}
          );
        }
      }

      // Limitar resultados finais
      final finalResults = vitrineProfiles.take(limit).toList();

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      EnhancedLogger.success('Complete vitrine profiles search completed', 
        tag: 'VITRINE_PROFILE_FILTER',
        data: {
          'totalDocuments': snapshot.docs.length,
          'completeVitrineProfiles': vitrineProfiles.length,
          'finalResults': finalResults.length,
          'executionTime': executionTime,
        }
      );

      return finalResults;

    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      EnhancedLogger.error('Complete vitrine profiles search failed', 
        tag: 'VITRINE_PROFILE_FILTER',
        error: e,
        data: {'executionTime': executionTime}
      );
      
      return [];
    }
  }

  /// Verifica se é um perfil de vitrine completo (dados da spiritual_profiles)
  static bool _isCompleteVitrineProfile(Map<String, dynamic> profileData) {
    // 1. Deve ter username cadastrado (não vazio e não "N/A")
    final username = profileData['username'] as String?;
    if (username == null || username.isEmpty || username == 'N/A') {
      return false;
    }

    // 2. Deve ter displayName
    final displayName = profileData['displayName'] as String?;
    if (displayName == null || displayName.isEmpty) {
      return false;
    }

    // 3. Deve ter dados básicos de vitrine
    final city = profileData['city'] as String?;
    final state = profileData['state'] as String?;
    final aboutMe = profileData['aboutMe'] as String?;
    
    // Pelo menos cidade OU estado deve estar preenchido
    if ((city == null || city.isEmpty) && (state == null || state.isEmpty)) {
      return false;
    }

    // 4. AboutMe deve estar preenchida (característica de perfil de vitrine)
    if (aboutMe == null || aboutMe.isEmpty) {
      return false;
    }

    // 5. Deve ter idade
    final age = profileData['age'];
    if (age == null) {
      return false;
    }

    // 6. Perfil deve estar completo
    final isProfileComplete = profileData['isProfileComplete'] as bool?;
    if (isProfileComplete != true) {
      return false;
    }

    return true;
  }

  /// Verifica se o perfil corresponde à query de busca
  static bool _matchesSearchQuery(SpiritualProfileModel profile, String? query) {
    if (query == null || query.isEmpty) {
      return true;
    }

    final searchableText = [
      profile.displayName ?? '',
      profile.username ?? '',  // ← ADICIONADO USERNAME!
      profile.bio ?? '',
      profile.city ?? '',
      profile.state ?? '',
    ].join(' ').toLowerCase();

    final queryWords = query.toLowerCase().split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    if (queryWords.isEmpty) return true;

    return queryWords.any((word) => searchableText.contains(word));
  }

  /// Converte dados de spiritual_profiles para SpiritualProfileModel
  static SpiritualProfileModel _convertToSpiritualProfile(
    String docId, 
    Map<String, dynamic> profileData,
  ) {
    return SpiritualProfileModel(
      id: docId,
      userId: profileData['userId'] as String? ?? docId,
      displayName: profileData['displayName'] as String? ?? 'Usuário',
      username: profileData['username'] as String? ?? '',  // ← ADICIONADO USERNAME!
      age: profileData['age'] as int?,
      bio: profileData['aboutMe'] as String? ?? '',
      city: profileData['city'] as String? ?? '',
      state: profileData['state'] as String? ?? '',
      photoUrl: profileData['mainPhotoUrl'] as String?,
      interests: _extractInterests(profileData),
      isActive: true, // Perfis completos são considerados ativos
      isVerified: true, // Perfis de vitrine são considerados verificados
      hasCompletedCourse: profileData['hasCompletedCourse'] as bool? ?? false,
      createdAt: _parseTimestamp(profileData['createdAt']),
      updatedAt: _parseTimestamp(profileData['updatedAt']),
      // Marcar como perfil de vitrine completo
      profileType: 'vitrine_completo',
      searchKeywords: _generateSearchKeywords(profileData),
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

  /// Extrai interesses dos dados do perfil espiritual
  static List<String> _extractInterests(Map<String, dynamic> profileData) {
    final interests = <String>[];
    
    if (profileData['city'] != null) {
      interests.add(profileData['city'] as String);
    }
    if (profileData['state'] != null) {
      interests.add(profileData['state'] as String);
    }
    
    // Adicionar interesses específicos se existirem
    final profileInterests = profileData['interests'];
    if (profileInterests is List) {
      interests.addAll(profileInterests.cast<String>());
    }
    
    return interests;
  }

  /// Gera keywords de busca para o perfil
  static List<String> _generateSearchKeywords(Map<String, dynamic> profileData) {
    final keywords = <String>[];
    
    final displayName = profileData['displayName'] as String? ?? '';
    final username = profileData['username'] as String? ?? '';
    final city = profileData['city'] as String? ?? '';
    final state = profileData['state'] as String? ?? '';
    
    if (displayName.isNotEmpty) {
      keywords.add(displayName.toLowerCase());
      keywords.addAll(displayName.toLowerCase().split(' '));
    }
    
    if (username.isNotEmpty) {
      keywords.add(username.toLowerCase());
    }
    
    if (city.isNotEmpty) {
      keywords.add(city.toLowerCase());
    }
    if (state.isNotEmpty) {
      keywords.add(state.toLowerCase());
    }
    
    return keywords.toSet().toList();
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

  /// Debug: Lista todos os perfis de vitrine completos
  static Future<void> debugCompleteVitrineProfiles() async {
    print('\n🔍 DEBUG: Perfis de Vitrine Completos');
    print('=' * 50);

    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .limit(50)
          .get();

      int totalUsers = snapshot.docs.length;
      int completeVitrineCount = 0;
      int incompleteCount = 0;

      print('📊 Total de usuários analisados: $totalUsers');
      print('\n🔍 Analisando cada perfil...');

      for (final doc in snapshot.docs) {
        final userData = doc.data();
        final nome = userData['nome'] as String? ?? 'Sem nome';
        
        if (_isCompleteVitrineProfile(userData)) {
          completeVitrineCount++;
          print('✅ VITRINE COMPLETO: $nome');
          print('   • Username: ${userData['username']}');
          print('   • Cidade: ${userData['cidade'] ?? 'N/A'}');
          print('   • Estado: ${userData['estado'] ?? 'N/A'}');
          print('   • Bio: ${(userData['bio'] as String? ?? '').length > 0 ? 'Sim' : 'Não'}');
          print('   • Nascimento: ${userData['nascimento'] != null ? 'Sim' : 'Não'}');
        } else {
          incompleteCount++;
          print('❌ INCOMPLETO: $nome');
          print('   • Username: ${userData['username'] ?? 'N/A'}');
          print('   • Motivo: ${_getIncompleteReason(userData)}');
        }
        print('');
      }

      print('\n📊 RESUMO:');
      print('   • Total analisados: $totalUsers');
      print('   • Perfis de vitrine completos: $completeVitrineCount');
      print('   • Perfis incompletos: $incompleteCount');
      print('   • Taxa de completude: ${(completeVitrineCount / totalUsers * 100).toStringAsFixed(1)}%');

    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }

  /// Retorna o motivo pelo qual um perfil não é considerado completo
  static String _getIncompleteReason(Map<String, dynamic> userData) {
    final reasons = <String>[];

    final username = userData['username'] as String?;
    if (username == null || username.isEmpty || username == 'N/A') {
      reasons.add('Username ausente');
    }

    final nome = userData['nome'] as String?;
    if (nome == null || nome.isEmpty) {
      reasons.add('Nome ausente');
    }

    final cidade = userData['cidade'] as String?;
    final estado = userData['estado'] as String?;
    if ((cidade == null || cidade.isEmpty) && (estado == null || estado.isEmpty)) {
      reasons.add('Localização ausente');
    }

    final bio = userData['bio'] as String?;
    if (bio == null || bio.isEmpty) {
      reasons.add('Bio ausente');
    }

    final nascimento = userData['nascimento'];
    if (nascimento == null) {
      reasons.add('Data nascimento ausente');
    }

    final isActive = userData['isActive'] as bool?;
    if (isActive != true) {
      reasons.add('Perfil inativo');
    }

    return reasons.isEmpty ? 'Motivo desconhecido' : reasons.join(', ');
  }

  /// Testa a busca de perfis de vitrine completos
  static Future<void> testCompleteVitrineSearch() async {
    print('\n🔍 TESTE: Busca de Perfis de Vitrine Completos');
    print('=' * 60);

    // Teste 1: Busca geral
    print('\n📊 Teste 1: Busca geral (todos os perfis completos)');
    final allComplete = await searchCompleteVitrineProfiles(limit: 20);
    print('✅ Encontrados: ${allComplete.length} perfis completos');
    
    for (final profile in allComplete.take(5)) {
      print('   - ${profile.displayName} - ${profile.city}, ${profile.state}');
    }

    // Teste 2: Busca por "itala"
    print('\n📊 Teste 2: Busca por "itala"');
    final italaProfiles = await searchCompleteVitrineProfiles(query: 'itala', limit: 10);
    print('✅ Encontrados: ${italaProfiles.length} perfis');
    
    for (final profile in italaProfiles) {
      print('   - ${profile.displayName} - ${profile.city}, ${profile.state}');
      final bioPreview = profile.bio?.length != null && profile.bio!.length > 50 
          ? profile.bio!.substring(0, 50) + '...'
          : profile.bio ?? '';
      print('     Bio: $bioPreview');
    }

    print('\n🎉 TESTE CONCLUÍDO!');
  }
}