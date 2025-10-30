import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/story_comment_model.dart';
import '../models/story_like_model.dart';
import '../models/usuario_model.dart';
import '../repositories/story_interactions_repository.dart';
import '../services/notification_service.dart';
import '../repositories/usuario_repository.dart';
import '../repositories/stories_repository.dart';
import '../utils/story_author_helper.dart';

class StoryInteractionsController extends GetxController {
  // Observables
  final RxBool isLiked = false.obs;
  final RxInt likesCount = 0.obs;
  final RxBool isFavorited = false.obs;
  final RxList<StoryCommentModel> comments = <StoryCommentModel>[].obs;
  final RxList<StoryLikeModel> likes = <StoryLikeModel>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool isAddingComment = false.obs;

  // Controllers
  final TextEditingController commentController = TextEditingController();
  final TextEditingController replyController = TextEditingController();

  // Current story
  String? currentStoryId;
  String currentContexto = 'principal'; // Contexto atual do story

  // Mention system
  final RxList<UsuarioModel> mentionSuggestions = <UsuarioModel>[].obs;
  final RxBool showMentionSuggestions = false.obs;
  String? replyingToCommentId;
  String? replyingToUsername;

  // Stream subscriptions para cancelar
  StreamSubscription? _commentsSubscription;
  StreamSubscription? _likesSubscription;

  // Cache para evitar recarregamentos e manter persistência
  static final Map<String, bool> _likedCache = {};
  static final Map<String, bool> _favoritedCache = {};
  static final Map<String, int> _likesCountCache = {};
  static final Map<String, List<StoryCommentModel>> _commentsCache = {};

  @override
  void onClose() {
    print('DEBUG CONTROLLER: Disposing controller');
    _cancelStreams();
    commentController.dispose();
    replyController.dispose();
    super.onClose();
  }

  /// Cancela todos os streams ativos
  void _cancelStreams() {
    _commentsSubscription?.cancel();
    _likesSubscription?.cancel();
    _commentsSubscription = null;
    _likesSubscription = null;
  }

  /// Inicializa as interações para um story
  void initializeStory(String storyId, {String contexto = 'principal'}) {
    print('🚀🚀🚀 INICIALIZAÇÃO STORY 🚀🚀🚀');
    print('📖 Story ID: $storyId (anterior: $currentStoryId)');
    print('🏷️ Contexto recebido: "$contexto"');
    print('🏷️ Contexto anterior: "$currentContexto"');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀');

    // Se é o mesmo story, não faz nada
    if (currentStoryId == storyId && currentContexto == contexto) {
      print('⚠️ CONTROLLER: Mesmo story e contexto, pulando inicialização');
      return;
    }

    // Cancela streams anteriores
    _cancelStreams();

    // Limpa dados do story anterior
    print('🧹 CONTROLLER: Limpando dados do story anterior');
    clearStoryData();
    currentStoryId = storyId;
    currentContexto = contexto;

    print('✅ CONTEXTO DEFINIDO COMO: "$currentContexto"');

    // Carrega dados com cache
    _loadStoryDataWithCache();
    _listenToCommentsOptimized();
    _listenToLikesOptimized();
  }

  /// Carrega dados iniciais do story com cache
  void _loadStoryDataWithCache() async {
    if (currentStoryId == null) return;

    // Usar cache se disponível
    if (_likedCache.containsKey(currentStoryId!)) {
      isLiked.value = _likedCache[currentStoryId!]!;
      isFavorited.value = _favoritedCache[currentStoryId!] ?? false;
      likesCount.value = _likesCountCache[currentStoryId!] ?? 0;

      // Carregar comentários do cache se disponível
      if (_commentsCache.containsKey(currentStoryId!)) {
        comments.value = _commentsCache[currentStoryId!]!;
      }

      print(
          'DEBUG CONTROLLER: Dados carregados do cache para story $currentStoryId');
      return;
    }

    // Carrega dados apenas se não estiver em cache
    try {
      final results = await Future.wait([
        StoryInteractionsRepository.hasUserLiked(currentStoryId!),
        StoryInteractionsRepository.hasUserFavorited(currentStoryId!,
            contexto: currentContexto),
        StoryInteractionsRepository.getLikesCount(currentStoryId!),
      ]);

      // Atualiza cache
      _likedCache[currentStoryId!] = results[0] as bool;
      _favoritedCache[currentStoryId!] = results[1] as bool;
      _likesCountCache[currentStoryId!] = results[2] as int;

      // Atualiza UI
      isLiked.value = results[0] as bool;
      isFavorited.value = results[1] as bool;
      likesCount.value = results[2] as int;

      print(
          'DEBUG CONTROLLER: Dados carregados do servidor para story $currentStoryId');
    } catch (e) {
      print('DEBUG CONTROLLER: Erro ao carregar dados: $e');
    }
  }

  /// Escuta mudanças nos comentários de forma otimizada
  void _listenToCommentsOptimized() {
    if (currentStoryId == null) return;

    _commentsSubscription =
        StoryInteractionsRepository.getCommentsStream(currentStoryId!).listen(
      (commentsList) {
        // Só atualiza se realmente mudou
        if (comments.length != commentsList.length ||
            !_areCommentsEqual(comments, commentsList)) {
          comments.value = commentsList;

          // Atualizar cache
          _commentsCache[currentStoryId!] = List.from(commentsList);

          print(
              'DEBUG CONTROLLER: Comentários atualizados - Story: $currentStoryId, Count: ${commentsList.length}');
        }
      },
      onError: (error) {
        print('DEBUG CONTROLLER: Erro no stream de comentários: $error');
      },
    );
  }

  /// Verifica se duas listas de comentários são iguais
  bool _areCommentsEqual(
      List<StoryCommentModel> list1, List<StoryCommentModel> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].text != list2[i].text ||
          list1[i].likesCount != list2[i].likesCount) {
        return false;
      }
    }

    return true;
  }

  /// Escuta mudanças nos likes de forma otimizada
  void _listenToLikesOptimized() {
    if (currentStoryId == null) return;

    _likesSubscription =
        StoryInteractionsRepository.getLikesStream(currentStoryId!).listen(
      (likesList) {
        // Só atualiza se realmente mudou
        if (likesCount.value != likesList.length) {
          likes.value = likesList;
          likesCount.value = likesList.length;

          // Atualiza cache
          _likesCountCache[currentStoryId!] = likesList.length;
        }
      },
      onError: (error) {
        print('DEBUG CONTROLLER: Erro no stream de likes: $error');
      },
    );
  }

  /// Curte ou descurte o story
  Future<void> toggleLike() async {
    if (currentStoryId == null) return;

    try {
      final wasLiked =
          await StoryInteractionsRepository.toggleLike(currentStoryId!);
      isLiked.value = wasLiked;

      // Atualizar cache
      _likedCache[currentStoryId!] = wasLiked;

      // Atualizar contador de likes
      if (wasLiked) {
        likesCount.value++;
        _likesCountCache[currentStoryId!] = likesCount.value;
        _showLikeAnimation();
      } else {
        likesCount.value =
            (likesCount.value - 1).clamp(0, double.infinity).toInt();
        _likesCountCache[currentStoryId!] = likesCount.value;
      }

      print(
          'DEBUG CONTROLLER: Like atualizado - Story: $currentStoryId, Liked: $wasLiked, Count: ${likesCount.value}');
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao curtir story: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Adiciona ou remove dos favoritos
  Future<void> toggleFavorite() async {
    if (currentStoryId == null) {
      print('❌ CONTROLLER: currentStoryId é null, não é possível favoritar');
      return;
    }

    print('🔥🔥🔥 FAVORITO DEBUG 🔥🔥🔥');
    print('💾 CONTROLLER: Iniciando toggleFavorite');
    print('📖 Story ID: $currentStoryId');
    print('🏷️ Contexto atual: "$currentContexto"');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');

    try {
      final wasFavorited = await StoryInteractionsRepository.toggleFavorite(
          currentStoryId!,
          contexto: currentContexto);

      print('🔥🔥🔥 RESULTADO FAVORITO 🔥🔥🔥');
      print('✅ toggleFavorite retornou: $wasFavorited');
      print('🏷️ Contexto usado: "$currentContexto"');
      print('📖 Story ID: $currentStoryId');
      print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');

      isFavorited.value = wasFavorited;

      // Atualizar cache
      _favoritedCache[currentStoryId!] = wasFavorited;
      print(
          '💾 CONTROLLER: Cache atualizado para story $currentStoryId: $wasFavorited');

      Get.rawSnackbar(
        message: wasFavorited
            ? '💾 Story salvo nos favoritos!'
            : '🗑️ Story removido dos favoritos',
        backgroundColor: wasFavorited ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          wasFavorited ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
      );

      print(
          '✅ CONTROLLER: Favorito atualizado com sucesso - Story: $currentStoryId, Favorited: $wasFavorited');
    } catch (e) {
      print('❌ CONTROLLER: Erro ao favoritar: $e');
      Get.rawSnackbar(
        message: '❌ Erro ao favoritar story: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  /// Compartilha o story atual
  Future<void> shareStory() async {
    if (currentStoryId == null) return;

    try {
      await StoryInteractionsRepository.shareStory(currentStoryId!);

      Get.rawSnackbar(
        message: 'Story compartilhado com sucesso!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao compartilhar story: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Adiciona um comentário
  Future<void> addComment() async {
    if (currentStoryId == null || commentController.text.trim().isEmpty) return;

    isAddingComment.value = true;

    try {
      final mentions = _extractMentions(commentController.text);
      final commentText = commentController.text.trim();

      await StoryInteractionsRepository.addComment(
        storyId: currentStoryId!,
        text: commentText,
        parentCommentId:
            replyingToCommentId, // Usa o ID do comentário pai se estiver respondendo
        mentions: mentions.isNotEmpty ? mentions : null,
      );

      // Criar notificações após salvar o comentário com sucesso
      await _createCommentNotifications(commentText);

      commentController.clear();
      showMentionSuggestions.value = false;

      // Limpa dados de resposta
      replyingToCommentId = null;
      replyingToUsername = null;

      Get.rawSnackbar(
        message: replyingToCommentId != null
            ? 'Resposta adicionada!'
            : 'Comentário adicionado!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao adicionar comentário: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isAddingComment.value = false;
    }
  }

  /// Cria notificações para comentários
  Future<void> _createCommentNotifications(String commentText) async {
    try {
      if (currentStoryId == null) return;

      // Obter usuário atual
      final currentUserStream = UsuarioRepository.getUser();
      final currentUser = await currentUserStream.first;

      if (currentUser == null) {
        print('DEBUG: Usuário atual não encontrado');
        return;
      }

      // Obter informações do story
      final story = await StoriesRepository.getStoryById(currentStoryId!);

      if (story == null) {
        print('DEBUG: Story não encontrado: $currentStoryId');
        return;
      }

      // Processar apenas notificações de menções em comentários
      // Os stories são do aplicativo, não dos usuários
      final mentionedUserIds =
          await NotificationService.extractMentionUserIds(commentText);

      for (final mentionedUserId in mentionedUserIds) {
        await NotificationService.createMentionNotification(
          storyId: currentStoryId!,
          mentionedUserId: mentionedUserId,
          commentAuthorId: currentUser.id!,
          commentAuthorName: currentUser.nome!,
          commentAuthorAvatar: currentUser.imgUrl ?? '',
          commentText: commentText,
        );
      }

      print('DEBUG: Notificações de menção processadas');
    } catch (e) {
      print('Erro ao criar notificações: $e');
      // Não relançar o erro para não afetar a criação do comentário
    }
  }

  /// Responde a um comentário
  void replyToComment(String commentId, String username) {
    print(
        'DEBUG CONTROLLER: Respondendo ao comentário $commentId de @$username');

    replyingToCommentId = commentId;
    replyingToUsername = username;

    // Limpa o campo e adiciona a menção
    commentController.text = '@$username ';
    commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: commentController.text.length),
    );

    Get.rawSnackbar(
      message: 'Respondendo para @$username',
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 2),
    );
  }

  /// Adiciona uma resposta
  Future<void> addReply() async {
    if (currentStoryId == null ||
        replyController.text.trim().isEmpty ||
        replyingToCommentId == null) return;

    isAddingComment.value = true;

    try {
      final mentions = _extractMentions(replyController.text);

      await StoryInteractionsRepository.addComment(
        storyId: currentStoryId!,
        text: replyController.text.trim(),
        parentCommentId: replyingToCommentId,
        mentions: mentions.isNotEmpty ? mentions : null,
      );

      replyController.clear();
      replyingToCommentId = null;
      replyingToUsername = null;

      Get.rawSnackbar(
        message: 'Resposta adicionada!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao adicionar resposta: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isAddingComment.value = false;
    }
  }

  /// Curte ou descurte um comentário
  Future<void> toggleCommentLike(String commentId) async {
    try {
      await StoryInteractionsRepository.toggleCommentLike(commentId);
    } catch (e) {
      Get.rawSnackbar(
        message: 'Erro ao curtir comentário: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Timer? _searchTimer;

  /// Busca usuários para menção com debounce
  Future<void> searchUsersForMention(String query) async {
    // Cancela busca anterior
    _searchTimer?.cancel();

    if (query.length < 2) {
      mentionSuggestions.clear();
      showMentionSuggestions.value = false;
      return;
    }

    // Debounce de 300ms
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final users =
            await StoryInteractionsRepository.searchUsersForMention(query);
        if (users.isNotEmpty) {
          mentionSuggestions.value = users;
          showMentionSuggestions.value = true;
        }
      } catch (e) {
        print('Erro ao buscar usuários para menção: $e');
      }
    });
  }

  /// Seleciona um usuário para menção
  void selectUserForMention(UsuarioModel user) {
    final currentText = commentController.text;
    final lastAtIndex = currentText.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final beforeAt = currentText.substring(0, lastAtIndex);
      final afterQuery = '@${user.username} ';
      commentController.text = beforeAt + afterQuery;
      commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: commentController.text.length),
      );
    }

    showMentionSuggestions.value = false;
  }

  /// Extrai menções do texto
  List<String> _extractMentions(String text) {
    final mentionRegex = RegExp(r'@([a-zA-Z0-9_]+)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Mostra animação de like
  void _showLikeAnimation() {
    // TODO: Implementar animação de oração flutuante
    print('DEBUG: Mostrando animação de like');
  }

  /// Limpa dados ao trocar de story
  void clearStoryData() {
    print('DEBUG CONTROLLER: Limpando dados do story');

    // Cancela streams
    _cancelStreams();

    // Limpa apenas dados da UI, mantém cache
    isLiked.value = false;
    likesCount.value = 0;
    isFavorited.value = false;
    comments.clear();
    likes.clear();
    commentController.clear();
    replyController.clear();
    mentionSuggestions.clear();
    showMentionSuggestions.value = false;
    replyingToCommentId = null;
    replyingToUsername = null;
    isLoadingComments.value = false;
    isAddingComment.value = false;
  }

  /// Limpa todo o cache (útil para logout ou reset)
  static void clearAllCache() {
    _likedCache.clear();
    _favoritedCache.clear();
    _likesCountCache.clear();
    _commentsCache.clear();
    print('DEBUG CONTROLLER: Cache global limpo');
  }
}
