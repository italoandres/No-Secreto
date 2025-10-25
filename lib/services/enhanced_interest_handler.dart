import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_data.dart';
import 'mutual_match_detector.dart';
import 'notification_orchestrator.dart';
import 'real_time_notification_service.dart';

/// Handler aprimorado para processar interesses e detectar matches mútuos
class EnhancedInterestHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Processa o envio de um interesse inicial
  static Future<String?> sendInterest({
    required String toUserId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    print('💕 [ENHANCED_INTEREST_HANDLER] Enviando interesse para $toUserId');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Usuário não autenticado');
      return null;
    }

    try {
      // Buscar dados do usuário atual
      final userData = await _getUserData(currentUser.uid);
      if (userData == null) {
        print('❌ [ENHANCED_INTEREST_HANDLER] Dados do usuário não encontrados');
        return null;
      }

      // Criar documento de interesse
      final interestData = {
        'fromUserId': currentUser.uid,
        'toUserId': toUserId,
        'type': 'interest',
        'status': 'pending',
        'message': message,
        'dataCriacao': Timestamp.now(),
        'dataResposta': null,
        'metadata': metadata ?? {},
      };

      // Salvar interesse no Firestore
      final interestDoc =
          await _firestore.collection('interests').add(interestData);

      print('✅ [ENHANCED_INTEREST_HANDLER] Interesse salvo: ${interestDoc.id}');

      // Criar notificação para o destinatário
      final notification = NotificationData(
        id: '',
        toUserId: toUserId,
        fromUserId: currentUser.uid,
        fromUserName: userData['nome'] ?? 'Usuário',
        fromUserEmail: userData['email'] ?? '',
        type: 'interest',
        message: message,
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'interestId': interestDoc.id,
          'originalMessage': message,
        },
      );

      await NotificationOrchestrator.createNotification(notification);

      print('✅ [ENHANCED_INTEREST_HANDLER] Notificação de interesse enviada');
      return interestDoc.id;
    } catch (e) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Erro ao enviar interesse: $e');
      return null;
    }
  }

  /// Processa a resposta a um interesse (aceitar/rejeitar)
  static Future<void> respondToInterest({
    required String notificationId,
    required String interestId,
    required String action, // 'accepted' ou 'rejected'
    String? responseMessage,
  }) async {
    print(
        '🔄 [ENHANCED_INTEREST_HANDLER] Processando resposta: $action para interesse $interestId');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Usuário não autenticado');
      return;
    }

    try {
      // Buscar o interesse original
      final interestDoc =
          await _firestore.collection('interests').doc(interestId).get();

      if (!interestDoc.exists) {
        print(
            '❌ [ENHANCED_INTEREST_HANDLER] Interesse não encontrado: $interestId');
        return;
      }

      final interestData = interestDoc.data()!;
      final fromUserId = interestData['fromUserId'] as String;
      final toUserId = interestData['toUserId'] as String;

      // Verificar se o usuário atual é o destinatário do interesse
      if (currentUser.uid != toUserId) {
        print(
            '❌ [ENHANCED_INTEREST_HANDLER] Usuário não autorizado a responder este interesse');
        return;
      }

      // Verificar se já foi respondido
      if (interestData['status'] != 'pending') {
        print(
            'ℹ️ [ENHANCED_INTEREST_HANDLER] Interesse já foi respondido anteriormente');
        // Não gerar erro, apenas ignorar silenciosamente
        return;
      }

      // Atualizar status do interesse
      await _firestore.collection('interests').doc(interestId).update({
        'status': action,
        'dataResposta': Timestamp.now(),
        'responseMessage': responseMessage,
      });

      print(
          '✅ [ENHANCED_INTEREST_HANDLER] Status do interesse atualizado para: $action');

      // Atualizar status da notificação
      await NotificationOrchestrator.handleNotificationResponse(
          notificationId, action);

      // Se foi aceito, verificar match mútuo
      if (action == 'accepted') {
        print(
            '💕 [ENHANCED_INTEREST_HANDLER] Interesse aceito, verificando match mútuo...');

        // Verificar se há match mútuo
        final hasMutualMatch =
            await MutualMatchDetector.checkMutualMatch(fromUserId, toUserId);

        if (hasMutualMatch) {
          print('🎉 [ENHANCED_INTEREST_HANDLER] MATCH MÚTUO DETECTADO!');

          // Verificar se já foi processado para evitar duplicatas
          final alreadyProcessed =
              await MutualMatchDetector.isMatchAlreadyProcessed(
                  fromUserId, toUserId);

          if (!alreadyProcessed) {
            // Criar notificações de match mútuo para ambos
            await MutualMatchDetector.createMutualMatchNotifications(
                fromUserId, toUserId);

            // Criar chat automaticamente
            await MutualMatchDetector.triggerChatCreation(fromUserId, toUserId);

            print(
                '🎉 [ENHANCED_INTEREST_HANDLER] Fluxo de match mútuo concluído com sucesso!');

            // IMPORTANTE: Retornar aqui para não criar notificação de interesse aceito
            return;
          } else {
            print(
                'ℹ️ [ENHANCED_INTEREST_HANDLER] Match mútuo já foi processado anteriormente');
            return;
          }
        } else {
          print(
              'ℹ️ [ENHANCED_INTEREST_HANDLER] Interesse aceito, mas ainda não é mútuo');

          // Criar notificação de interesse aceito para o remetente
          await _createInterestAcceptedNotification(
              fromUserId, toUserId, responseMessage);
        }
      } else {
        print('💔 [ENHANCED_INTEREST_HANDLER] Interesse rejeitado');

        // Opcionalmente, criar notificação de rejeição (ou não, dependendo da UX desejada)
        // await _createInterestRejectedNotification(fromUserId, toUserId);
      }
    } catch (e) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Erro ao processar resposta: $e');
      throw Exception('Erro ao processar resposta ao interesse: $e');
    }
  }

  /// Busca interesses enviados por um usuário
  static Future<List<Map<String, dynamic>>> getSentInterests(
      String userId) async {
    try {
      final query = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('dataCriacao', descending: true)
          .get();

      final interests = query.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      print(
          '📋 [ENHANCED_INTEREST_HANDLER] ${interests.length} interesses enviados encontrados');
      return interests;
    } catch (e) {
      print(
          '❌ [ENHANCED_INTEREST_HANDLER] Erro ao buscar interesses enviados: $e');
      return [];
    }
  }

  /// Busca interesses recebidos por um usuário
  static Future<List<Map<String, dynamic>>> getReceivedInterests(
      String userId) async {
    try {
      final query = await _firestore
          .collection('interests')
          .where('toUserId', isEqualTo: userId)
          .orderBy('dataCriacao', descending: true)
          .get();

      final interests = query.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      print(
          '📋 [ENHANCED_INTEREST_HANDLER] ${interests.length} interesses recebidos encontrados');
      return interests;
    } catch (e) {
      print(
          '❌ [ENHANCED_INTEREST_HANDLER] Erro ao buscar interesses recebidos: $e');
      return [];
    }
  }

  /// Verifica se já existe interesse entre dois usuários
  static Future<Map<String, dynamic>?> checkExistingInterest(
      String fromUserId, String toUserId) async {
    try {
      final query = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }

      return null;
    } catch (e) {
      print(
          '❌ [ENHANCED_INTEREST_HANDLER] Erro ao verificar interesse existente: $e');
      return null;
    }
  }

  /// Obtém estatísticas de interesses de um usuário
  static Future<Map<String, int>> getInterestStats(String userId) async {
    try {
      // Interesses enviados
      final sentQuery = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId)
          .get();

      // Interesses recebidos
      final receivedQuery = await _firestore
          .collection('interests')
          .where('toUserId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'sent_total': sentQuery.docs.length,
        'sent_pending': 0,
        'sent_accepted': 0,
        'sent_rejected': 0,
        'received_total': receivedQuery.docs.length,
        'received_pending': 0,
        'received_accepted': 0,
        'received_rejected': 0,
      };

      // Contar por status - enviados
      for (final doc in sentQuery.docs) {
        final status = doc.data()['status'] ?? 'pending';
        stats['sent_$status'] = (stats['sent_$status'] ?? 0) + 1;
      }

      // Contar por status - recebidos
      for (final doc in receivedQuery.docs) {
        final status = doc.data()['status'] ?? 'pending';
        stats['received_$status'] = (stats['received_$status'] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Cria notificação de interesse aceito (mas não mútuo)
  static Future<void> _createInterestAcceptedNotification(
      String toUserId, String fromUserId, String? responseMessage) async {
    try {
      final userData = await _getUserData(fromUserId);
      if (userData == null) return;

      final notification = NotificationData(
        id: '',
        toUserId: toUserId,
        fromUserId: fromUserId,
        fromUserName: userData['nome'] ?? 'Usuário',
        fromUserEmail: userData['email'] ?? '',
        type: 'interest_accepted',
        message: responseMessage ?? 'Seu interesse foi aceito! 💕',
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'responseType': 'accepted',
          'originalMessage': responseMessage,
        },
      );

      await NotificationOrchestrator.createNotification(notification);
      print(
          '✅ [ENHANCED_INTEREST_HANDLER] Notificação de interesse aceito criada');
    } catch (e) {
      print(
          '❌ [ENHANCED_INTEREST_HANDLER] Erro ao criar notificação de aceite: $e');
    }
  }

  /// Busca dados do usuário
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // Tentar na coleção usuarios primeiro
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data();
      }

      // Fallback para coleção users
      final fallbackDoc =
          await _firestore.collection('users').doc(userId).get();

      return fallbackDoc.exists ? fallbackDoc.data() : null;
    } catch (e) {
      print(
          '❌ [ENHANCED_INTEREST_HANDLER] Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  /// Limpa interesses antigos (mais de 30 dias sem resposta)
  static Future<void> cleanupOldInterests() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldInterests = await _firestore
          .collection('interests')
          .where('status', isEqualTo: 'pending')
          .where('dataCriacao', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldInterests.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      await batch.commit();

      print(
          '🧹 [ENHANCED_INTEREST_HANDLER] ${oldInterests.docs.length} interesses antigos marcados como expirados');
    } catch (e) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Erro na limpeza de interesses: $e');
    }
  }

  /// Testa o handler de interesses
  static Future<void> testEnhancedInterestHandler() async {
    print('🧪 [ENHANCED_INTEREST_HANDLER] Testando handler de interesses...');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Usuário não autenticado');
      return;
    }

    try {
      const testUserId = 'test_interest_user';

      // Teste 1: Enviar interesse
      final interestId = await sendInterest(
        toUserId: testUserId,
        message: 'Tenho interesse em você! 💕',
        metadata: {'testMode': true},
      );
      print('✅ Teste 1 - Interesse enviado: $interestId');

      // Teste 2: Buscar interesses enviados
      final sentInterests = await getSentInterests(currentUser.uid);
      print('✅ Teste 2 - Interesses enviados: ${sentInterests.length}');

      // Teste 3: Verificar interesse existente
      final existingInterest =
          await checkExistingInterest(currentUser.uid, testUserId);
      print('✅ Teste 3 - Interesse existente: ${existingInterest != null}');

      // Teste 4: Obter estatísticas
      final stats = await getInterestStats(currentUser.uid);
      print('✅ Teste 4 - Estatísticas: $stats');

      print('🎉 [ENHANCED_INTEREST_HANDLER] Todos os testes passaram!');
    } catch (e) {
      print('❌ [ENHANCED_INTEREST_HANDLER] Erro nos testes: $e');
    }
  }
}
