import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/accepted_match_model.dart';
import '../models/interest_notification_model.dart';

/// Repositório simplificado para matches aceitos que funciona sem índices complexos
class SimpleAcceptedMatchesRepository {
  final FirebaseFirestore _firestore;
  
  SimpleAcceptedMatchesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Busca matches aceitos usando método simples sem índices complexos
  Future<List<AcceptedMatchModel>> getAcceptedMatches(String userId) async {
    try {
      debugPrint('SimpleAcceptedMatchesRepository: Buscando matches aceitos para $userId');
      
      // Buscar notificações onde o usuário RECEBEU interesse (toUserId)
      final receivedNotifications = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      // Buscar notificações onde o usuário ENVIOU interesse (fromUserId)
      final sentNotifications = await _firestore
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .get();
      
      debugPrint('SimpleAcceptedMatchesRepository: Recebidas: ${receivedNotifications.docs.length}, Enviadas: ${sentNotifications.docs.length}');
      
      // Combinar todas as notificações
      final allDocs = [...receivedNotifications.docs, ...sentNotifications.docs];
      
      // Filtrar apenas as aceitas e remover duplicatas
      final seenIds = <String>{};
      final acceptedNotifications = allDocs
          .where((doc) {
            final data = doc.data();
            final id = doc.id;
            
            // Remover duplicatas
            if (seenIds.contains(id)) return false;
            seenIds.add(id);
            
            // Apenas aceitas
            return data['status'] == 'accepted';
          })
          .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      debugPrint('SimpleAcceptedMatchesRepository: Encontradas ${acceptedNotifications.length} notificações aceitas (sem duplicatas)');
      
      // Converter para AcceptedMatchModel
      final matches = <AcceptedMatchModel>[];
      
      for (final notification in acceptedNotifications) {
        try {
          final match = await _convertNotificationToMatch(notification, userId);
          if (match != null) {
            matches.add(match);
          }
        } catch (e) {
          debugPrint('SimpleAcceptedMatchesRepository: Erro ao converter notificação ${notification.id}: $e');
        }
      }
      
      // Ordenar por data de aceitação (mais recentes primeiro)
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
      
      debugPrint('SimpleAcceptedMatchesRepository: Retornando ${matches.length} matches aceitos');
      return matches;
      
    } catch (e) {
      debugPrint('SimpleAcceptedMatchesRepository: Erro ao buscar matches aceitos: $e');
      return [];
    }
  }
  
  /// Stream de matches aceitos usando método simples
  Stream<List<AcceptedMatchModel>> getAcceptedMatchesStream(String userId) async* {
    // Combinar streams de notificações recebidas e enviadas
    await for (final _ in _firestore
        .collection('interest_notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()) {
      
      // Buscar ambos os lados
      final receivedSnapshot = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      final sentSnapshot = await _firestore
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: userId)
          .get();
      
      // Combinar e filtrar
      final allDocs = [...receivedSnapshot.docs, ...sentSnapshot.docs];
      final seenIds = <String>{};
      
      final acceptedNotifications = allDocs
          .where((doc) {
            final data = doc.data();
            final id = doc.id;
            
            if (seenIds.contains(id)) return false;
            seenIds.add(id);
            
            return data['status'] == 'accepted';
          })
          .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      // Converter para AcceptedMatchModel
      final matches = <AcceptedMatchModel>[];
      
      for (final notification in acceptedNotifications) {
        try {
          final match = await _convertNotificationToMatch(notification, userId);
          if (match != null) {
            matches.add(match);
          }
        } catch (e) {
          debugPrint('SimpleAcceptedMatchesRepository: Erro no stream para notificação ${notification.id}: $e');
        }
      }
      
      // Ordenar por data de aceitação
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
      
      yield matches;
    }
  }
  
  /// Conta matches não lidos usando método simples
  Future<int> getUnreadMatchesCount(String userId) async {
    try {
      // Buscar todas as notificações e filtrar no código
      final allNotifications = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .get();
      
      // Contar apenas as aceitas e não lidas
      int count = 0;
      for (final doc in allNotifications.docs) {
        final data = doc.data();
        if (data['status'] == 'accepted' && (data['isRead'] == false || data['isRead'] == null)) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      debugPrint('SimpleAcceptedMatchesRepository: Erro ao contar matches não lidos: $e');
      return 0;
    }
  }
  
  /// Converte uma notificação de interesse em AcceptedMatchModel
  Future<AcceptedMatchModel?> _convertNotificationToMatch(
    InterestNotificationModel notification,
    String currentUserId,
  ) async {
    try {
      // Determinar o ID do outro usuário
      final otherUserId = notification.fromUserId == currentUserId
          ? notification.toUserId
          : notification.fromUserId;
      
      if (otherUserId == null) {
        debugPrint('SimpleAcceptedMatchesRepository: otherUserId é null');
        return null;
      }
      
      // Buscar dados do outro usuário da collection usuarios
      final otherUserDoc = await _firestore
          .collection('usuarios')
          .doc(otherUserId)
          .get();
      
      if (!otherUserDoc.exists) {
        debugPrint('SimpleAcceptedMatchesRepository: Usuário $otherUserId não encontrado');
        return null;
      }
      
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
      
      // Buscar dados do perfil espiritual para idade e cidade
      final profileQuery = await _firestore
          .collection('spiritual_profiles')
          .where('userId', isEqualTo: otherUserId)
          .limit(1)
          .get();
      
      Map<String, dynamic>? profileData;
      if (profileQuery.docs.isNotEmpty) {
        profileData = profileQuery.docs.first.data();
      }
      
      // Gerar ID único do chat
      final chatId = _generateChatId(currentUserId, otherUserId);
      
      // Calcular dias restantes e status de expiração
      final matchDate = notification.dataResposta?.toDate() ?? notification.dataCriacao?.toDate() ?? DateTime.now();
      final daysRemaining = 30 - DateTime.now().difference(matchDate).inDays;
      final chatExpired = daysRemaining <= 0;
      
      // Buscar contador de mensagens não lidas do chat (se existir)
      int unreadMessages = 0;
      try {
        final chatDoc = await _firestore
            .collection('match_chats')
            .doc(chatId)
            .get();
        
        if (chatDoc.exists) {
          final chatData = chatDoc.data() as Map<String, dynamic>;
          final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
          unreadMessages = unreadCount?[currentUserId] ?? 0;
        }
      } catch (e) {
        debugPrint('SimpleAcceptedMatchesRepository: Erro ao buscar mensagens não lidas: $e');
      }
      
      // Buscar idade e cidade do perfil espiritual (fonte primária)
      final int? age = profileData?['age'] as int?;
      final String? city = profileData?['city'] as String?;
      
      // Buscar foto do perfil da collection usuarios
      final String? photo = otherUserData['imgUrl'] as String?;
      
      debugPrint('🔍 [MATCH_DATA] Dados extraídos do usuário $otherUserId:');
      debugPrint('   Nome: ${otherUserData['nome']}');
      debugPrint('   Foto: $photo');
      debugPrint('   Idade: $age (de spiritual_profiles)');
      debugPrint('   Cidade: $city (de spiritual_profiles)');
      
      return AcceptedMatchModel.fromNotification(
        notificationId: notification.id!,
        otherUserId: otherUserId,
        otherUserName: otherUserData['nome'] ?? 'Usuário',
        otherUserPhoto: photo,
        otherUserAge: age,
        otherUserCity: city,
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: unreadMessages,
        chatExpired: chatExpired,
        daysRemaining: daysRemaining.clamp(0, 30),
      );
      
    } catch (e) {
      debugPrint('SimpleAcceptedMatchesRepository: Erro ao converter notificação: $e');
      return null;
    }
  }
  
  /// Gera ID único para o chat baseado nos IDs dos usuários
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }
}