import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// INVESTIGAÇÃO PROFUNDA - ENCONTRAR NOTIFICAÇÕES REAIS
class DeepInvestigationRealNotifications {
  
  /// Investigar TODAS as coleções possíveis onde podem estar as notificações reais
  static Future<void> investigateAllCollections() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ [INVESTIGATION] Usuário não logado');
      return;
    }

    final userId = currentUser.uid;
    print('🔍 [INVESTIGATION] Investigando notificações para userId: $userId');
    print('🔍 [INVESTIGATION] Email: ${currentUser.email}');

    // 1. Investigar coleção 'notifications'
    await _investigateNotifications(userId);
    
    // 2. Investigar coleção 'interests' (como no nosso propósito)
    await _investigateInterests(userId);
    
    // 3. Investigar coleção 'matches'
    await _investigateMatches(userId);
    
    // 4. Investigar coleção 'user_interests'
    await _investigateUserInterests(userId);
    
    // 5. Investigar coleção 'profile_interests'
    await _investigateProfileInterests(userId);
    
    // 6. Investigar subcoleções do usuário
    await _investigateUserSubcollections(userId);
    
    // 7. Investigar por username 'itala'
    await _investigateByUsername();
  }

  /// 1. Investigar coleção 'notifications'
  static Future<void> _investigateNotifications(String userId) async {
    print('\n🔍 [INVESTIGATION] === COLEÇÃO NOTIFICATIONS ===');
    
    try {
      // Buscar TODAS as notificações do usuário (sem filtro de tipo)
      final allNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 [INVESTIGATION] Total notifications encontradas: ${allNotifications.docs.length}');
      
      for (var doc in allNotifications.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Notification ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
      // Buscar também notificações que podem ter userId diferente
      final allNotificationsGeneral = await FirebaseFirestore.instance
          .collection('notifications')
          .limit(20)
          .get();
      
      print('📊 [INVESTIGATION] Total notifications gerais: ${allNotificationsGeneral.docs.length}');
      
      for (var doc in allNotificationsGeneral.docs) {
        final data = doc.data();
        if (data.toString().contains('itala') || data.toString().contains('italo')) {
          print('🎯 [INVESTIGATION] Notification com itala/italo: ${doc.id}');
          print('🎯 [INVESTIGATION] Data: $data');
          print('---');
        }
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar notifications: $e');
    }
  }

  /// 2. Investigar coleção 'interests' (inspirado no nosso propósito)
  static Future<void> _investigateInterests(String userId) async {
    print('\n🔍 [INVESTIGATION] === COLEÇÃO INTERESTS ===');
    
    try {
      // Buscar interesses onde o usuário é o alvo
      final interestsAsTarget = await FirebaseFirestore.instance
          .collection('interests')
          .where('targetUserId', isEqualTo: userId)
          .get();
      
      print('📊 [INVESTIGATION] Interests como alvo: ${interestsAsTarget.docs.length}');
      
      for (var doc in interestsAsTarget.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Interest ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
      // Buscar interesses onde o usuário demonstrou interesse
      final interestsAsSource = await FirebaseFirestore.instance
          .collection('interests')
          .where('sourceUserId', isEqualTo: userId)
          .get();
      
      print('📊 [INVESTIGATION] Interests como fonte: ${interestsAsSource.docs.length}');
      
      for (var doc in interestsAsSource.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Interest ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar interests: $e');
    }
  }

  /// 3. Investigar coleção 'matches'
  static Future<void> _investigateMatches(String userId) async {
    print('\n🔍 [INVESTIGATION] === COLEÇÃO MATCHES ===');
    
    try {
      final matches = await FirebaseFirestore.instance
          .collection('matches')
          .where('participants', arrayContains: userId)
          .get();
      
      print('📊 [INVESTIGATION] Matches encontrados: ${matches.docs.length}');
      
      for (var doc in matches.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Match ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar matches: $e');
    }
  }

  /// 4. Investigar coleção 'user_interests'
  static Future<void> _investigateUserInterests(String userId) async {
    print('\n🔍 [INVESTIGATION] === COLEÇÃO USER_INTERESTS ===');
    
    try {
      final userInterests = await FirebaseFirestore.instance
          .collection('user_interests')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 [INVESTIGATION] User interests: ${userInterests.docs.length}');
      
      for (var doc in userInterests.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] UserInterest ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar user_interests: $e');
    }
  }

  /// 5. Investigar coleção 'profile_interests'
  static Future<void> _investigateProfileInterests(String userId) async {
    print('\n🔍 [INVESTIGATION] === COLEÇÃO PROFILE_INTERESTS ===');
    
    try {
      final profileInterests = await FirebaseFirestore.instance
          .collection('profile_interests')
          .where('profileId', isEqualTo: userId)
          .get();
      
      print('📊 [INVESTIGATION] Profile interests: ${profileInterests.docs.length}');
      
      for (var doc in profileInterests.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] ProfileInterest ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar profile_interests: $e');
    }
  }

  /// 6. Investigar subcoleções do usuário
  static Future<void> _investigateUserSubcollections(String userId) async {
    print('\n🔍 [INVESTIGATION] === SUBCOLEÇÕES DO USUÁRIO ===');
    
    try {
      // Investigar users/{userId}/notifications
      final userNotifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      
      print('📊 [INVESTIGATION] User notifications: ${userNotifications.docs.length}');
      
      for (var doc in userNotifications.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] UserNotification ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
      // Investigar users/{userId}/interests
      final userInterestsSubcol = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('interests')
          .get();
      
      print('📊 [INVESTIGATION] User interests subcol: ${userInterestsSubcol.docs.length}');
      
      for (var doc in userInterestsSubcol.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] UserInterestSub ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar subcoleções: $e');
    }
  }

  /// 7. Investigar por username 'itala'
  static Future<void> _investigateByUsername() async {
    print('\n🔍 [INVESTIGATION] === BUSCA POR USERNAME ===');
    
    try {
      // Buscar usuário 'itala'
      final italaUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: 'itala')
          .get();
      
      print('📊 [INVESTIGATION] Usuários itala: ${italaUser.docs.length}');
      
      for (var doc in italaUser.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Itala User ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
      // Buscar usuário 'italo2'
      final italo2User = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: 'italo2')
          .get();
      
      print('📊 [INVESTIGATION] Usuários italo2: ${italo2User.docs.length}');
      
      for (var doc in italo2User.docs) {
        final data = doc.data();
        print('📄 [INVESTIGATION] Italo2 User ID: ${doc.id}');
        print('📄 [INVESTIGATION] Data: $data');
        print('---');
      }
      
    } catch (e) {
      print('❌ [INVESTIGATION] Erro ao investigar por username: $e');
    }
  }

  /// Executar investigação completa
  static Future<void> runCompleteInvestigation() async {
    print('🚀 [INVESTIGATION] INICIANDO INVESTIGAÇÃO COMPLETA...');
    print('🚀 [INVESTIGATION] Procurando notificações REAIS do @italo2 para @itala');
    print('=' * 60);
    
    await investigateAllCollections();
    
    print('=' * 60);
    print('🏁 [INVESTIGATION] INVESTIGAÇÃO COMPLETA FINALIZADA');
  }
}