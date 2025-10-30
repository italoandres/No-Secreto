import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/models/purpose_invite_model.dart';
import 'package:whatsapp_chat/models/purpose_partnership_model.dart';
import 'package:whatsapp_chat/models/purpose_chat_model.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';

class PurposePartnershipRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleções
  static const String _invitesCollection = 'purpose_invites';
  static const String _partnershipsCollection = 'purpose_partnerships';
  static const String _chatsCollection = 'purpose_chats';
  static const String _usersCollection = 'usuarios';
  static const String _blockedUsersCollection = 'blocked_users';

  // ==================== INICIALIZAÇÃO ====================

  /// Inicializar coleções do Firebase (executar uma vez)
  static Future<void> initializeCollections() async {
    try {
      // Verificar se as coleções existem criando documentos de exemplo (serão removidos)
      await _ensureCollectionExists(_invitesCollection);
      await _ensureCollectionExists(_partnershipsCollection);
      await _ensureCollectionExists(_chatsCollection);
      await _ensureCollectionExists(_blockedUsersCollection);

      print('✅ Coleções do Firebase inicializadas com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar coleções: $e');
    }
  }

  /// Garantir que uma coleção existe
  static Future<void> _ensureCollectionExists(String collectionName) async {
    try {
      final query = await _firestore.collection(collectionName).limit(1).get();
      if (query.docs.isEmpty) {
        // Criar documento temporário para inicializar a coleção
        final tempDoc = await _firestore.collection(collectionName).add({
          '_temp': true,
          'createdAt': Timestamp.now(),
        });
        // Remover documento temporário
        await tempDoc.delete();
        print('📁 Coleção $collectionName inicializada');
      }
    } catch (e) {
      print('⚠️ Erro ao inicializar coleção $collectionName: $e');
    }
  }

  /// Verificar saúde das coleções
  static Future<Map<String, bool>> checkCollectionsHealth() async {
    final health = <String, bool>{};

    try {
      // Testar acesso a cada coleção
      health[_invitesCollection] =
          await _testCollectionAccess(_invitesCollection);
      health[_partnershipsCollection] =
          await _testCollectionAccess(_partnershipsCollection);
      health[_chatsCollection] = await _testCollectionAccess(_chatsCollection);
      health[_blockedUsersCollection] =
          await _testCollectionAccess(_blockedUsersCollection);
      health[_usersCollection] = await _testCollectionAccess(_usersCollection);
    } catch (e) {
      print('❌ Erro ao verificar saúde das coleções: $e');
    }

    return health;
  }

  /// Testar acesso a uma coleção
  static Future<bool> _testCollectionAccess(String collectionName) async {
    try {
      await _firestore.collection(collectionName).limit(1).get();
      return true;
    } catch (e) {
      print('❌ Erro ao acessar coleção $collectionName: $e');
      return false;
    }
  }

  // ==================== CONVITES ====================

  /// Enviar convite de parceria com mensagem personalizada
  static Future<void> sendPartnershipInviteWithMessage(
      String toUserEmail, String message, UsuarioModel fromUser) async {
    try {
      // Verificar se usuário de destino existe
      final userQuery = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: toUserEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Usuário não encontrado com este email');
      }

      final doc = userQuery.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Adicionar o ID do documento
      final toUser = UsuarioModel.fromJson(data);

      print('🎯 Debug toUser criado:');
      print('   toUser.id: ${toUser.id}');
      print('   toUser.email: ${toUser.email}');
      print('   toUser.nome: ${toUser.nome}');

      // Verificar se não é do mesmo sexo
      if (toUser.sexo == fromUser.sexo) {
        throw Exception('Não é possível adicionar pessoa do mesmo sexo');
      }

      // Verificar se IDs não são nulos
      if (fromUser.id == null || toUser.id == null) {
        throw Exception('IDs de usuário inválidos');
      }

      // Verificar se usuário está bloqueado
      final isBlocked = await isUserBlocked(fromUser.id!, toUser.id!);
      if (isBlocked) {
        throw Exception('Não é possível enviar convite para este usuário');
      }

      // Verificar se já existe convite pendente
      final existingInvite = await _firestore
          .collection(_invitesCollection)
          .where('fromUserId', isEqualTo: fromUser.id)
          .where('toUserId', isEqualTo: toUser.id)
          .where('type', isEqualTo: 'partnership')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        throw Exception('Convite já foi enviado para este usuário');
      }

      // Verificar se usuário já tem parceiro
      final existingPartnership = await getUserPartnership(fromUser.id!);
      if (existingPartnership != null &&
          existingPartnership.isActivePartnership) {
        throw Exception('Você já possui um(a) parceiro(a) conectado');
      }

      // Verificar se nomes não são nulos
      if (fromUser.nome == null || fromUser.nome!.isEmpty) {
        throw Exception('Nome do usuário remetente é obrigatório');
      }

      // Criar convite com mensagem personalizada
      final invite = PurposeInviteModel(
        fromUserId: fromUser.id!,
        fromUserName: fromUser.nome!,
        toUserId: toUser.id!,
        toUserEmail: toUserEmail,
        type: 'partnership',
        message: message,
        status: 'pending',
        dataCriacao: Timestamp.now(),
      );

      print('💾 Salvando convite no Firestore:');
      print('   fromUserId: ${invite.fromUserId}');
      print('   toUserId: ${invite.toUserId}');
      print('   type: ${invite.type}');
      print('   status: ${invite.status}');
      print('   message: ${invite.message}');

      final docRef =
          await _firestore.collection(_invitesCollection).add(invite.toMap());

      print('✅ Convite salvo com ID: ${docRef.id}');
    } catch (e) {
      throw Exception('Erro ao enviar convite: ${e.toString()}');
    }
  }

  /// Enviar convite de parceria
  static Future<void> sendPartnershipInvite(
      String toUserEmail, UsuarioModel fromUser) async {
    try {
      // Verificar se usuário de destino existe
      final userQuery = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: toUserEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Usuário não encontrado com este email');
      }

      final doc = userQuery.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Adicionar o ID do documento
      final toUser = UsuarioModel.fromJson(data);

      // Verificar se usuário está bloqueado
      final isBlocked = await isUserBlocked(fromUser.id!, toUser.id!);
      if (isBlocked) {
        throw Exception('Não é possível enviar convite para este usuário');
      }

      // Verificar se já existe convite pendente
      final existingInvite = await _firestore
          .collection(_invitesCollection)
          .where('fromUserId', isEqualTo: fromUser.id)
          .where('toUserId', isEqualTo: toUser.id)
          .where('type', isEqualTo: 'partnership')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        throw Exception('Convite já foi enviado para este usuário');
      }

      // Verificar se usuário já tem parceiro
      final existingPartnership = await getUserPartnership(fromUser.id!);
      if (existingPartnership != null &&
          existingPartnership.isActivePartnership) {
        throw Exception('Você já possui um(a) parceiro(a) conectado');
      }

      // Criar convite
      final invite = PurposeInviteModel.partnership(
        fromUserId: fromUser.id!,
        fromUserName: fromUser.nome!,
        toUserEmail: toUserEmail,
      );

      await _firestore.collection(_invitesCollection).add(invite.toMap());
    } catch (e) {
      throw Exception('Erro ao enviar convite: ${e.toString()}');
    }
  }

  /// Enviar convite de menção
  static Future<void> sendMentionInvite(
      String toUserId, String message, UsuarioModel fromUser) async {
    try {
      // Verificar se usuário de destino existe
      final userDoc =
          await _firestore.collection(_usersCollection).doc(toUserId).get();
      if (!userDoc.exists) {
        throw Exception('Usuário não encontrado');
      }

      // Verificar se já existe convite pendente
      final existingInvite = await _firestore
          .collection(_invitesCollection)
          .where('fromUserId', isEqualTo: fromUser.id)
          .where('toUserId', isEqualTo: toUserId)
          .where('type', isEqualTo: 'mention')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        throw Exception('Convite de menção já foi enviado para este usuário');
      }

      // Criar convite de menção
      final invite = PurposeInviteModel.mention(
        fromUserId: fromUser.id!,
        fromUserName: fromUser.nome!,
        toUserId: toUserId,
        message: message,
      );

      await _firestore.collection(_invitesCollection).add(invite.toMap());
    } catch (e) {
      throw Exception('Erro ao enviar convite de menção: ${e.toString()}');
    }
  }

  /// Obter convites do usuário
  static Stream<List<PurposeInviteModel>> getUserInvites(String userId) {
    print('🔍 Buscando convites para usuário: $userId');

    return _firestore
        .collection(_invitesCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      print('📨 Encontrados ${snapshot.docs.length} convites pendentes');

      final invites = snapshot.docs.map((doc) {
        print('   📋 Convite: ${doc.data()}');
        return PurposeInviteModel.fromFirestore(doc);
      }).toList();

      // Ordenar manualmente por data (mais recente primeiro)
      invites.sort((a, b) => b.dataCriacao!.compareTo(a.dataCriacao!));

      return invites;
    });
  }

  /// Responder a convite com ação específica (método principal)
  static Future<void> respondToInviteWithAction(
      String inviteId, String action) async {
    try {
      final inviteDoc =
          await _firestore.collection(_invitesCollection).doc(inviteId).get();
      if (!inviteDoc.exists) {
        throw Exception('Convite não encontrado');
      }

      final invite = PurposeInviteModel.fromFirestore(inviteDoc);

      if (!invite.isPending) {
        throw Exception('Este convite já foi respondido');
      }

      // Atualizar status do convite
      await _firestore.collection(_invitesCollection).doc(inviteId).update({
        'status': action,
        'dataResposta': Timestamp.now(),
      });

      // Se aceito e é convite de parceria, criar parceria
      if (action == 'accepted' && invite.isPartnership) {
        await _createPartnershipFromInvite(invite);
      }

      // Se aceito e é convite de menção, adicionar ao chat
      if (action == 'accepted' && invite.isMention) {
        await _addUserToMentionChat(invite);
      }

      // Se bloqueado, adicionar à lista de bloqueados
      if (action == 'blocked') {
        await _addToBlockedList(invite.fromUserId!, invite.toUserId!);
      }
    } catch (e) {
      throw Exception('Erro ao responder convite: ${e.toString()}');
    }
  }

  /// Responder a convite (método legado para compatibilidade)
  static Future<void> respondToInvite(String inviteId, bool accepted,
      {bool blocked = false}) async {
    final action = blocked ? 'blocked' : (accepted ? 'accepted' : 'rejected');
    await respondToInviteWithAction(inviteId, action);
  }

  // ==================== PARCERIAS ====================

  /// Obter parceria do usuário
  static Future<PurposePartnershipModel?> getUserPartnership(
      String userId) async {
    try {
      print('🔍 Buscando parceria para usuário: $userId');

      // Verificar se userId não está vazio
      if (userId.isEmpty) {
        print('❌ UserId está vazio');
        return null;
      }

      final query = await _firestore
          .collection(_partnershipsCollection)
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      print('📊 Encontradas ${query.docs.length} parcerias ativas');

      for (var doc in query.docs) {
        try {
          final partnership = PurposePartnershipModel.fromFirestore(doc);
          if (partnership.includesUser(userId)) {
            print('✅ Parceria encontrada: ${partnership.id}');
            return partnership;
          }
        } catch (docError) {
          print('⚠️ Erro ao processar documento ${doc.id}: $docError');
          continue;
        }
      }

      print('📭 Nenhuma parceria encontrada para o usuário');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar parceria: $e');
      // Retornar null em vez de lançar exceção para não quebrar a UI
      return null;
    }
  }

  /// Criar parceria
  static Future<void> createPartnership(String user1Id, String user2Id) async {
    try {
      final chatId = PurposePartnershipModel.generateChatId(user1Id, user2Id);

      final partnership = PurposePartnershipModel.create(
        user1Id: user1Id,
        user2Id: user2Id,
        chatId: chatId,
      );

      await _firestore
          .collection(_partnershipsCollection)
          .add(partnership.toMap());

      // Enviar mensagens automáticas do Pai assim que a parceria for criada
      await _sendWelcomeMessagesFromFather(chatId, [user1Id, user2Id]);
    } catch (e) {
      throw Exception('Erro ao criar parceria: ${e.toString()}');
    }
  }

  /// Enviar mensagens de boas-vindas do Pai para nova parceria
  static Future<void> _sendWelcomeMessagesFromFather(
      String chatId, List<String> participantIds) async {
    try {
      // Mensagens específicas do Pai para o chat "Nosso Propósito"
      final messages = [
        'Meus filhos, que alegria ver vocês aqui escolhendo caminhar juntos no Meu propósito.',
        'Não é por acaso que seus caminhos se cruzaram.',
        'Lembrem-se: o propósito não é apenas sobre o que vocês sentirão um pelo outro, mas sobre o que juntos vão refletir de Mim ao mundo.',
        'Haverá momentos de dúvidas, distrações e vontades próprias, mas se Me ouvirem e se sustentarem na Minha Palavra, Eu serei a rocha firme entre vocês.',
        'Peçam sinais quando precisarem, consultem-Me antes de cada decisão, e Eu estarei aqui para guiar cada passo.',
        'Sejam fiéis ao processo, e vocês verão que há um propósito maior do que simplesmente estarem juntos: um destino e serem Um, em Mim.',
      ];

      // Enviar cada mensagem com um pequeno delay para manter a ordem
      for (int i = 0; i < messages.length; i++) {
        final message = PurposeChatModel.adminMessage(
          chatId: chatId,
          participantIds: participantIds,
          text: messages[i],
        );

        await _firestore.collection(_chatsCollection).add(message.toMap());

        // Pequeno delay entre mensagens para garantir ordem cronológica
        if (i < messages.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('✅ Mensagens de boas-vindas do Pai enviadas para o chat $chatId');
    } catch (e) {
      print('⚠️ Erro ao enviar mensagens de boas-vindas: $e');
      // Não lançar exceção para não impedir a criação da parceria
    }
  }

  /// Desconectar parceria
  static Future<void> disconnectPartnership(String partnershipId) async {
    try {
      final partnershipDoc = await _firestore
          .collection(_partnershipsCollection)
          .doc(partnershipId)
          .get();
      if (!partnershipDoc.exists) {
        throw Exception('Parceria não encontrada');
      }

      final partnership = PurposePartnershipModel.fromFirestore(partnershipDoc);

      // Limpar mensagens do chat antes de desconectar
      if (partnership.chatId != null) {
        await _clearChatMessages(partnership.chatId!);
      }

      final disconnectedPartnership = partnership.disconnect();

      await _firestore
          .collection(_partnershipsCollection)
          .doc(partnershipId)
          .update(disconnectedPartnership.toMap());
    } catch (e) {
      throw Exception('Erro ao desconectar parceria: ${e.toString()}');
    }
  }

  /// Limpar todas as mensagens de um chat
  static Future<void> _clearChatMessages(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .where('chatId', isEqualTo: chatId)
          .get();

      // Deletar todas as mensagens em batch
      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
          '✅ ${messagesQuery.docs.length} mensagens do chat $chatId foram removidas');
    } catch (e) {
      print('⚠️ Erro ao limpar mensagens do chat: $e');
      // Não lançar exceção para não impedir a desconexão da parceria
    }
  }

  // ==================== CHAT COMPARTILHADO ====================

  /// Obter mensagens do chat compartilhado
  static Stream<List<PurposeChatModel>> getSharedChat(String chatId) {
    print('💬 Buscando mensagens do chat: $chatId');

    return _firestore
        .collection(_chatsCollection)
        .where('chatId', isEqualTo: chatId)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      print('📨 Encontradas ${snapshot.docs.length} mensagens no chat');

      final messages = snapshot.docs
          .map((doc) => PurposeChatModel.fromFirestore(doc))
          .toList();

      // Ordenar manualmente por data (mais recente primeiro)
      messages.sort((a, b) => b.dataCadastro!.compareTo(a.dataCadastro!));

      return messages;
    });
  }

  /// Enviar mensagem no chat compartilhado
  static Future<void> sendSharedMessage(
      String chatId, String message, List<String> participantIds,
      {String? mentionedUserId}) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Buscar o nome e sexo do usuário no Firestore
      String currentUserName = 'Usuário';
      String currentUserSexo = 'none';
      try {
        final userDoc = await _firestore
            .collection(_usersCollection)
            .doc(currentUserId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          currentUserName = userData['nome'] ??
              FirebaseAuth.instance.currentUser!.displayName ??
              'Usuário';
          currentUserSexo = userData['sexo'] ?? 'none';
        }
      } catch (e) {
        print('Erro ao buscar dados do usuário: $e');
        currentUserName =
            FirebaseAuth.instance.currentUser!.displayName ?? 'Usuário';
      }

      final chatMessage = PurposeChatModel.coupleMessage(
        chatId: chatId,
        participantIds: participantIds,
        autorId: currentUserId,
        autorNome: currentUserName,
        autorSexo: currentUserSexo,
        text: message,
        mentionedUserId: mentionedUserId,
      );

      await _firestore.collection(_chatsCollection).add(chatMessage.toMap());
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  /// Enviar mensagem de admin
  static Future<void> sendAdminMessage(
      String chatId, String message, List<String> participantIds) async {
    try {
      final chatMessage = PurposeChatModel.adminMessage(
        chatId: chatId,
        participantIds: participantIds,
        text: message,
      );

      await _firestore.collection(_chatsCollection).add(chatMessage.toMap());
    } catch (e) {
      throw Exception('Erro ao enviar mensagem de admin: ${e.toString()}');
    }
  }

  // ==================== BUSCA DE USUÁRIOS ====================

  /// Buscar usuário por email
  static Future<UsuarioModel?> searchUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Adicionar o ID do documento
      return UsuarioModel.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao buscar usuário: ${e.toString()}');
    }
  }

  /// Buscar usuários por username (para @menções)
  static Future<List<UsuarioModel>> searchUsersByName(String username) async {
    try {
      print('🔍 Buscando usuários por username: $username');

      // Primeiro, vamos ver quantos usuários existem no total
      final allUsersQuery =
          await _firestore.collection(_usersCollection).limit(5).get();

      print('📊 Total de usuários no banco: ${allUsersQuery.docs.length}');
      for (var doc in allUsersQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Adicionar o ID do documento
        final user = UsuarioModel.fromJson(data);
        print(
            '   - ${user.nome} (@${user.username ?? 'sem_username'}) - ID: ${user.id}');
      }

      // Buscar por username primeiro
      final usernameQuery = await _firestore
          .collection(_usersCollection)
          .where('username', isGreaterThanOrEqualTo: username.toLowerCase())
          .where('username',
              isLessThanOrEqualTo: username.toLowerCase() + '\uf8ff')
          .limit(10)
          .get();

      List<UsuarioModel> users = usernameQuery.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Adicionar o ID do documento
            final user = UsuarioModel.fromJson(data);
            print(
                '   👤 Usuário por username: ${user.nome} (@${user.username}) - ID: ${user.id}');
            return user;
          })
          .where((user) =>
                  user.id !=
                      FirebaseAuth
                          .instance.currentUser?.uid && // Excluir usuário atual
                  user.username != null &&
                  user.username!.isNotEmpty // Só usuários com username
              )
          .toList();

      print('📊 Encontrados ${users.length} usuários com username válidos');

      // Se não encontrou por username, vamos tentar uma busca mais ampla
      if (users.isEmpty) {
        print('🔄 Tentando busca mais ampla por nome que contenha: $username');
        final broadQuery =
            await _firestore.collection(_usersCollection).limit(20).get();

        final filteredUsers = broadQuery.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Adicionar o ID do documento
              return UsuarioModel.fromJson(data);
            })
            .where((user) =>
                user.id != FirebaseAuth.instance.currentUser?.uid &&
                user.nome != null &&
                user.nome!.toLowerCase().contains(username.toLowerCase()))
            .take(5)
            .toList();

        users.addAll(filteredUsers);
        print(
            '📊 Encontrados ${filteredUsers.length} usuários por busca ampla');
      }

      // Se não encontrou por username, buscar por nome como fallback
      if (users.isEmpty) {
        print('🔄 Buscando por nome como fallback');
        final nameQuery = await _firestore
            .collection(_usersCollection)
            .where('nome', isGreaterThanOrEqualTo: username)
            .where('nome', isLessThanOrEqualTo: username + '\uf8ff')
            .limit(5)
            .get();

        users = nameQuery.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Adicionar o ID do documento
              final user = UsuarioModel.fromJson(data);
              print(
                  '   👤 Usuário por nome: ${user.nome} - ID: ${user.id} - Email: ${user.email}');
              return user;
            })
            .where((user) => user.id != FirebaseAuth.instance.currentUser?.uid)
            .toList();

        print('📊 Encontrados ${users.length} usuários por nome');
      }

      // Debug final dos usuários retornados
      print('🎯 Usuários finais retornados:');
      for (var user in users) {
        print(
            '   - ${user.nome} (@${user.username ?? 'sem_username'}) - ID: ${user.id}');
      }

      return users;
    } catch (e) {
      print('❌ Erro ao buscar usuários: $e');
      return [];
    }
  }

  // ==================== LISTA DE BLOQUEADOS ====================

  /// Adicionar usuário à lista de bloqueados
  static Future<void> _addToBlockedList(
      String blockedUserId, String blockerUserId) async {
    try {
      await _firestore.collection('blocked_users').add({
        'blockedUserId': blockedUserId,
        'blockerUserId': blockerUserId,
        'dataBlocked': Timestamp.now(),
      });
    } catch (e) {
      print('Erro ao adicionar à lista de bloqueados: $e');
    }
  }

  /// Bloquear usuário (método público)
  static Future<void> blockUser(String blockedUserId, String inviteId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Atualizar convite para status 'blocked'
      await _firestore.collection(_invitesCollection).doc(inviteId).update({
        'status': 'blocked',
        'dataResposta': Timestamp.now(),
      });

      // Adicionar à lista de bloqueados
      await _addToBlockedList(blockedUserId, currentUserId);
    } catch (e) {
      throw Exception('Erro ao bloquear usuário: ${e.toString()}');
    }
  }

  /// Verificar se usuário está bloqueado
  static Future<bool> isUserBlocked(String fromUserId, String toUserId) async {
    try {
      final query = await _firestore
          .collection('blocked_users')
          .where('blockedUserId', isEqualTo: fromUserId)
          .where('blockerUserId', isEqualTo: toUserId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Criar parceria a partir de convite aceito
  static Future<void> _createPartnershipFromInvite(
      PurposeInviteModel invite) async {
    // Buscar usuário de destino
    final toUser = await searchUserByEmail(invite.toUserEmail!);
    if (toUser == null) {
      throw Exception('Usuário de destino não encontrado');
    }

    await createPartnership(invite.fromUserId!, toUser.id!);
  }

  /// Adicionar usuário ao chat através de menção
  static Future<void> _addUserToMentionChat(PurposeInviteModel invite) async {
    // Buscar parceria do usuário que enviou a menção
    final partnership = await getUserPartnership(invite.fromUserId!);
    if (partnership == null) {
      throw Exception('Parceria não encontrada');
    }

    // Adicionar usuário mencionado aos participantes do chat
    final participantIds = [
      partnership.user1Id!,
      partnership.user2Id!,
      invite.toUserId!
    ];

    // Enviar mensagem de boas-vindas
    final welcomeMessage = PurposeChatModel.adminMessage(
      chatId: partnership.chatId!,
      participantIds: participantIds,
      text:
          '${invite.fromUserName} convidou um novo participante para o Propósito. Sejam bem-vindos!',
    );

    await _firestore.collection(_chatsCollection).add(welcomeMessage.toMap());
  }

  // ==================== GERENCIAMENTO DE PARCERIAS ====================

  /// Obter todas as parcerias ativas
  static Future<List<PurposePartnershipModel>> getActivePartnerships() async {
    try {
      final query = await _firestore
          .collection(_partnershipsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('dataCriacao', descending: true)
          .get();

      return query.docs
          .map((doc) => PurposePartnershipModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar parcerias ativas: ${e.toString()}');
    }
  }

  /// Obter histórico de parcerias do usuário
  static Future<List<PurposePartnershipModel>> getUserPartnershipHistory(
      String userId) async {
    try {
      final query = await _firestore
          .collection(_partnershipsCollection)
          .orderBy('dataCriacao', descending: true)
          .get();

      return query.docs
          .map((doc) => PurposePartnershipModel.fromFirestore(doc))
          .where((partnership) => partnership.includesUser(userId))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar histórico de parcerias: ${e.toString()}');
    }
  }

  /// Verificar se dois usuários já foram parceiros
  static Future<bool> werePartners(String user1Id, String user2Id) async {
    try {
      final query = await _firestore.collection(_partnershipsCollection).get();

      for (var doc in query.docs) {
        final partnership = PurposePartnershipModel.fromFirestore(doc);
        if (partnership.includesUsers(user1Id, user2Id)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== ESTATÍSTICAS E ANALYTICS ====================

  /// Obter estatísticas de convites do usuário
  static Future<Map<String, int>> getUserInviteStats(String userId) async {
    try {
      final sentQuery = await _firestore
          .collection(_invitesCollection)
          .where('fromUserId', isEqualTo: userId)
          .get();

      final receivedQuery = await _firestore
          .collection(_invitesCollection)
          .where('toUserId', isEqualTo: userId)
          .get();

      final sent = sentQuery.docs.length;
      final received = receivedQuery.docs.length;
      final accepted = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'accepted')
          .length;
      final rejected = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'rejected')
          .length;
      final blocked = receivedQuery.docs
          .where((doc) => doc.data()['status'] == 'blocked')
          .length;

      return {
        'sent': sent,
        'received': received,
        'accepted': accepted,
        'rejected': rejected,
        'blocked': blocked,
      };
    } catch (e) {
      return {
        'sent': 0,
        'received': 0,
        'accepted': 0,
        'rejected': 0,
        'blocked': 0,
      };
    }
  }

  /// Obter estatísticas gerais do sistema
  static Future<Map<String, int>> getSystemStats() async {
    try {
      final invitesQuery =
          await _firestore.collection(_invitesCollection).get();
      final partnershipsQuery =
          await _firestore.collection(_partnershipsCollection).get();
      final chatsQuery = await _firestore.collection(_chatsCollection).get();

      final totalInvites = invitesQuery.docs.length;
      final totalPartnerships = partnershipsQuery.docs.length;
      final activePartnerships = partnershipsQuery.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;
      final totalChats = chatsQuery.docs.length;

      return {
        'totalInvites': totalInvites,
        'totalPartnerships': totalPartnerships,
        'activePartnerships': activePartnerships,
        'totalChats': totalChats,
      };
    } catch (e) {
      return {
        'totalInvites': 0,
        'totalPartnerships': 0,
        'activePartnerships': 0,
        'totalChats': 0,
      };
    }
  }

  // ==================== VALIDAÇÕES ====================

  /// Verificar se usuário pode enviar convites
  static Future<bool> canInviteUser(String fromUserId, String toUserId) async {
    try {
      // Verificar rate limiting (máximo 5 convites por dia)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final invitesToday = await _firestore
          .collection(_invitesCollection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('dataCriacao',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (invitesToday.docs.length >= 5) {
        return false;
      }

      // Verificar se não é o mesmo usuário
      if (fromUserId == toUserId) {
        return false;
      }

      // Verificar se usuário está bloqueado
      final isBlocked = await isUserBlocked(fromUserId, toUserId);
      if (isBlocked) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validar dados de convite
  static bool validateInviteData(
      String fromUserId, String toUserEmail, String message) {
    // Verificar se os campos obrigatórios estão preenchidos
    if (fromUserId.isEmpty || toUserEmail.isEmpty) {
      return false;
    }

    // Verificar formato do email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(toUserEmail)) {
      return false;
    }

    // Verificar tamanho da mensagem
    if (message.length > 500) {
      return false;
    }

    return true;
  }

  /// Validar dados de parceria
  static bool validatePartnershipData(String user1Id, String user2Id) {
    // Verificar se os IDs são diferentes
    if (user1Id == user2Id) {
      return false;
    }

    // Verificar se os IDs não estão vazios
    if (user1Id.isEmpty || user2Id.isEmpty) {
      return false;
    }

    return true;
  }
}
