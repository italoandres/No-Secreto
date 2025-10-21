import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitário para popular dados de teste para o sistema Explorar Perfis
class PopulateExploreProfilesTestData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Popula dados de teste para perfis espirituais e engajamento
  static Future<void> populateTestData() async {
    print('🚀 Iniciando população de dados de teste...');

    try {
      // Dados de teste para perfis
      final testProfiles = [
        {
          'userId': 'test_user_1',
          'displayName': 'Maria Santos',
          'searchKeywords': ['maria', 'santos', 'são', 'paulo', 'sp', 'sao'],
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
          'userId': 'test_user_2',
          'displayName': 'João Silva',
          'searchKeywords': ['joão', 'joao', 'silva', 'rio', 'janeiro', 'rj'],
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
          'userId': 'test_user_3',
          'displayName': 'Ana Costa',
          'searchKeywords': ['ana', 'costa', 'belo', 'horizonte', 'mg'],
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
          'userId': 'test_user_4',
          'displayName': 'Pedro Oliveira',
          'searchKeywords': ['pedro', 'oliveira', 'porto', 'alegre', 'rs'],
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
          'userId': 'test_user_5',
          'displayName': 'Carla Mendes',
          'searchKeywords': ['carla', 'mendes', 'salvador', 'ba'],
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
          'userId': 'test_user_6',
          'displayName': 'Lucas Ferreira',
          'searchKeywords': ['lucas', 'ferreira', 'fortaleza', 'ce'],
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

      // Dados de engajamento correspondentes
      final testEngagements = [
        {
          'userId': 'test_user_1',
          'isEligibleForExploration': true,
          'engagementScore': 85.5,
          'lastUpdated': Timestamp.now(),
          'profileViews': 150,
          'profileLikes': 45,
          'messagesReceived': 12,
          'messagesReplied': 8,
        },
        {
          'userId': 'test_user_2',
          'isEligibleForExploration': true,
          'engagementScore': 92.3,
          'lastUpdated': Timestamp.now(),
          'profileViews': 200,
          'profileLikes': 60,
          'messagesReceived': 18,
          'messagesReplied': 15,
        },
        {
          'userId': 'test_user_3',
          'isEligibleForExploration': true,
          'engagementScore': 78.1,
          'lastUpdated': Timestamp.now(),
          'profileViews': 80,
          'profileLikes': 25,
          'messagesReceived': 6,
          'messagesReplied': 4,
        },
        {
          'userId': 'test_user_4',
          'isEligibleForExploration': true,
          'engagementScore': 95.7,
          'lastUpdated': Timestamp.now(),
          'profileViews': 300,
          'profileLikes': 85,
          'messagesReceived': 25,
          'messagesReplied': 22,
        },
        {
          'userId': 'test_user_5',
          'isEligibleForExploration': true,
          'engagementScore': 88.2,
          'lastUpdated': Timestamp.now(),
          'profileViews': 120,
          'profileLikes': 35,
          'messagesReceived': 10,
          'messagesReplied': 7,
        },
        {
          'userId': 'test_user_6',
          'isEligibleForExploration': true,
          'engagementScore': 82.4,
          'lastUpdated': Timestamp.now(),
          'profileViews': 90,
          'profileLikes': 28,
          'messagesReceived': 8,
          'messagesReplied': 5,
        },
      ];

      // Adicionar perfis espirituais
      print('📝 Adicionando perfis espirituais...');
      for (final profile in testProfiles) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profile['userId'] as String)
            .set(profile);
        print('✅ Perfil adicionado: ${profile['displayName']}');
      }

      // Adicionar dados de engajamento
      print('📊 Adicionando dados de engajamento...');
      for (final engagement in testEngagements) {
        await _firestore
            .collection('profile_engagement')
            .doc(engagement['userId'] as String)
            .set(engagement);
        print('✅ Engajamento adicionado: ${engagement['userId']}');
      }

      print('🎉 Dados de teste populados com sucesso!');
      print('📊 Total de perfis: ${testProfiles.length}');
      print('📊 Total de engajamentos: ${testEngagements.length}');

    } catch (e) {
      print('❌ Erro ao popular dados de teste: $e');
      rethrow;
    }
  }

  /// Remove todos os dados de teste
  static Future<void> clearTestData() async {
    print('🧹 Removendo dados de teste...');

    try {
      final testUserIds = [
        'test_user_1',
        'test_user_2', 
        'test_user_3',
        'test_user_4',
        'test_user_5',
        'test_user_6',
      ];

      // Remover perfis espirituais
      for (final userId in testUserIds) {
        await _firestore
            .collection('spiritual_profiles')
            .doc(userId)
            .delete();
        print('🗑️ Perfil removido: $userId');
      }

      // Remover dados de engajamento
      for (final userId in testUserIds) {
        await _firestore
            .collection('profile_engagement')
            .doc(userId)
            .delete();
        print('🗑️ Engajamento removido: $userId');
      }

      print('✅ Dados de teste removidos com sucesso!');

    } catch (e) {
      print('❌ Erro ao remover dados de teste: $e');
      rethrow;
    }
  }

  /// Verifica se os dados de teste existem
  static Future<bool> testDataExists() async {
    try {
      final doc = await _firestore
          .collection('spiritual_profiles')
          .doc('test_user_1')
          .get();
      
      return doc.exists;
    } catch (e) {
      print('❌ Erro ao verificar dados de teste: $e');
      return false;
    }
  }
}