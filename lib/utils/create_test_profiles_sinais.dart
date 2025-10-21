import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';

/// Script para criar perfis de teste para a aba Sinais
class CreateTestProfilesSinais {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria perfis de teste no Firestore
  static Future<void> createTestProfiles() async {
    try {
      EnhancedLogger.info(
        'Creating test profiles for Sinais',
        tag: 'TEST_PROFILES',
      );

      // PRIMEIRO: Criar perfil do usuário atual na coleção /profiles
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userProfileRef = _firestore
            .collection('profiles')
            .doc(currentUser.uid);
            
        final userProfileDoc = await userProfileRef.get();
        if (!userProfileDoc.exists) {
          // Buscar dados do usuário da coleção usuarios
          final userDoc = await _firestore
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();
              
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            await userProfileRef.set({
              'userId': currentUser.uid,
              'name': userData['nome'] ?? 'Usuário',
              'age': userData['idade'] ?? 25,
              'city': userData['cidade'] ?? 'São Paulo',
              'state': userData['estado'] ?? 'São Paulo',
              'bio': 'Perfil criado automaticamente para testes do sistema Sinais',
              'photos': userData['photos'] ?? [],
              'photoUrl': userData['photoUrl'] ?? '',
              'isVerified': true,
              'hasCertification': userData['certification'] ?? false,
              'isDeusEPaiMember': userData['deusEPaiMember'] ?? false,
              'hobbies': userData['hobbies'] ?? [],
              'commonHobbies': userData['commonHobbies'] ?? 3, // Para teste visual
              'isComplete': true,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'lastActive': FieldValue.serverTimestamp(),
            });
            
            EnhancedLogger.info(
              'User profile created in /profiles',
              tag: 'TEST_PROFILES',
              data: {'userId': currentUser.uid, 'name': userData['nome']},
            );
            
            print('✅ Seu perfil foi criado na coleção /profiles');
          }
        } else {
          print('ℹ️ Seu perfil já existe na coleção /profiles');
        }
      }

      // Perfil 1: Maria - Certificada, Movimento, Alta compatibilidade
      await _createProfile(
        userId: 'test_maria_001',
        data: {
          'userId': 'test_maria_001',
          'name': 'Maria Silva',
          'age': 28,
          'city': 'São Paulo',
          'state': 'São Paulo',
          'photoUrl':
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
          ],
          'bio':
              'Buscando alguém que compartilhe dos mesmos valores cristãos e propósito de vida. Amo servir na igreja e participar de atividades do movimento.',
          'purpose': 'Relacionamento sério com propósito de casamento',
          'hasCertification': true,
          'isDeusEPaiMember': true,
          'virginityStatus': 'Preservando até o casamento',
          'education': 'Ensino Superior Completo',
          'languages': ['Português', 'Inglês'],
          'hobbies': ['Música', 'Leitura', 'Voluntariado', 'Yoga'],
          'children': 'Não tenho',
          'drinking': 'Não bebo',
          'smoking': 'Não fumo',
          'height': 165,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Perfil 2: Ana - Certificada, Sem movimento
      await _createProfile(
        userId: 'test_ana_002',
        data: {
          'userId': 'test_ana_002',
          'name': 'Ana Costa',
          'age': 25,
          'city': 'Rio de Janeiro',
          'state': 'Rio de Janeiro',
          'photoUrl':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
          ],
          'bio':
              'Cristã dedicada, buscando um relacionamento sério baseado em valores e fé.',
          'purpose': 'Namoro cristão com intenção de casamento',
          'hasCertification': true,
          'isDeusEPaiMember': false,
          'virginityStatus': 'Preservando até o casamento',
          'education': 'Pós-graduação',
          'languages': ['Português', 'Espanhol'],
          'hobbies': ['Leitura', 'Cinema', 'Culinária'],
          'children': 'Não tenho',
          'drinking': 'Socialmente',
          'smoking': 'Não fumo',
          'height': 160,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Perfil 3: Juliana - Movimento, Sem certificação
      await _createProfile(
        userId: 'test_juliana_003',
        data: {
          'userId': 'test_juliana_003',
          'name': 'Juliana Santos',
          'age': 30,
          'city': 'Belo Horizonte',
          'state': 'Minas Gerais',
          'photoUrl':
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400',
          ],
          'bio':
              'Membro ativa do movimento Deus é Pai. Busco alguém que compartilhe da mesma fé e propósito.',
          'purpose': 'Conhecer pessoas com os mesmos valores para relacionamento sério',
          'hasCertification': false,
          'isDeusEPaiMember': true,
          'virginityStatus': null,
          'education': 'Ensino Superior Completo',
          'languages': ['Português'],
          'hobbies': ['Música', 'Dança', 'Voluntariado', 'Natureza'],
          'children': 'Não tenho',
          'drinking': 'Não bebo',
          'smoking': 'Não fumo',
          'height': 170,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Perfil 4: Beatriz - Perfil completo, sem certificação/movimento
      await _createProfile(
        userId: 'test_beatriz_004',
        data: {
          'userId': 'test_beatriz_004',
          'name': 'Beatriz Oliveira',
          'age': 27,
          'city': 'Curitiba',
          'state': 'Paraná',
          'photoUrl':
              'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
          ],
          'bio':
              'Cristã em busca de um relacionamento sério e duradouro. Valorizo família e fé.',
          'purpose': 'Relacionamento sério que leve ao casamento',
          'hasCertification': false,
          'isDeusEPaiMember': false,
          'virginityStatus': 'Preservando até o casamento',
          'education': 'Ensino Médio Completo',
          'languages': ['Português', 'Inglês'],
          'hobbies': ['Fotografia', 'Viagens', 'Leitura'],
          'children': 'Não tenho',
          'drinking': 'Socialmente',
          'smoking': 'Não fumo',
          'height': 158,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Perfil 5: Carolina - Certificada, Movimento, Muitos hobbies
      await _createProfile(
        userId: 'test_carolina_005',
        data: {
          'userId': 'test_carolina_005',
          'name': 'Carolina Ferreira',
          'age': 26,
          'city': 'Porto Alegre',
          'state': 'Rio Grande do Sul',
          'photoUrl':
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
            'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
          ],
          'bio':
              'Apaixonada por servir a Deus e ao próximo. Certificada espiritualmente e membro ativa do movimento.',
          'purpose': 'Encontrar um parceiro para construir uma família cristã',
          'hasCertification': true,
          'isDeusEPaiMember': true,
          'virginityStatus': 'Preservando até o casamento',
          'education': 'Ensino Superior Completo',
          'languages': ['Português', 'Inglês', 'Espanhol'],
          'hobbies': [
            'Música',
            'Leitura',
            'Voluntariado',
            'Yoga',
            'Meditação',
            'Arte'
          ],
          'children': 'Não tenho',
          'drinking': 'Não bebo',
          'smoking': 'Não fumo',
          'height': 168,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Perfil 6: Fernanda - Perfil básico
      await _createProfile(
        userId: 'test_fernanda_006',
        data: {
          'userId': 'test_fernanda_006',
          'name': 'Fernanda Lima',
          'age': 29,
          'city': 'Brasília',
          'state': 'Distrito Federal',
          'photoUrl':
              'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
          'photos': [
            'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400',
          ],
          'bio': 'Buscando um relacionamento sério com base na fé cristã.',
          'purpose': 'Namoro sério',
          'hasCertification': false,
          'isDeusEPaiMember': false,
          'virginityStatus': null,
          'education': 'Ensino Superior Incompleto',
          'languages': ['Português'],
          'hobbies': ['Cinema', 'Culinária'],
          'children': 'Não tenho',
          'drinking': 'Socialmente',
          'smoking': 'Não fumo',
          'height': 162,
          'isComplete': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      EnhancedLogger.success(
        'Test profiles created successfully',
        tag: 'TEST_PROFILES',
        data: {'count': 6},
      );

      print('✅ 6 perfis de teste criados com sucesso!');
      print('');
      print('Perfis criados:');
      print('1. Maria Silva (28) - Certificada + Movimento - São Paulo');
      print('2. Ana Costa (25) - Certificada - Rio de Janeiro');
      print('3. Juliana Santos (30) - Movimento - Belo Horizonte');
      print('4. Beatriz Oliveira (27) - Perfil completo - Curitiba');
      print('5. Carolina Ferreira (26) - Certificada + Movimento - Porto Alegre');
      print('6. Fernanda Lima (29) - Perfil básico - Brasília');
      print('');
      print('Agora você pode testar a aba Sinais! 🎉');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to create test profiles',
        tag: 'TEST_PROFILES',
        error: e,
      );
      print('❌ Erro ao criar perfis de teste: $e');
    }
  }

  /// Cria um perfil individual
  static Future<void> _createProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    // Criar na coleção /profiles (usada pelo sistema de recomendações)
    await _firestore.collection('profiles').doc(userId).set(data);
    EnhancedLogger.info(
      'Profile created',
      tag: 'TEST_PROFILES',
      data: {'userId': userId, 'name': data['name']},
    );
  }

  /// Remove perfis de teste
  static Future<void> deleteTestProfiles() async {
    try {
      EnhancedLogger.info(
        'Deleting test profiles',
        tag: 'TEST_PROFILES',
      );

      final testUserIds = [
        'test_maria_001',
        'test_ana_002',
        'test_juliana_003',
        'test_beatriz_004',
        'test_carolina_005',
        'test_fernanda_006',
      ];

      for (final userId in testUserIds) {
        await _firestore.collection('profiles').doc(userId).delete();
      }

      EnhancedLogger.success(
        'Test profiles deleted',
        tag: 'TEST_PROFILES',
      );

      print('✅ Perfis de teste removidos com sucesso!');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to delete test profiles',
        tag: 'TEST_PROFILES',
        error: e,
      );
      print('❌ Erro ao remover perfis de teste: $e');
    }
  }
}
