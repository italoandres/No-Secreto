import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../models/story_like_model.dart';
import '../models/story_comment_model.dart';
import '../models/story_favorite_model.dart';
import '../models/usuario_model.dart';
import 'usuario_repository.dart';
import '../utils/context_utils.dart';

class StoryInteractionsRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // LIKES
  
  /// Curte ou descurte um story
  static Future<bool> toggleLike(String storyId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      final user = await UsuarioRepository.getUserById(userId);
      if (user == null) return false;
      
      final likeRef = _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId);
      
      final existingLike = await likeRef.get();
      
      if (existingLike.docs.isNotEmpty) {
        // Remove like
        await existingLike.docs.first.reference.delete();
        return false;
      } else {
        // Adiciona like
        final like = StoryLikeModel(
          storyId: storyId,
          userId: userId,
          userName: user.nome ?? 'Usuário',
          userUsername: user.username ?? '',
          dataCadastro: Timestamp.now(),
        );
        
        await _firestore.collection('story_likes').add(like.toJson());
        return true;
      }
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao curtir story: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário atual curtiu o story
  static Future<bool> hasUserLiked(String storyId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      final like = await _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId)
          .get();
      
      return like.docs.isNotEmpty;
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao verificar like: $e');
      return false;
    }
  }
  
  /// Obtém a contagem de likes de um story
  static Future<int> getLikesCount(String storyId) async {
    try {
      final likes = await _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .get();
      
      return likes.docs.length;
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao contar likes: $e');
      return 0;
    }
  }
  
  /// Stream de likes de um story (otimizado)
  static Stream<List<StoryLikeModel>> getLikesStream(String storyId) {
    return _firestore
        .collection('story_likes')
        .where('storyId', isEqualTo: storyId)
        .orderBy('dataCadastro', descending: true)
        .limit(100) // Limita para performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryLikeModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  // COMENTÁRIOS
  
  /// Adiciona um comentário a um story
  static Future<String?> addComment({
    required String storyId,
    required String text,
    String? parentCommentId,
    List<String>? mentions,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;
      
      final user = await UsuarioRepository.getUserById(userId);
      if (user == null) return null;
      
      // Filtro de moderação básico
      if (_containsInappropriateContent(text)) {
        throw Exception('Comentário contém conteúdo inadequado');
      }
      
      final comment = StoryCommentModel(
        storyId: storyId,
        userId: userId,
        userName: user.nome ?? 'Usuário',
        userUsername: user.username ?? '',
        userPhotoUrl: user.imgUrl,
        text: text,
        mentions: mentions,
        parentCommentId: parentCommentId,
        likesCount: 0,
        repliesCount: 0,
        dataCadastro: Timestamp.now(),
        isModerated: false,
        isBlocked: false,
      );
      
      final docRef = await _firestore.collection('story_comments').add(comment.toJson());
      
      // Se é uma resposta, incrementa o contador do comentário pai
      if (parentCommentId != null) {
        await _firestore.collection('story_comments').doc(parentCommentId).update({
          'repliesCount': FieldValue.increment(1),
        });
      }
      
      // TODO: Enviar notificações para menções
      if (mentions != null && mentions.isNotEmpty) {
        _sendMentionNotifications(storyId, mentions, user);
      }
      
      return docRef.id;
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao adicionar comentário: $e');
      rethrow;
    }
  }
  
  /// Obtém comentários de um story (limitado para performance)
  static Stream<List<StoryCommentModel>> getCommentsStream(String storyId) {
    return _firestore
        .collection('story_comments')
        .where('storyId', isEqualTo: storyId)
        .where('parentCommentId', isNull: true) // Apenas comentários principais
        .where('isBlocked', isEqualTo: false)
        .orderBy('dataCadastro', descending: false)
        .limit(50) // Limita a 50 comentários para performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryCommentModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  /// Obtém respostas de um comentário
  static Stream<List<StoryCommentModel>> getRepliesStream(String parentCommentId) {
    return _firestore
        .collection('story_comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .where('isBlocked', isEqualTo: false)
        .orderBy('dataCadastro', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryCommentModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  /// Curte ou descurte um comentário
  static Future<bool> toggleCommentLike(String commentId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      final likeRef = _firestore
          .collection('comment_likes')
          .where('commentId', isEqualTo: commentId)
          .where('userId', isEqualTo: userId);
      
      final existingLike = await likeRef.get();
      
      if (existingLike.docs.isNotEmpty) {
        // Remove like
        await existingLike.docs.first.reference.delete();
        await _firestore.collection('story_comments').doc(commentId).update({
          'likesCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // Adiciona like
        await _firestore.collection('comment_likes').add({
          'commentId': commentId,
          'userId': userId,
          'dataCadastro': Timestamp.now(),
        });
        await _firestore.collection('story_comments').doc(commentId).update({
          'likesCount': FieldValue.increment(1),
        });
        return true;
      }
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao curtir comentário: $e');
      return false;
    }
  }
  
  // FAVORITOS
  
  /// Adiciona ou remove story dos favoritos
  static Future<bool> toggleFavorite(String storyId, {String contexto = 'principal'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ContextDebug.logCriticalError('toggleFavorite', 'Usuário não logado', contexto);
        return false;
      }
      
      // Validar e normalizar contexto
      final normalizedContext = ContextValidator.normalizeContext(contexto);
      if (!ContextValidator.validateAndLog(contexto, 'toggleFavorite')) {
        ContextDebug.logCriticalError('toggleFavorite', 'Contexto inválido, usando contexto normalizado', normalizedContext);
      }
      
      // Validar parâmetros
      if (storyId.isEmpty) {
        ContextDebug.logCriticalError('toggleFavorite', 'StoryId vazio', normalizedContext);
        return false;
      }
      
      ContextDebug.logSummary('toggleFavorite', normalizedContext, {
        'storyId': storyId,
        'userId': userId,
        'originalContext': contexto,
        'normalizedContext': normalizedContext,
        'operation': 'TOGGLE_FAVORITE'
      });
      
      final favoriteRef = _firestore
          .collection('story_favorites')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: normalizedContext); // USAR CONTEXTO NORMALIZADO
      
      final existingFavorite = await favoriteRef.get();
      
      ContextDebug.logSummary('favorite_check', normalizedContext, {
        'existingFavorites': existingFavorite.docs.length,
        'action': existingFavorite.docs.isNotEmpty ? 'REMOVE' : 'ADD'
      });
      
      if (existingFavorite.docs.isNotEmpty) {
        // Validar contexto do favorito existente antes de remover
        final existingDoc = existingFavorite.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final existingContext = ContextValidator.normalizeContext(existingData['contexto'] as String?);
        
        if (existingContext != normalizedContext) {
          ContextDebug.logCriticalError('toggleFavorite', 
            'VAZAMENTO DETECTADO - Favorito existente tem contexto "$existingContext" mas deveria ser "$normalizedContext"', 
            normalizedContext);
        }
        
        // Remove dos favoritos
        final docId = existingDoc.id;
        await existingDoc.reference.delete();
        
        ContextDebug.logSummary('favorite_removed', normalizedContext, {
          'docId': docId,
          'storyId': storyId,
          'existingContext': existingContext
        });
        
        return false;
      } else {
        // Adiciona aos favoritos
        final favorite = StoryFavoriteModel(
          storyId: storyId,
          userId: userId,
          contexto: normalizedContext, // USAR CONTEXTO NORMALIZADO
          dataCadastro: Timestamp.now(),
        );
        
        final docRef = await _firestore.collection('story_favorites').add(favorite.toJson());
        
        ContextDebug.logSummary('favorite_added', normalizedContext, {
          'docId': docRef.id,
          'storyId': storyId,
          'savedData': favorite.toJson()
        });
        
        return true;
      }
    } catch (e) {
      ContextDebug.logCriticalError('toggleFavorite', 'Erro ao favoritar story: $e', contexto);
      return false;
    }
  }
  
  /// Verifica se o usuário favoritou o story
  static Future<bool> hasUserFavorited(String storyId, {String contexto = 'principal'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ContextDebug.logCriticalError('hasUserFavorited', 'Usuário não logado', contexto);
        return false;
      }
      
      // Validar e normalizar contexto
      final normalizedContext = ContextValidator.normalizeContext(contexto);
      if (!ContextValidator.validateAndLog(contexto, 'hasUserFavorited')) {
        ContextDebug.logCriticalError('hasUserFavorited', 'Contexto inválido, usando contexto normalizado', normalizedContext);
      }
      
      // Validar parâmetros
      if (storyId.isEmpty) {
        ContextDebug.logCriticalError('hasUserFavorited', 'StoryId vazio', normalizedContext);
        return false;
      }
      
      final favorite = await _firestore
          .collection('story_favorites')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: normalizedContext) // USAR CONTEXTO NORMALIZADO
          .get();
      
      // Validar contexto dos documentos encontrados
      for (final doc in favorite.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final docContext = ContextValidator.normalizeContext(data['contexto'] as String?);
        
        if (docContext != normalizedContext) {
          ContextDebug.logCriticalError('hasUserFavorited', 
            'VAZAMENTO DETECTADO - Documento ${doc.id} tem contexto "$docContext" mas deveria ser "$normalizedContext"', 
            normalizedContext);
        }
      }
      
      final isFavorited = favorite.docs.isNotEmpty;
      
      ContextDebug.logSummary('favorite_check_result', normalizedContext, {
        'storyId': storyId,
        'isFavorited': isFavorited,
        'documentsFound': favorite.docs.length
      });
      
      return isFavorited;
    } catch (e) {
      ContextDebug.logCriticalError('hasUserFavorited', 'Erro ao verificar favorito: $e', contexto);
      return false;
    }
  }
  
  /// Obtém stories favoritos do usuário por contexto
  static Stream<List<String>> getUserFavoritesStream({String contexto = 'principal'}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ContextDebug.logCriticalError('getUserFavoritesStream', 'Usuário não logado', contexto);
      return Stream.value([]);
    }
    
    // Validar e normalizar contexto
    final normalizedContext = ContextValidator.normalizeContext(contexto);
    if (!ContextValidator.validateAndLog(contexto, 'getUserFavoritesStream')) {
      ContextDebug.logCriticalError('getUserFavoritesStream', 'Contexto inválido, usando contexto normalizado', normalizedContext);
    }
    
    ContextDebug.logSummary('getUserFavoritesStream', normalizedContext, {
      'userId': userId,
      'originalContext': contexto,
      'normalizedContext': normalizedContext,
      'operation': 'LOAD_FAVORITES_BY_CONTEXT'
    });
    
    return ContextDebug.measurePerformance('getUserFavoritesStream_query', normalizedContext, () {
      return _firestore
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: normalizedContext) // USAR CONTEXTO NORMALIZADO
          .snapshots();
    }).asyncMap((snapshot) async {
      ContextDebug.logLoad(normalizedContext, 'story_favorites', snapshot.docs.length, 'getUserFavoritesStream');
      
      // Se não encontrou nada e é contexto principal, buscar favoritos legacy
      if (snapshot.docs.isEmpty && normalizedContext == 'principal') {
        ContextDebug.logSummary('legacy_migration', normalizedContext, {
          'action': 'SEARCHING_LEGACY_FAVORITES'
        });
        
        final legacyQuery = await _firestore
            .collection('story_favorites')
            .where('userId', isEqualTo: userId)
            .get();
        
        await _migrateLegacyFavorites(legacyQuery.docs);
      }
      
      // Validar contexto de cada documento
      final validDocs = <QueryDocumentSnapshot>[];
      final invalidDocs = <QueryDocumentSnapshot>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final docContext = ContextValidator.normalizeContext(data['contexto'] as String?);
        
        if (docContext == normalizedContext) {
          validDocs.add(doc);
        } else {
          invalidDocs.add(doc);
          ContextDebug.logCriticalError('getUserFavoritesStream', 
            'VAZAMENTO DE FAVORITO DETECTADO - Documento ${doc.id} tem contexto "$docContext" mas deveria ser "$normalizedContext"', 
            normalizedContext);
        }
      }
      
      // Log de vazamentos se encontrados
      if (invalidDocs.isNotEmpty) {
        ContextDebug.logSummary('favorites_leak_detected', normalizedContext, {
          'validDocs': validDocs.length,
          'invalidDocs': invalidDocs.length,
          'leakDetails': invalidDocs.map((doc) => {
            'docId': doc.id,
            'docContext': (doc.data() as Map<String, dynamic>)['contexto']
          }).toList()
        });
      }
      
      // Ordenar documentos válidos manualmente por enquanto
      validDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['dataCadastro'] as Timestamp?) ?? Timestamp.now();
        final bTime = (bData['dataCadastro'] as Timestamp?) ?? Timestamp.now();
        return bTime.compareTo(aTime); // Descending
      });
      
      final storyIds = validDocs
          .map((doc) => (doc.data() as Map<String, dynamic>)['storyId'] as String)
          .toList();
      
      ContextDebug.logFilter(normalizedContext, snapshot.docs.length, storyIds.length, 'getUserFavoritesStream');
      ContextDebug.logSummary('favorites_result', normalizedContext, {
        'totalFavorites': storyIds.length,
        'storyIds': storyIds
      });
      
      return storyIds;
    });
  }
  
  /// Obtém todos os stories favoritos do usuário (todos os contextos) - para galeria geral
  static Stream<List<String>> getAllUserFavoritesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ INTERACTIONS: Usuário não logado para buscar favoritos');
      return Stream.value([]);
    }
    
    print('📚 INTERACTIONS: Buscando TODOS os favoritos para userId: $userId');
    
    return _firestore
        .collection('story_favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          // Migrar favoritos antigos sem contexto
          await _migrateLegacyFavorites(snapshot.docs);
          
          // Ordenar manualmente por enquanto
          final docs = snapshot.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['dataCadastro'] as Timestamp?) ?? Timestamp.now();
            final bTime = (b.data()['dataCadastro'] as Timestamp?) ?? Timestamp.now();
            return bTime.compareTo(aTime); // Descending
          });
          
          final storyIds = docs
              .map((doc) => doc.data()['storyId'] as String)
              .toList();
          print('✅ INTERACTIONS: TODOS os favoritos encontrados: ${storyIds.length} - IDs: $storyIds');
          return storyIds;
        });
  }
  
  /// Migra favoritos antigos que não têm contexto
  static Future<void> _migrateLegacyFavorites(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('contexto') || data['contexto'] == null) {
        print('🔄 INTERACTIONS: Migrando favorito legacy: ${doc.id}');
        try {
          await doc.reference.update({'contexto': 'principal'});
          print('✅ INTERACTIONS: Favorito migrado para contexto principal');
        } catch (e) {
          print('❌ INTERACTIONS: Erro ao migrar favorito: $e');
        }
      }
    }
  }
  
  // UTILITÁRIOS
  
  /// Filtro básico de conteúdo inadequado
  static bool _containsInappropriateContent(String text) {
    final inappropriateWords = [
      'palavrão1', 'palavrão2', // Adicionar palavras inadequadas
      // TODO: Implementar filtro mais sofisticado
    ];
    
    final lowerText = text.toLowerCase();
    return inappropriateWords.any((word) => lowerText.contains(word));
  }
  
  /// Envia notificações para usuários mencionados
  static Future<void> _sendMentionNotifications(
    String storyId, 
    List<String> mentions, 
    UsuarioModel mentioner
  ) async {
    // TODO: Implementar sistema de notificações
    print('DEBUG INTERACTIONS: Enviando notificações para: $mentions');
  }
  
  /// Busca usuários para menção
  static Future<List<UsuarioModel>> searchUsersForMention(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final users = await _firestore
          .collection('usuarios')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(10)
          .get();
      
      return users.docs
          .map((doc) => UsuarioModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao buscar usuários: $e');
      return [];
    }
  }
  
  /// Compartilha um story
  static Future<void> shareStory(String storyId) async {
    try {
      // Implementação básica usando share_plus
      final storyUrl = 'https://app.nosecreto.com/story/$storyId';
      final shareText = 'Confira este story incrível no No Secreto com Deus Pai!\n\n$storyUrl';
      
      // Usar o share_plus para compartilhar
      await _shareContent(shareText);
      
      // Registrar compartilhamento para analytics
      await _firestore.collection('story_shares').add({
        'storyId': storyId,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'dataCadastro': Timestamp.now(),
        'platform': 'app', // Pode ser expandido para diferentes plataformas
      });
      
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro ao compartilhar story: $e');
      rethrow;
    }
  }
  
  /// Função auxiliar para compartilhamento
  static Future<void> _shareContent(String text) async {
    try {
      // Usar share_plus para compartilhamento nativo
      await Share.share(
        text,
        subject: 'Story do No Secreto com Deus Pai',
      );
      
      print('DEBUG INTERACTIONS: Compartilhando: $text');
      
    } catch (e) {
      print('DEBUG INTERACTIONS: Erro no compartilhamento: $e');
      
      // Fallback: copiar para clipboard
      try {
        await Clipboard.setData(ClipboardData(text: text));
        print('DEBUG INTERACTIONS: Texto copiado para clipboard como fallback');
      } catch (clipboardError) {
        print('DEBUG INTERACTIONS: Erro no fallback clipboard: $clipboardError');
        rethrow;
      }
    }
  }
}