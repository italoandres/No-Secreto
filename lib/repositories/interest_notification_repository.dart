import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import '../services/interest_cache_service.dart';
import '../services/match_chat_integrator.dart';
import '../utils/enhanced_logger.dart';

class InterestNotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'interest_notifications';
  static const String _usersCollection = 'usuarios';
  
  final InterestCacheService _cacheService = InterestCacheService();

  // ==================== CRIAR NOTIFICAÇÃO DE INTERESSE ====================

  /// Criar notificação de interesse (equivale a sendPartnershipInvite)
  static Future<void> createInterestNotification({
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserId,
    required String toUserEmail,
    String? message,
  }) async {
    try {
      print('💕 Criando notificação de interesse:');
      print('   De: $fromUserName ($fromUserId)');
      print('   Para: $toUserId');
      
      // Verificar se usuário destinatário existe
      final userDoc = await _firestore.collection(_usersCollection).doc(toUserId).get();
      if (!userDoc.exists) {
        throw Exception('Usuário destinatário não encontrado');
      }

      // Verificar se já existe interesse pendente
      final existing = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Você já demonstrou interesse neste perfil');
      }

      // Criar nova notificação
      final notification = InterestNotificationModel.interest(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: toUserId,
        toUserEmail: toUserEmail,
        message: message,
      );

      print('💾 Salvando notificação no Firestore:');
      print('   fromUserId: ${notification.fromUserId}');
      print('   toUserId: ${notification.toUserId}');
      print('   type: ${notification.type}');
      print('   status: ${notification.status}');
      print('   message: ${notification.message}');

      final docRef = await _firestore.collection(_collection).add(notification.toMap());
      
      print('✅ Notificação de interesse salva com ID: ${docRef.id}');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de interesse: $e');
      throw Exception('Erro ao demonstrar interesse: ${e.toString()}');
    }
  }

  // ==================== BUSCAR NOTIFICAÇÕES ====================

  /// Stream de notificações de interesse (equivale a getUserInvites)
  static Stream<List<InterestNotificationModel>> getUserInterestNotifications(String userId) {
    print('🔍 [REPO_STREAM] Iniciando stream de notificações para usuário: $userId');
    
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('📊 [REPO_STREAM] Total de documentos recebidos: ${snapshot.docs.length}');
          
          const validTypes = ['interest', 'acceptance', 'mutual_match'];
          const alwaysVisibleStatuses = ['pending', 'new', 'viewed'];
          const timedStatuses = ['accepted', 'rejected'];
          
          print('🔍 [REPO_STREAM] Tipos válidos: $validTypes');
          print('🔍 [REPO_STREAM] Status sempre visíveis: $alwaysVisibleStatuses');
          print('🔍 [REPO_STREAM] Status com tempo (7 dias): $timedStatuses');
          
          final now = DateTime.now();
          
          final notifications = snapshot.docs
              .map((doc) {
                final data = doc.data();
                final type = data['type'] ?? 'interest';
                final status = data['status'] ?? 'pending';
                
                print('   📋 [REPO_STREAM] Doc ID=${doc.id}');
                print('      - type: $type');
                print('      - status: $status');
                print('      - fromUserId: ${data['fromUserId']}');
                print('      - fromUserName: ${data['fromUserName']}');
                print('      - toUserId: ${data['toUserId']}');
                
                return InterestNotificationModel.fromMap({...data, 'id': doc.id});
              })
              .where((notification) {
                final isValidType = validTypes.contains(notification.type);
                final status = notification.status;
                
                if (!isValidType) {
                  print('   ❌ [REPO_STREAM] Notificação REJEITADA - tipo inválido: ${notification.type} (ID: ${notification.id})');
                  return false;
                }
                
                // Status sempre visíveis (pending, new, viewed)
                if (alwaysVisibleStatuses.contains(status)) {
                  print('   ✅ [REPO_STREAM] Notificação ACEITA (status sempre visível): ${notification.id}');
                  return true;
                }
                
                // Status com tempo (accepted, rejected) - visível por 7 dias
                if (timedStatuses.contains(status)) {
                  if (notification.dataResposta == null) {
                    print('   ⚠️ [REPO_STREAM] Notificação $status sem dataResposta: ${notification.id}');
                    return false;
                  }
                  
                  final responseDate = notification.dataResposta!.toDate();
                  final daysSinceResponse = now.difference(responseDate).inDays;
                  
                  print('      - dataResposta: $responseDate');
                  print('      - dias desde resposta: $daysSinceResponse');
                  
                  if (daysSinceResponse < 7) {
                    print('   ✅ [REPO_STREAM] Notificação ACEITA (dentro de 7 dias): ${notification.id}');
                    return true;
                  } else {
                    print('   ⏰ [REPO_STREAM] Notificação EXPIRADA (mais de 7 dias): ${notification.id}');
                    return false;
                  }
                }
                
                // Status desconhecido
                print('   ❌ [REPO_STREAM] Notificação REJEITADA - status desconhecido: $status (ID: ${notification.id})');
                return false;
              })
              .toList();
          
          print('✅ [REPO_STREAM] Total de notificações válidas retornadas: ${notifications.length}');
          
          // Ordenar manualmente por data (mais recente primeiro)
          notifications.sort((a, b) => b.dataCriacao!.compareTo(a.dataCriacao!));
          
          return notifications;
        });
  }

  /// Obter todas as notificações de interesse do usuário (incluindo respondidas)
  static Future<List<InterestNotificationModel>> getAllUserInterestNotifications(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .orderBy('dataCriacao', descending: true)
          .get();

      return query.docs
          .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar todas as notificações: $e');
      return [];
    }
  }

  /// Obter notificações recebidas (pendentes e visualizadas, mas não respondidas)
  static Future<List<InterestNotificationModel>> getReceivedInterestNotifications(String userId) async {
    try {
      print('🔍 [REPO] Buscando notificações recebidas para usuário: $userId');
      
      // Buscar todas as notificações do usuário primeiro
      final allQuery = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .orderBy('dataCriacao', descending: true)
          .get();
      
      print('📊 [REPO] Total de documentos encontrados: ${allQuery.docs.length}');
      
      // Tipos válidos de notificação
      const validTypes = ['interest', 'acceptance', 'mutual_match'];
      const validStatuses = ['pending', 'viewed', 'new'];
      
      print('🔍 [FILTER] Aplicando filtros...');
      print('   - Tipos válidos: $validTypes');
      print('   - Status válidos: $validStatuses');
      
      // Filtrar no código para evitar erro de índice
      final filteredDocs = allQuery.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final type = data['type'] ?? 'interest';
        
        final isValidStatus = validStatuses.contains(status);
        final isValidType = validTypes.contains(type);
        
        if (!isValidType) {
          print('⚠️ [FILTER] Notificação excluída - tipo inválido: $type (ID: ${doc.id})');
        }
        if (!isValidStatus) {
          print('⚠️ [FILTER] Notificação excluída - status inválido: $status (ID: ${doc.id})');
        }
        
        return isValidStatus && isValidType;
      }).toList();
      
      print('✅ [FILTER] Notificações válidas após filtro: ${filteredDocs.length}');
      
      final notifications = filteredDocs
          .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      print('📱 [UI] Retornando ${notifications.length} notificações para exibição');
      
      return notifications;
    } catch (e) {
      print('❌ [REPO] Erro ao buscar notificações recebidas: $e');
      
      // Fallback: usar método simples sem filtro complexo
      try {
        print('🔄 [FALLBACK] Tentando método alternativo...');
        final simpleQuery = await _firestore
            .collection(_collection)
            .where('toUserId', isEqualTo: userId)
            .get();
        
        const validTypes = ['interest', 'acceptance', 'mutual_match'];
        const validStatuses = ['pending', 'viewed', 'new'];
        
        final notifications = simpleQuery.docs
            .map((doc) => InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
            .where((notification) {
              final isValidStatus = validStatuses.contains(notification.status);
              final isValidType = validTypes.contains(notification.type);
              return isValidStatus && isValidType;
            })
            .toList();
        
        print('✅ [FALLBACK] Método alternativo funcionou: ${notifications.length} notificações');
        return notifications;
      } catch (fallbackError) {
        print('❌ [FALLBACK] Erro no método alternativo: $fallbackError');
        return [];
      }
    }
  }

  // ==================== RESPONDER A NOTIFICAÇÃO ====================

  /// Responder a notificação de interesse (equivale a respondToInviteWithAction)
  static Future<void> respondToInterestNotification(String notificationId, String action) async {
    try {
      print('💬 Respondendo à notificação $notificationId com ação: $action');
      
      final notificationDoc = await _firestore.collection(_collection).doc(notificationId).get();
      if (!notificationDoc.exists) {
        throw Exception('Notificação não encontrada');
      }

      final notification = InterestNotificationModel.fromMap({...notificationDoc.data()!, 'id': notificationDoc.id});
      
      if (!notification.isPending) {
        throw Exception('Esta notificação já foi respondida');
      }

      // Atualizar status da notificação
      await _firestore.collection(_collection).doc(notificationId).update({
        'status': action, // 'accepted', 'rejected'
        'dataResposta': Timestamp.now(),
      });

      print('✅ Notificação atualizada com status: $action');

      // Se aceito, criar notificação de aceitação e verificar match mútuo
      if (action == 'accepted') {
        await _createAcceptanceNotification(notification);
        await _handleMutualInterest(notification);
        await _createChatFromAcceptedInterest(notification);
      }
      
    } catch (e) {
      print('❌ Erro ao responder notificação: $e');
      throw Exception('Erro ao responder interesse: ${e.toString()}');
    }
  }

  // ==================== LÓGICA DE MATCH MÚTUO ====================

  /// Criar notificação de aceitação para quem enviou o interesse
  static Future<void> _createAcceptanceNotification(InterestNotificationModel notification) async {
    try {
      print('💕 Criando notificação de aceitação para ${notification.fromUserId}');
      
      // Buscar dados do usuário que aceitou
      final accepterDoc = await _firestore.collection(_usersCollection).doc(notification.toUserId).get();
      
      if (!accepterDoc.exists) {
        print('⚠️ Usuário que aceitou não foi encontrado');
        return;
      }
      
      final accepterData = accepterDoc.data()!;
      
      // Buscar dados do usuário que enviou o interesse
      final senderDoc = await _firestore.collection(_usersCollection).doc(notification.fromUserId).get();
      
      if (!senderDoc.exists) {
        print('⚠️ Usuário que enviou interesse não foi encontrado');
        return;
      }
      
      final senderData = senderDoc.data()!;
      
      // Criar notificação de aceitação
      await _firestore.collection(_collection).add({
        'fromUserId': notification.toUserId,
        'fromUserName': accepterData['nome'] ?? 'Usuário',
        'fromUserEmail': accepterData['email'] ?? '',
        'toUserId': notification.fromUserId,
        'toUserEmail': senderData['email'] ?? '',
        'type': 'acceptance',
        'message': 'Também tem interesse em você! 💕',
        'status': 'new',
        'dataCriacao': Timestamp.now(),
      });
      
      print('✅ Notificação de aceitação criada para ${notification.fromUserId}');
      
    } catch (e) {
      print('⚠️ Erro ao criar notificação de aceitação: $e');
      // Não lançar exceção para não impedir a resposta à notificação
    }
  }

  /// Verificar e tratar interesse mútuo
  static Future<void> _handleMutualInterest(InterestNotificationModel notification) async {
    try {
      print('💕 Verificando interesse mútuo entre ${notification.fromUserId} e ${notification.toUserId}');
      
      // Verificar se existe interesse mútuo (o destinatário também demonstrou interesse no remetente)
      final mutualInterest = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: notification.toUserId)
          .where('toUserId', isEqualTo: notification.fromUserId)
          .where('status', whereIn: ['accepted', 'pending'])
          .limit(1)
          .get();

      if (mutualInterest.docs.isNotEmpty) {
        print('💕💕 MATCH MÚTUO DETECTADO!');
        await _createMutualMatchNotifications(
          notification.fromUserId!,
          notification.toUserId!,
        );
      } else {
        print('💕 Interesse aceito, mas ainda não é mútuo');
      }
      
    } catch (e) {
      print('⚠️ Erro ao verificar interesse mútuo: $e');
      // Não lançar exceção para não impedir a resposta à notificação
    }
  }

  /// Criar notificações de match mútuo para ambos os usuários
  static Future<void> _createMutualMatchNotifications(String user1Id, String user2Id) async {
    try {
      print('💕💕 Criando notificações de MATCH MÚTUO!');
      
      // Buscar dados dos usuários
      final user1Doc = await _firestore.collection(_usersCollection).doc(user1Id).get();
      final user2Doc = await _firestore.collection(_usersCollection).doc(user2Id).get();
      
      if (!user1Doc.exists || !user2Doc.exists) {
        print('⚠️ Um dos usuários não foi encontrado');
        return;
      }
      
      final user1Data = user1Doc.data()!;
      final user2Data = user2Doc.data()!;
      
      // Notificação para user1
      await _firestore.collection(_collection).add({
        'fromUserId': user2Id,
        'fromUserName': user2Data['nome'] ?? 'Usuário',
        'fromUserEmail': user2Data['email'] ?? '',
        'toUserId': user1Id,
        'toUserEmail': user1Data['email'] ?? '',
        'type': 'mutual_match',
        'message': 'MATCH MÚTUO! Vocês dois demonstraram interesse! 🎉💕',
        'status': 'new',
        'dataCriacao': Timestamp.now(),
      });
      
      // Notificação para user2
      await _firestore.collection(_collection).add({
        'fromUserId': user1Id,
        'fromUserName': user1Data['nome'] ?? 'Usuário',
        'fromUserEmail': user1Data['email'] ?? '',
        'toUserId': user2Id,
        'toUserEmail': user2Data['email'] ?? '',
        'type': 'mutual_match',
        'message': 'MATCH MÚTUO! Vocês dois demonstraram interesse! 🎉💕',
        'status': 'new',
        'dataCriacao': Timestamp.now(),
      });
      
      print('✅ Notificações de match mútuo criadas para ambos os usuários');
      
    } catch (e) {
      print('⚠️ Erro ao criar notificações de match mútuo: $e');
    }
  }

  /// Criar chat automaticamente quando interesse é aceito
  static Future<void> _createChatFromAcceptedInterest(InterestNotificationModel notification) async {
    try {
      print('🚀 Criando chat a partir de interesse aceito');
      
      // Gerar ID único do chat
      final sortedIds = [notification.fromUserId!, notification.toUserId!]..sort();
      final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';
      
      // Verificar se o chat já existe
      final chatDoc = await _firestore.collection('match_chats').doc(chatId).get();
      if (chatDoc.exists) {
        print('ℹ️ Chat já existe: $chatId');
        return;
      }

      // Criar o chat no Firebase
      await _firestore.collection('match_chats').doc(chatId).set({
        'user1Id': sortedIds[0],
        'user2Id': sortedIds[1],
        'createdAt': Timestamp.now(),
        'lastMessage': 'Chat criado a partir de interesse aceito!',
        'lastMessageAt': Timestamp.now(),
        'isExpired': false,
        'unreadCount': {
          notification.fromUserId!: 0,
          notification.toUserId!: 0,
        },
      });

      // Adicionar mensagem de boas-vindas
      await _firestore.collection('chat_messages').add({
        'chatId': chatId,
        'senderId': 'system',
        'senderName': 'Sistema',
        'message': '🎉 Vocês têm um match! Aproveitem para se conhecer melhor! 💕',
        'timestamp': Timestamp.now(),
        'type': 'system',
        'isRead': false,
      });

      print('✅ Chat criado com sucesso: $chatId');

    } catch (e) {
      print('❌ Erro ao criar chat a partir de interesse aceito: $e');
      // Não lançar exceção para não impedir a resposta à notificação
    }
  }

  // ==================== VALIDAÇÕES E UTILITÁRIOS ====================

  /// Verificar se usuário já demonstrou interesse
  static Future<bool> hasUserShownInterest(String fromUserId, String toUserId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar interesse existente: $e');
      return false;
    }
  }

  /// Contar notificações não lidas
  static Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs.length;
    } catch (e) {
      print('❌ Erro ao contar notificações não lidas: $e');
      return 0;
    }
  }

  /// Stream do contador de notificações não lidas
  static Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== BUSCA DE USUÁRIOS ====================

  /// Buscar usuário por ID (para navegação de perfil)
  static Future<UsuarioModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data()!;
      data['id'] = userDoc.id;
      return UsuarioModel.fromJson(data);
    } catch (e) {
      print('❌ Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  // ==================== LIMPEZA E MANUTENÇÃO ====================

  /// Limpar notificações antigas (mais de 30 dias)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
      
      final query = await _firestore
          .collection(_collection)
          .where('dataCriacao', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ ${query.docs.length} notificações antigas foram removidas');
      
    } catch (e) {
      print('⚠️ Erro ao limpar notificações antigas: $e');
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Obter estatísticas de interesse do usuário
  static Future<Map<String, int>> getUserInterestStats(String userId) async {
    try {
      // Interesses enviados
      final sentQuery = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .get();

      // Interesses recebidos
      final receivedQuery = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .get();

      // Interesses aceitos (que o usuário enviou)
      final acceptedSentQuery = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // Interesses aceitos (que o usuário recebeu)
      final acceptedReceivedQuery = await _firestore
          .collection(_collection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      return {
        'sent': sentQuery.docs.length,
        'received': receivedQuery.docs.length,
        'acceptedSent': acceptedSentQuery.docs.length,
        'acceptedReceived': acceptedReceivedQuery.docs.length,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
      return {
        'sent': 0,
        'received': 0,
        'acceptedSent': 0,
        'acceptedReceived': 0,
      };
    }
  }
}