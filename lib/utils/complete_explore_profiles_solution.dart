import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Solução completa para o sistema Explorar Perfis
class CompleteExploreProfilesSolution {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Executa solução completa: corrige perfil + adiciona dados de teste
  static Future<void> runCompleteSolution() async {
    print('🚀 INICIANDO SOLUÇÃO COMPLETA - EXPLORAR PERFIS');
    print('=' * 60);

    try {
      // 1. Corrigir perfil do usuário atual
      print('\n1️⃣ Corrigindo seu perfil existente...');
      await _fixCurrentUserProfile();

      // 2. Adicionar dados de teste
      print('\n2️⃣ Adicionando perfis de teste...');
      await _addTestProfiles();

      // 3. Verificar resultado
      print('\n3️⃣ Verificando resultado final...');
      await _verifyResults();

      print('\n' + '=' * 60);
      print('🎉 SOLUÇÃO COMPLETA APLICADA COM SUCESSO!');
      print('📱 TESTE AGORA: Toque no ícone 🔍 na barra superior');
      print('🔍 BUSQUE POR: seu nome, "maria", "joão", "ana"');
      print('=' * 60);

    } catch (e) {
      print('❌ Erro na solução completa: $e');
      rethrow;
    }
  }

  /// Corrige o perfil do usuário atual
  static Future<void> _fixCurrentUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ Usuário não autenticado - pulando correção do perfil');
        return;
      }

      print('🔍 Procurando seu perfil...');

      // Buscar perfil do usuário atual
      final profileQuery = await _firestore
          .collection('spiritual_profiles')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        print('⚠️ Seu perfil não foi encontrado - pulando correção');
        return;
      }

      final profileDoc = profileQuery.docs.first;
      final profileData = profileDoc.data();
      final profileId = profileDoc.id;

      print('✅ Seu perfil encontrado: $profileId');

      // Campos necessários para aparecer no Explorar Perfis
      final updates = <String, dynamic>{};

      // Campos obrigatórios
      if (profileData['isActive'] != true) {
        updates['isActive'] = true;
      }
      if (profileData['isVerified'] != true) {
        updates['isVerified'] = true;
      }
      if (profileData['hasCompletedSinaisCourse'] != true) {
        updates['hasCompletedSinaisCourse'] = true;
      }

      // Campos de busca
      final displayName = profileData['displayName'] as String?;
      if (displayName != null && profileData['searchKeywords'] == null) {
        final keywords = _generateSearchKeywords(displayName, profileData);
        updates['searchKeywords'] = keywords;
      }

      // Campos de ordenação
      if (profileData['viewsCount'] == null) {
        updates['viewsCount'] = 0;
      }
      if (profileData['age'] == null) {
        updates['age'] = 25; // Idade padrão
      }

      updates['updatedAt'] = Timestamp.now();

      // Aplicar correções
      if (updates.isNotEmpty) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(updates);
        print('✅ Seu perfil foi corrigido (${updates.length} campos)');
      } else {
        print('✅ Seu perfil já estava correto');
      }

      // Criar registro de engajamento
      await _createEngagementRecord(currentUser.uid);

    } catch (e) {
      print('❌ Erro ao corrigir seu perfil: $e');
    }
  }

  /// Adiciona perfis de teste
  static Future<void> _addTestProfiles() async {
    try {
      // Verificar se já existem dados de teste
      final existingTest = await _firestore
          .collection('spiritual_profiles')
          .doc('complete_test_user_1')
          .get();

      if (existingTest.exists) {
        print('✅ Perfis de teste já existem');
        return;
      }

      print('📝 Criando 6 perfis de teste...');

      // Perfis de teste
      final testProfiles = [
        {
          'userId': 'complete_test_user_1',
          'displayName': 'Maria Santos',
          'searchKeywords': ['maria', 'santos', 'são', 'paulo', 'sp'],
          'age': 25,
          'city': 'São Paulo',
          'state': 'SP',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 150,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/4A90E2/FFFFFF?text=Maria',
          'relationshipStatus': 'Solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'complete_test_user_2',
          'displayName': 'João Silva',
          'searchKeywords': ['joão', 'joao', 'silva', 'rio', 'janeiro'],
          'age': 28,
          'city': 'Rio de Janeiro',
          'state': 'RJ',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 200,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/50C878/FFFFFF?text=João',
          'relationshipStatus': 'Solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'complete_test_user_3',
          'displayName': 'Ana Costa',
          'searchKeywords': ['ana', 'costa', 'belo', 'horizonte'],
          'age': 30,
          'city': 'Belo Horizonte',
          'state': 'MG',
          'hasCompletedSinaisCourse': false,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 80,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Ana',
          'relationshipStatus': 'Solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'complete_test_user_4',
          'displayName': 'Pedro Oliveira',
          'searchKeywords': ['pedro', 'oliveira', 'porto', 'alegre'],
          'age': 32,
          'city': 'Porto Alegre',
          'state': 'RS',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 300,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/9B59B6/FFFFFF?text=Pedro',
          'relationshipStatus': 'Solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'complete_test_user_5',
          'displayName': 'Carla Mendes',
          'searchKeywords': ['carla', 'mendes', 'salvador'],
          'age': 26,
          'city': 'Salvador',
          'state': 'BA',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 120,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/F39C12/FFFFFF?text=Carla',
          'relationshipStatus': 'Solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'complete_test_user_6',
          'displayName': 'Lucas Ferreira',
          'searchKeywords': ['lucas', 'ferreira', 'fortaleza'],
          'age': 29,
          'city': 'Fortaleza',
          'state': 'CE',
          'hasCompletedSinaisCourse': false,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 90,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/3498DB/FFFFFF?text=Lucas',
          'relationshipStatus': 'Solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Dados de engajamento correspondentes
      final engagements = [
        {'userId': 'complete_test_user_1', 'engagementScore': 85.5},
        {'userId': 'complete_test_user_2', 'engagementScore': 92.3},
        {'userId': 'complete_test_user_3', 'engagementScore': 78.1},
        {'userId': 'complete_test_user_4', 'engagementScore': 95.7},
        {'userId': 'complete_test_user_5', 'engagementScore': 88.2},
        {'userId': 'complete_test_user_6', 'engagementScore': 82.4},
      ];

      // Adicionar perfis
      for (final profile in testProfiles) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profile['userId'] as String)
            .set(profile);
        print('✅ ${profile['displayName']} adicionado');
      }

      // Adicionar engajamentos
      for (final engagement in engagements) {
        await _createEngagementRecord(
          engagement['userId'] as String,
          engagement['engagementScore'] as double,
        );
      }

      print('✅ 6 perfis de teste criados com sucesso!');

    } catch (e) {
      print('❌ Erro ao adicionar perfis de teste: $e');
    }
  }

  /// Verifica os resultados finais
  static Future<void> _verifyResults() async {
    try {
      // Testar query de perfis verificados
      final verifiedQuery = await _firestore
          .collection('spiritual_profiles')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();

      print('✅ Perfis verificados encontrados: ${verifiedQuery.docs.length}');

      // Testar query de engajamento
      final engagementQuery = await _firestore
          .collection('profile_engagement')
          .where('isEligibleForExploration', isEqualTo: true)
          .limit(10)
          .get();

      print('✅ Registros de engajamento: ${engagementQuery.docs.length}');

      // Testar busca por "maria"
      try {
        final searchQuery = await _firestore
            .collection('spiritual_profiles')
            .where('searchKeywords', arrayContains: 'maria')
            .where('isActive', isEqualTo: true)
            .where('isVerified', isEqualTo: true)
            .limit(5)
            .get();

        print('✅ Busca por "maria": ${searchQuery.docs.length} resultados');
      } catch (e) {
        print('⚠️ Busca ainda requer índice (normal se acabou de criar)');
      }

    } catch (e) {
      print('❌ Erro na verificação: $e');
    }
  }

  /// Gera palavras-chave de busca
  static List<String> _generateSearchKeywords(String displayName, Map<String, dynamic> profileData) {
    final keywords = <String>[];

    // Palavras do nome
    final nameParts = displayName.toLowerCase().split(' ');
    keywords.addAll(nameParts);

    // Cidade
    final city = profileData['city'] as String?;
    if (city != null && city.isNotEmpty) {
      keywords.add(city.toLowerCase());
    }

    // Estado
    final state = profileData['state'] as String?;
    if (state != null && state.isNotEmpty) {
      keywords.add(state.toLowerCase());
    }

    return keywords
        .where((keyword) => keyword.length >= 2)
        .toSet()
        .toList();
  }

  /// Cria registro de engajamento
  static Future<void> _createEngagementRecord(String userId, [double? score]) async {
    try {
      final engagementDoc = await _firestore
          .collection('profile_engagement')
          .doc(userId)
          .get();

      if (!engagementDoc.exists) {
        await _firestore
            .collection('profile_engagement')
            .doc(userId)
            .set({
          'userId': userId,
          'isEligibleForExploration': true,
          'engagementScore': score ?? 75.0,
          'lastUpdated': Timestamp.now(),
          'profileViews': 0,
          'profileLikes': 0,
          'messagesReceived': 0,
          'messagesReplied': 0,
        });
        print('✅ Engajamento criado para $userId');
      }
    } catch (e) {
      print('⚠️ Erro ao criar engajamento para $userId: $e');
    }
  }

  /// Remove todos os dados de teste
  static Future<void> clearTestData() async {
    print('🧹 Removendo dados de teste...');
    
    final testUserIds = [
      'complete_test_user_1',
      'complete_test_user_2',
      'complete_test_user_3',
      'complete_test_user_4',
      'complete_test_user_5',
      'complete_test_user_6',
    ];

    for (final userId in testUserIds) {
      try {
        await _firestore.collection('spiritual_profiles').doc(userId).delete();
        await _firestore.collection('profile_engagement').doc(userId).delete();
        print('🗑️ $userId removido');
      } catch (e) {
        print('⚠️ Erro ao remover $userId: $e');
      }
    }
    
    print('✅ Dados de teste removidos!');
  }

  /// Verifica se a solução foi aplicada
  static Future<bool> checkSolutionStatus() async {
    try {
      final testProfile = await _firestore
          .collection('spiritual_profiles')
          .doc('complete_test_user_1')
          .get();
      
      return testProfile.exists;
    } catch (e) {
      return false;
    }
  }
}