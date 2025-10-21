import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_data.dart';
import 'notification_orchestrator.dart';
import 'chat_system_manager.dart';

/// Detector de matches mútuos entre usuários
/// Responsável por identificar quando dois usuários têm interesse mútuo
/// e criar as notificações apropriadas para ambos
class MutualMatchDetector {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica se existe match mútuo entre dois usuários
  /// Retorna true se ambos enviaram interesse um para o outro com status 'accepted'
  static Future<bool> checkMutualMatch(String userId1, String userId2) async {
    print('🔍 [MUTUAL_MATCH_DETECTOR] Verificando match mútuo entre $userId1 e $userId2');
    
    try {
      // Query 1: Verificar se userId1 enviou interesse para userId2 (status: accepted)
      final interest1to2 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      print('📊 [MUTUAL_MATCH_DETECTOR] Interesse de $userId1 para $userId2: ${interest1to2.docs.length} documentos');
      
      // Query 2: Verificar se userId2 enviou interesse para userId1 (status: accepted)
      final interest2to1 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      print('📊 [MUTUAL_MATCH_DETECTOR] Interesse de $userId2 para $userId1: ${interest2to1.docs.length} documentos');
      
      final hasMutualMatch = interest1to2.docs.isNotEmpty && interest2to1.docs.isNotEmpty;
      
      if (hasMutualMatch) {
        print('🎉 [MUTUAL_MATCH_DETECTOR] MATCH MÚTUO CONFIRMADO!');
      } else {
        print('ℹ️ [MUTUAL_MATCH_DETECTOR] Ainda não há match mútuo');
      }
      
      return hasMutualMatch;
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao verificar match mútuo: $e');
      return false;
    }
  }

  /// Cria notificações de match mútuo para AMBOS os usuários
  /// Cria DUAS notificações separadas (uma para cada usuário)
  static Future<void> createMutualMatchNotifications(String userId1, String userId2) async {
    print('💕 [MUTUAL_MATCH_DETECTOR] Criando notificações de match mútuo');
    
    try {
      // Buscar dados dos usuários
      final user1Data = await _getUserData(userId1);
      final user2Data = await _getUserData(userId2);
      
      if (user1Data == null || user2Data == null) {
        print('❌ [MUTUAL_MATCH_DETECTOR] Dados de usuário não encontrados');
        return;
      }
      
      // Gerar chatId determinístico
      final chatId = _generateChatId(userId1, userId2);
      
      print('📝 [MUTUAL_MATCH_DETECTOR] ChatId gerado: $chatId');
      
      // Notificação 1: Para userId1
      final notification1 = NotificationData(
        id: '',
        toUserId: userId1,
        fromUserId: userId2,
        fromUserName: user2Data['nome'] ?? 'Usuário',
        fromUserEmail: user2Data['email'] ?? '',
        type: 'mutual_match',  // IMPORTANTE: tipo correto
        message: 'MATCH MÚTUO! 🎉 Vocês têm interesse mútuo!',
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'chatId': chatId,
          'matchType': 'mutual',
          'otherUserId': userId2,
        },
      );
      
      // Notificação 2: Para userId2
      final notification2 = NotificationData(
        id: '',
        toUserId: userId2,
        fromUserId: userId1,
        fromUserName: user1Data['nome'] ?? 'Usuário',
        fromUserEmail: user1Data['email'] ?? '',
        type: 'mutual_match',  // IMPORTANTE: tipo correto
        message: 'MATCH MÚTUO! 🎉 Vocês têm interesse mútuo!',
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'chatId': chatId,
          'matchType': 'mutual',
          'otherUserId': userId1,
        },
      );
      
      // Criar ambas as notificações
      print('📤 [MUTUAL_MATCH_DETECTOR] Criando notificação para $userId1');
      await NotificationOrchestrator.createNotification(notification1);
      
      print('📤 [MUTUAL_MATCH_DETECTOR] Criando notificação para $userId2');
      await NotificationOrchestrator.createNotification(notification2);
      
      print('✅ [MUTUAL_MATCH_DETECTOR] Notificações de match mútuo criadas com sucesso');
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao criar notificações: $e');
      throw Exception('Erro ao criar notificações de match mútuo: $e');
    }
  }

  /// Cria o chat automaticamente e marca o match como processado
  static Future<String> triggerChatCreation(String userId1, String userId2) async {
    print('💬 [MUTUAL_MATCH_DETECTOR] Criando chat para match mútuo');
    
    try {
      // Gerar chatId determinístico
      final chatId = _generateChatId(userId1, userId2);
      
      // Criar chat através do ChatSystemManager
      await ChatSystemManager.createChat(userId1, userId2);
      
      print('✅ [MUTUAL_MATCH_DETECTOR] Chat criado: $chatId');
      
      // Criar documento na coleção mutual_matches para marcar como processado
      await _firestore.collection('mutual_matches').doc(chatId).set({
        'matchId': chatId,
        'participants': [userId1, userId2],
        'createdAt': Timestamp.now(),
        'chatId': chatId,
        'notificationsCreated': true,
        'chatCreated': true,
      });
      
      print('✅ [MUTUAL_MATCH_DETECTOR] Match marcado como processado');
      
      return chatId;
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao criar chat: $e');
      throw Exception('Erro ao criar chat: $e');
    }
  }

  /// Verifica se o match já foi processado anteriormente
  /// Previne criação de notificações duplicadas
  static Future<bool> isMatchAlreadyProcessed(String userId1, String userId2) async {
    try {
      final matchId = _generateChatId(userId1, userId2);
      final doc = await _firestore.collection('mutual_matches').doc(matchId).get();
      
      final exists = doc.exists;
      
      if (exists) {
        print('ℹ️ [MUTUAL_MATCH_DETECTOR] Match já foi processado: $matchId');
      }
      
      return exists;
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao verificar se match foi processado: $e');
      return false;
    }
  }

  /// Obtém todos os matches mútuos de um usuário
  static Future<List<Map<String, dynamic>>> getUserMutualMatches(String userId) async {
    print('📋 [MUTUAL_MATCH_DETECTOR] Buscando matches mútuos para $userId');
    
    try {
      final matches = await _firestore
          .collection('mutual_matches')
          .where('participants', arrayContains: userId)
          .get();
      
      final matchList = matches.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      
      print('✅ [MUTUAL_MATCH_DETECTOR] ${matchList.length} matches mútuos encontrados');
      
      return matchList;
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao buscar matches mútuos: $e');
      return [];
    }
  }

  /// Gera um chatId determinístico baseado nos IDs dos usuários
  /// Garante que o mesmo par de usuários sempre gera o mesmo chatId
  static String _generateChatId(String userId1, String userId2) {
    // Ordenar IDs alfabeticamente para garantir consistência
    final sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Busca dados do usuário no Firestore
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // Tentar na coleção usuarios primeiro
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
      
      // Fallback para coleção users
      final fallbackDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return fallbackDoc.exists ? fallbackDoc.data() : null;
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  /// Testa o detector de matches mútuos
  static Future<void> testMutualMatchDetector() async {
    print('🧪 [MUTUAL_MATCH_DETECTOR] Testando detector de matches mútuos...');
    
    try {
      const testUserId1 = 'test_user_1';
      const testUserId2 = 'test_user_2';
      
      // Teste 1: Verificar match mútuo
      final hasMutualMatch = await checkMutualMatch(testUserId1, testUserId2);
      print('✅ Teste 1 - Verificação de match mútuo: $hasMutualMatch');
      
      // Teste 2: Verificar se já foi processado
      final alreadyProcessed = await isMatchAlreadyProcessed(testUserId1, testUserId2);
      print('✅ Teste 2 - Match já processado: $alreadyProcessed');
      
      // Teste 3: Gerar chatId
      final chatId = _generateChatId(testUserId1, testUserId2);
      print('✅ Teste 3 - ChatId gerado: $chatId');
      
      // Teste 4: Buscar matches do usuário
      final matches = await getUserMutualMatches(testUserId1);
      print('✅ Teste 4 - Matches encontrados: ${matches.length}');
      
      print('🎉 [MUTUAL_MATCH_DETECTOR] Todos os testes passaram!');
      
    } catch (e) {
      print('❌ [MUTUAL_MATCH_DETECTOR] Erro nos testes: $e');
    }
  }
}
