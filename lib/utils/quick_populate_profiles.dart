import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitário rápido para popular dados de teste
class QuickPopulateProfiles {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Popula dados rapidamente
  static Future<void> populateNow() async {
    print('🚀 POPULANDO DADOS AGORA...');
    
    try {
      // Criar 6 perfis simples
      final profiles = [
        {
          'userId': 'quick_user_1',
          'displayName': 'Maria Santos',
          'searchKeywords': ['maria', 'santos', 'são', 'paulo'],
          'age': 25,
          'city': 'São Paulo',
          'state': 'SP',
          'hasCompletedSinaisCoursе': true,
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
          'userId': 'quick_user_2',
          'displayName': 'João Silva',
          'searchKeywords': ['joão', 'joao', 'silva', 'rio'],
          'age': 28,
          'city': 'Rio de Janeiro',
          'state': 'RJ',
          'hasCompletedSinaisCoursе': true,
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
          'userId': 'quick_user_3',
          'displayName': 'Ana Costa',
          'searchKeywords': ['ana', 'costa', 'belo', 'horizonte'],
          'age': 30,
          'city': 'Belo Horizonte',
          'state': 'MG',
          'hasCompletedSinaisCoursе': false,
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
          'userId': 'quick_user_4',
          'displayName': 'Pedro Oliveira',
          'searchKeywords': ['pedro', 'oliveira', 'porto', 'alegre'],
          'age': 32,
          'city': 'Porto Alegre',
          'state': 'RS',
          'hasCompletedSinaisCoursе': true,
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
          'userId': 'quick_user_5',
          'displayName': 'Carla Mendes',
          'searchKeywords': ['carla', 'mendes', 'salvador'],
          'age': 26,
          'city': 'Salvador',
          'state': 'BA',
          'hasCompletedSinaisCoursе': true,
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
          'userId': 'quick_user_6',
          'displayName': 'Lucas Ferreira',
          'searchKeywords': ['lucas', 'ferreira', 'fortaleza'],
          'age': 29,
          'city': 'Fortaleza',
          'state': 'CE',
          'hasCompletedSinaisCoursе': false,
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

      // Dados de engajamento
      final engagements = [
        {
          'userId': 'quick_user_1',
          'isEligibleForExploration': true,
          'engagementScore': 85.5,
          'lastUpdated': Timestamp.now(),
        },
        {
          'userId': 'quick_user_2',
          'isEligibleForExploration': true,
          'engagementScore': 92.3,
          'lastUpdated': Timestamp.now(),
        },
        {
          'userId': 'quick_user_3',
          'isEligibleForExploration': true,
          'engagementScore': 78.1,
          'lastUpdated': Timestamp.now(),
        },
        {
          'userId': 'quick_user_4',
          'isEligibleForExploration': true,
          'engagementScore': 95.7,
          'lastUpdated': Timestamp.now(),
        },
        {
          'userId': 'quick_user_5',
          'isEligibleForExploration': true,
          'engagementScore': 88.2,
          'lastUpdated': Timestamp.now(),
        },
        {
          'userId': 'quick_user_6',
          'isEligibleForExploration': true,
          'engagementScore': 82.4,
          'lastUpdated': Timestamp.now(),
        },
      ];

      // Adicionar perfis
      print('📝 Adicionando perfis...');
      for (final profile in profiles) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profile['userId'] as String)
            .set(profile);
        print('✅ ${profile['displayName']} adicionado');
      }

      // Adicionar engajamentos
      print('📊 Adicionando engajamentos...');
      for (final engagement in engagements) {
        await _firestore
            .collection('profile_engagement')
            .doc(engagement['userId'] as String)
            .set(engagement);
        print('✅ Engajamento ${engagement['userId']} adicionado');
      }

      print('🎉 DADOS POPULADOS COM SUCESSO!');
      print('📊 Total: ${profiles.length} perfis + ${engagements.length} engajamentos');
      
    } catch (e) {
      print('❌ ERRO: $e');
      rethrow;
    }
  }

  /// Verifica se dados existem
  static Future<bool> checkData() async {
    try {
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(1)
          .get();
      
      final count = snapshot.docs.length;
      print('📊 Perfis encontrados: $count');
      return count > 0;
    } catch (e) {
      print('❌ Erro ao verificar dados: $e');
      return false;
    }
  }

  /// Remove dados de teste
  static Future<void> clearData() async {
    print('🧹 Removendo dados de teste...');
    
    final userIds = [
      'quick_user_1', 'quick_user_2', 'quick_user_3',
      'quick_user_4', 'quick_user_5', 'quick_user_6'
    ];

    for (final userId in userIds) {
      await _firestore.collection('spiritual_profiles').doc(userId).delete();
      await _firestore.collection('profile_engagement').doc(userId).delete();
      print('🗑️ $userId removido');
    }
    
    print('✅ Dados removidos!');
  }
}