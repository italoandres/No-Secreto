import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utilitário para corrigir perfil existente para aparecer no Explorar Perfis
class FixExistingProfileForExploration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Corrige o perfil do usuário atual para aparecer no Explorar Perfis
  static Future<void> fixCurrentUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        return;
      }

      print('🔍 Procurando perfil do usuário: ${currentUser.uid}');

      // Buscar perfil do usuário atual
      final profileQuery = await _firestore
          .collection('spiritual_profiles')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        print('❌ Perfil não encontrado para o usuário atual');
        return;
      }

      final profileDoc = profileQuery.docs.first;
      final profileData = profileDoc.data();
      final profileId = profileDoc.id;

      print('✅ Perfil encontrado: $profileId');
      print('📊 Dados atuais: ${profileData.keys.toList()}');

      // Campos necessários para aparecer no Explorar Perfis
      final requiredUpdates = <String, dynamic>{};

      // 1. Campos obrigatórios para queries básicas
      if (profileData['isActive'] != true) {
        requiredUpdates['isActive'] = true;
        print('🔧 Corrigindo: isActive = true');
      }

      if (profileData['isVerified'] != true) {
        requiredUpdates['isVerified'] = true;
        print('🔧 Corrigindo: isVerified = true');
      }

      if (profileData['hasCompletedSinaisCourse'] != true) {
        requiredUpdates['hasCompletedSinaisCourse'] = true;
        print('🔧 Corrigindo: hasCompletedSinaisCourse = true');
      }

      // 2. Campos para busca
      final displayName = profileData['displayName'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        // Criar searchKeywords se não existir
        if (profileData['searchKeywords'] == null) {
          final keywords = _generateSearchKeywords(displayName, profileData);
          requiredUpdates['searchKeywords'] = keywords;
          print('🔧 Adicionando searchKeywords: $keywords');
        }
      }

      // 3. Campos para ordenação
      if (profileData['viewsCount'] == null) {
        requiredUpdates['viewsCount'] = 0;
        print('🔧 Adicionando: viewsCount = 0');
      }

      // 4. Campos de idade para filtros
      if (profileData['age'] == null) {
        // Tentar calcular idade da data de nascimento
        final birthDate = profileData['birthDate'];
        if (birthDate != null) {
          final age = _calculateAge(birthDate);
          requiredUpdates['age'] = age;
          print('🔧 Calculando idade: $age anos');
        } else {
          requiredUpdates['age'] = 25; // Idade padrão
          print('🔧 Definindo idade padrão: 25 anos');
        }
      }

      // 5. Timestamp de atualização
      requiredUpdates['updatedAt'] = Timestamp.now();

      // Aplicar correções se necessário
      if (requiredUpdates.isNotEmpty) {
        print('🚀 Aplicando ${requiredUpdates.length} correções...');
        
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(requiredUpdates);

        print('✅ Perfil corrigido com sucesso!');
        print('📊 Campos atualizados: ${requiredUpdates.keys.toList()}');
      } else {
        print('✅ Perfil já está correto para exploração!');
      }

      // Criar registro de engajamento se não existir
      await _createEngagementRecord(currentUser.uid);

      print('🎉 Perfil pronto para aparecer no Explorar Perfis!');

    } catch (e) {
      print('❌ Erro ao corrigir perfil: $e');
      rethrow;
    }
  }

  /// Gera palavras-chave de busca baseadas no nome e dados do perfil
  static List<String> _generateSearchKeywords(String displayName, Map<String, dynamic> profileData) {
    final keywords = <String>[];

    // Adicionar palavras do nome
    final nameParts = displayName.toLowerCase().split(' ');
    keywords.addAll(nameParts);

    // Adicionar cidade se existir
    final city = profileData['city'] as String?;
    if (city != null && city.isNotEmpty) {
      keywords.add(city.toLowerCase());
    }

    // Adicionar estado se existir
    final state = profileData['state'] as String?;
    if (state != null && state.isNotEmpty) {
      keywords.add(state.toLowerCase());
    }

    // Remover duplicatas e palavras muito curtas
    return keywords
        .where((keyword) => keyword.length >= 2)
        .toSet()
        .toList();
  }

  /// Calcula idade baseada na data de nascimento
  static int _calculateAge(dynamic birthDate) {
    try {
      DateTime birth;
      if (birthDate is Timestamp) {
        birth = birthDate.toDate();
      } else if (birthDate is DateTime) {
        birth = birthDate;
      } else {
        return 25; // Idade padrão se não conseguir calcular
      }

      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 25; // Idade padrão em caso de erro
    }
  }

  /// Cria registro de engajamento se não existir
  static Future<void> _createEngagementRecord(String userId) async {
    try {
      final engagementDoc = await _firestore
          .collection('profile_engagement')
          .doc(userId)
          .get();

      if (!engagementDoc.exists) {
        print('🔧 Criando registro de engajamento...');
        
        await _firestore
            .collection('profile_engagement')
            .doc(userId)
            .set({
          'userId': userId,
          'isEligibleForExploration': true,
          'engagementScore': 75.0, // Score inicial
          'lastUpdated': Timestamp.now(),
          'profileViews': 0,
          'profileLikes': 0,
          'messagesReceived': 0,
          'messagesReplied': 0,
        });

        print('✅ Registro de engajamento criado!');
      } else {
        print('✅ Registro de engajamento já existe');
      }
    } catch (e) {
      print('⚠️ Erro ao criar registro de engajamento: $e');
    }
  }

  /// Verifica se o perfil atual está visível no Explorar Perfis
  static Future<bool> checkProfileVisibility() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        return false;
      }

      print('🔍 Verificando visibilidade do perfil...');

      // Testar query de perfis verificados
      final verifiedQuery = await _firestore
          .collection('spiritual_profiles')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('hasCompletedSinaisCourse', isEqualTo: true)
          .limit(1)
          .get();

      final isVisible = verifiedQuery.docs.isNotEmpty;
      
      if (isVisible) {
        print('✅ Perfil está visível no Explorar Perfis!');
        final profileData = verifiedQuery.docs.first.data();
        print('📊 Nome: ${profileData['displayName']}');
        print('📊 Cidade: ${profileData['city']}');
        print('📊 Keywords: ${profileData['searchKeywords']}');
      } else {
        print('❌ Perfil NÃO está visível no Explorar Perfis');
      }

      return isVisible;
    } catch (e) {
      print('❌ Erro ao verificar visibilidade: $e');
      return false;
    }
  }

  /// Executa correção completa e verificação
  static Future<void> runCompleteCheck() async {
    print('🚀 INICIANDO CORREÇÃO COMPLETA DO PERFIL');
    print('=' * 50);

    // 1. Verificar visibilidade atual
    print('\n1️⃣ Verificando visibilidade atual...');
    final wasVisible = await checkProfileVisibility();

    // 2. Aplicar correções
    print('\n2️⃣ Aplicando correções...');
    await fixCurrentUserProfile();

    // 3. Verificar visibilidade após correções
    print('\n3️⃣ Verificando visibilidade após correções...');
    final isNowVisible = await checkProfileVisibility();

    // 4. Resultado final
    print('\n' + '=' * 50);
    if (isNowVisible) {
      print('🎉 SUCESSO! Perfil agora está visível no Explorar Perfis!');
      print('📱 Teste agora: Toque no ícone 🔍 na barra superior');
    } else {
      print('⚠️ Perfil ainda não está visível. Pode ser necessário aguardar alguns minutos.');
    }
    print('=' * 50);
  }

  /// Método para compatibilidade com AutoProfileFixer
  static Future<void> autoFixIfNeeded() async {
    try {
      final isVisible = await checkProfileVisibility();
      if (!isVisible) {
        await fixCurrentUserProfile();
      }
    } catch (e) {
      print('⚠️ Erro durante correção automática: $e');
    }
  }
}