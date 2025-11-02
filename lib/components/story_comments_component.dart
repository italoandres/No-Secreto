import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/story_interactions_controller.dart';
import '../models/story_comment_model.dart';
import '../models/usuario_model.dart';
import '../views/profile_display_view.dart';
import '../repositories/spiritual_profile_repository.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class StoryCommentsComponent extends StatelessWidget {
  final String storyId;

  const StoryCommentsComponent({
    super.key,
    required this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoryInteractionsController>();
    final RxSet<String> expandedComments = <String>{}.obs;

    return Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comentários',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    print('DEBUG: Fechando comentários');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de comentários
          Expanded(
            child: Obx(() {
              if (controller.isLoadingComments.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.comments.isEmpty) {
                return const Center(
                  child: Text(
                    'Seja o primeiro a comentar!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return _buildCommentItem(comment, controller);
                },
                // Otimizações de performance
                cacheExtent: 1000, // Cache apenas 1000px
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
              );
            }),
          ),

          // Campo de comentário
          _buildCommentInput(controller),

          // Sugestões de menção
          Obx(() {
            if (!controller.showMentionSuggestions.value) {
              return const SizedBox();
            }

            return Container(
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.grey,
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: ListView.builder(
                itemCount: controller.mentionSuggestions.length,
                itemBuilder: (context, index) {
                  final user = controller.mentionSuggestions[index];
                  return _buildMentionSuggestion(user, controller);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
      StoryCommentModel comment, StoryInteractionsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withOpacity(0.1),
            backgroundImage: comment.userPhotoUrl != null && comment.userPhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(comment.userPhotoUrl!)
                : null,
            child: comment.userPhotoUrl == null || comment.userPhotoUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.blue)
                : null,
          ),

          const SizedBox(width: 12),

          // Conteúdo do comentário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e username
                Row(
                  children: [
                    Text(
                      comment.userName ?? 'Usuário',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.userUsername != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _openUserProfile(comment.userId),
                        child: Text(
                          '@${comment.userUsername}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(comment.dataCadastro),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Texto do comentário
                Text(
                  comment.text ?? '',
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 8),

                // Ações do comentário
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        print('DEBUG: Curtindo comentário ${comment.id}');
                        controller.toggleCommentLike(comment.id!);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount ?? 0}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => controller.replyToComment(
                        comment.id!,
                        comment.userUsername ?? comment.userName ?? 'usuário',
                      ),
                      child: const Text(
                        'Responder',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (comment.hasReplies) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // TODO: Expandir respostas
                        },
                        child: Text(
                          'Ver ${comment.repliesCount} resposta${comment.repliesCount! > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(StoryInteractionsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.commentController,
              decoration: const InputDecoration(
                hintText: 'Adicione um comentário...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onChanged: (text) {
                // Detectar menções
                if (text.contains('@')) {
                  final lastAtIndex = text.lastIndexOf('@');
                  if (lastAtIndex != -1 && lastAtIndex < text.length - 1) {
                    final query = text.substring(lastAtIndex + 1);
                    if (!query.contains(' ')) {
                      controller.searchUsersForMention(query);
                    }
                  }
                } else {
                  controller.showMentionSuggestions.value = false;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => IconButton(
                onPressed: controller.isAddingComment.value
                    ? null
                    : controller.addComment,
                icon: controller.isAddingComment.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.blue),
              )),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestion(
      UsuarioModel user, StoryInteractionsController controller) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue.withOpacity(0.1),
        backgroundImage:
            user.imgUrl != null && user.imgUrl!.isNotEmpty ? CachedNetworkImageProvider(user.imgUrl!) : null,
        child: user.imgUrl == null || user.imgUrl!.isEmpty
            ? const Icon(Icons.person, size: 16, color: Colors.blue)
            : null,
      ),
      title: Text(
        user.nome ?? 'Usuário',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: user.username != null
          ? Text(
              '@${user.username}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: () => controller.selectUserForMention(user),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  Future<void> _openUserProfile(String? userId) async {
    if (userId == null || userId.isEmpty) {
      Get.snackbar(
        'Erro',
        'Usuário não encontrado.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Check if user has a spiritual profile
      final profile =
          await SpiritualProfileRepository.getProfileByUserId(userId);

      if (profile == null || !profile.canShowPublicProfile) {
        Get.snackbar(
          'Perfil Indisponível',
          'Este usuário ainda não completou sua vitrine de propósito.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Navigate to profile display
      Get.to(() => ProfileDisplayView(userId: userId));
    } catch (e) {
      safePrint('❌ Erro ao abrir perfil: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o perfil. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
