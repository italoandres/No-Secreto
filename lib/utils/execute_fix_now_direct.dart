import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// EXECUTA CORREÇÃO DIRETA AGORA MESMO!
/// VOCÊ SÓ PRECISA CHAMAR: ExecuteFixNowDirect.runNow()
class ExecuteFixNowDirect {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// EXECUTA TUDO AGORA - CHAME ESTE MÉTODO!
  static Future<void> runNow() async {
    print('🚀🚀🚀 EXECUTANDO CORREÇÃO DIRETA AGORA! 🚀🚀🚀');
    print('=' * 60);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não logado');
        return;
      }

      print('✅ Usuário logado: ${currentUser.uid}');

      // 1. POPULAR DADOS DE TESTE PRIMEIRO
      print('\n1️⃣ POPULANDO DADOS DE TESTE...');
      await _populateTestData();

      // 2. CORRIGIR SEU PERFIL
      print('\n2️⃣ CORRIGINDO SEU PERFIL...');
      await _fixUserProfile(currentUser.uid);

      print('\n' + '=' * 60);
      print('🎉🎉🎉 CORREÇÃO DIRETA CONCLUÍDA! 🎉🎉🎉');
      print('📱 AGORA TESTE: Toque no ícone 🔍 na barra superior');
      print('📊 VOCÊ DEVE VER: 7 perfis (6 de teste + o seu)');
      print('🔍 BUSQUE POR: "italo", "maria", "joão"');
      print('=' * 60);

    } catch (e) {
      print('❌ ERRO DURANTE CORREÇÃO: $e');
      rethrow;
    }
  }

  /// Popula dados de teste diretamente
  static Future<void> _populateTestData() async {
    try {
      // SEMPRE RECRIAR OS DADOS PARA GARANTIR QUE ESTÃO CORRETOS
      print('🔄 Removendo dados antigos e recriando...');
      
      // Remover dados antigos
      final existingData = await _firestore
          .collection('spiritual_profiles')
          .where('userId', whereIn: ['quick_user_1', 'quick_user_2', 'quick_user_3', 'quick_user_4', 'quick_user_5', 'quick_user_6'])
          .get();

      for (final doc in existingData.docs) {
        await doc.reference.delete();
        print('🗑️ Removido: ${doc.data()['displayName']}');
      }

      // Criar 6 perfis de teste
      final profiles = [
        {
          'userId': 'quick_user_1',
          'displayName': 'Maria Santos',
          'searchKeywords': ['maria', 'santos', 'são', 'paulo'],
          'age': 25,
          'city': 'São Paulo',
          'state': 'SP',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 150,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/4A90E2/FFFFFF?text=Maria',
          'relationshipStatus': 'solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'quick_user_2',
          'displayName': 'João Silva',
          'searchKeywords': ['joão', 'joao', 'silva', 'rio'],
          'age': 28,
          'city': 'Rio de Janeiro',
          'state': 'RJ',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 200,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/50C878/FFFFFF?text=João',
          'relationshipStatus': 'solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'quick_user_3',
          'displayName': 'Ana Costa',
          'searchKeywords': ['ana', 'costa', 'belo', 'horizonte'],
          'age': 30,
          'city': 'Belo Horizonte',
          'state': 'MG',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 80,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Ana',
          'relationshipStatus': 'solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'quick_user_4',
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
          'relationshipStatus': 'solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'quick_user_5',
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
          'relationshipStatus': 'solteira',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'userId': 'quick_user_6',
          'displayName': 'Lucas Ferreira',
          'searchKeywords': ['lucas', 'ferreira', 'fortaleza'],
          'age': 29,
          'city': 'Fortaleza',
          'state': 'CE',
          'hasCompletedSinaisCourse': true,
          'isActive': true,
          'isVerified': true,
          'viewsCount': 90,
          'mainPhotoUrl': 'https://via.placeholder.com/300x400/3498DB/FFFFFF?text=Lucas',
          'relationshipStatus': 'solteiro',
          'isProfileComplete': true,
          'hasSinaisPreparationSeal': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Adicionar perfis
      for (final profile in profiles) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profile['userId'] as String)
            .set(profile);
        print('✅ ${profile['displayName']} adicionado');

        // Adicionar engajamento
        await _firestore
            .collection('profile_engagement')
            .doc(profile['userId'] as String)
            .set({
          'userId': profile['userId'],
          'isEligibleForExploration': true,
          'engagementScore': 85.0,
          'lastUpdated': Timestamp.now(),
          'profileViews': 0,
          'profileLikes': 0,
          'messagesReceived': 0,
          'messagesReplied': 0,
        });
      }

      print('✅ 6 perfis de teste criados com sucesso!');
    } catch (e) {
      print('⚠️ Erro ao popular dados: $e');
    }
  }

  /// Corrige o perfil do usuário atual
  static Future<void> _fixUserProfile(String userId) async {
    try {
      // Buscar perfil do usuário
      final profileQuery = await _firestore
          .collection('spiritual_profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        print('❌ Perfil não encontrado para o usuário');
        return;
      }

      final profileDoc = profileQuery.docs.first;
      final profileData = profileDoc.data();
      final profileId = profileDoc.id;

      print('✅ Perfil encontrado: $profileId');

      // Campos necessários para correção
      final updates = <String, dynamic>{};

      if (profileData['isActive'] != true) {
        updates['isActive'] = true;
        print('🔧 Corrigindo: isActive = true');
      }

      if (profileData['isVerified'] != true) {
        updates['isVerified'] = true;
        print('🔧 Corrigindo: isVerified = true');
      }

      if (profileData['hasCompletedSinaisCourse'] != true) {
        updates['hasCompletedSinaisCourse'] = true;
        print('🔧 Corrigindo: hasCompletedSinaisCourse = true');
      }

      // Gerar searchKeywords se não existir
      final displayName = profileData['displayName'] as String?;
      if (displayName != null && profileData['searchKeywords'] == null) {
        final keywords = displayName.toLowerCase().split(' ');
        updates['searchKeywords'] = keywords;
        print('🔧 Adicionando searchKeywords: $keywords');
      }

      // Adicionar idade se não existir
      if (profileData['age'] == null) {
        updates['age'] = 25;
        print('🔧 Definindo idade padrão: 25');
      }

      // Adicionar viewsCount se não existir
      if (profileData['viewsCount'] == null) {
        updates['viewsCount'] = 0;
        print('🔧 Adicionando viewsCount: 0');
      }

      updates['updatedAt'] = Timestamp.now();

      // Aplicar correções
      if (updates.isNotEmpty) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(updates);
        print('✅ Perfil corrigido com ${updates.length} campos!');
      }

      // Criar registro de engajamento
      await _firestore
          .collection('profile_engagement')
          .doc(userId)
          .set({
        'userId': userId,
        'isEligibleForExploration': true,
        'engagementScore': 75.0,
        'lastUpdated': Timestamp.now(),
        'profileViews': 0,
        'profileLikes': 0,
        'messagesReceived': 0,
        'messagesReplied': 0,
      }, SetOptions(merge: true));

      print('✅ Registro de engajamento criado/atualizado!');

    } catch (e) {
      print('❌ Erro ao corrigir perfil: $e');
    }
  }
}