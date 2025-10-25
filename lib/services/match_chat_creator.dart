import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável por criar e gerenciar chats de match automaticamente
class MatchChatCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cria ou obtém um chat existente entre dois usuários
  /// Usa ID determinístico para evitar duplicados
  static Future<String> createOrGetChatId(
      String userId1, String userId2) async {
    try {
      // Gerar ID determinístico ordenando os IDs dos usuários
      final List<String> sortedIds = [userId1, userId2]..sort();
      final String chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

      print('🔍 Verificando chat existente: $chatId');

      // Verificar se o chat já existe
      final chatDoc =
          await _firestore.collection('match_chats').doc(chatId).get();

      if (chatDoc.exists) {
        print('✅ Chat já existe: $chatId');
        return chatId;
      }

      print('🚀 Criando novo chat: $chatId');

      // Criar novo chat com dados seguros
      final chatData = {
        'id': chatId,
        'user1Id': sortedIds[0],
        'user2Id': sortedIds[1],
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'lastMessageAt': null,
        'lastMessage': '',
        'isExpired': false,
        'unreadCount': {
          sortedIds[0]: 0,
          sortedIds[1]: 0,
        },
      };

      // Criar o documento do chat
      await _firestore.collection('match_chats').doc(chatId).set(chatData);

      print('✅ Chat criado com sucesso: $chatId');
      return chatId;
    } catch (e) {
      print('❌ Erro ao criar/obter chat: $e');

      // Tentar novamente com retry
      await Future.delayed(Duration(seconds: 1));
      return await _retryCreateChat(userId1, userId2);
    }
  }

  /// Retry automático para criação de chat
  static Future<String> _retryCreateChat(String userId1, String userId2,
      {int attempts = 0}) async {
    if (attempts >= 3) {
      throw Exception('Falha ao criar chat após 3 tentativas');
    }

    try {
      return await createOrGetChatId(userId1, userId2);
    } catch (e) {
      print('🔄 Tentativa ${attempts + 1} falhou, tentando novamente...');
      await Future.delayed(Duration(seconds: 2));
      return await _retryCreateChat(userId1, userId2, attempts: attempts + 1);
    }
  }

  /// Cria chat automaticamente quando há match mútuo
  static Future<String?> createChatOnMutualMatch(
      String fromUserId, String toUserId) async {
    try {
      print('💕 Criando chat para match mútuo: $fromUserId ↔ $toUserId');

      final chatId = await createOrGetChatId(fromUserId, toUserId);

      // Verificar se o chat foi criado corretamente
      final chatDoc =
          await _firestore.collection('match_chats').doc(chatId).get();

      if (chatDoc.exists) {
        print('✅ Chat de match mútuo criado: $chatId');
        return chatId;
      } else {
        print('❌ Falha na verificação do chat criado');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao criar chat de match mútuo: $e');
      return null;
    }
  }

  /// Verifica se um chat existe
  static Future<bool> chatExists(String userId1, String userId2) async {
    try {
      final List<String> sortedIds = [userId1, userId2]..sort();
      final String chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

      final chatDoc =
          await _firestore.collection('match_chats').doc(chatId).get();

      return chatDoc.exists;
    } catch (e) {
      print('❌ Erro ao verificar existência do chat: $e');
      return false;
    }
  }

  /// Obtém ID do chat sem criar
  static String getChatId(String userId1, String userId2) {
    final List<String> sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }
}
