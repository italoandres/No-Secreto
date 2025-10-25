import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/story_interactions_controller.dart';
import '../repositories/chat_repository.dart';
import '../repositories/stories_repository.dart';
import '../models/storie_file_model.dart';
import '../utils/enhanced_image_loader.dart';

class StoryInteractionsComponent extends StatelessWidget {
  final String storyId;
  final VoidCallback? onCommentTap;

  const StoryInteractionsComponent({
    super.key,
    required this.storyId,
    this.onCommentTap,
  });

  /// Mostra opções de resposta baseadas no gênero do usuário
  void _showReplyOptions() {
    // TODO: Implementar detecção real do gênero do usuário
    // Por enquanto, simulando lógica baseada no contexto atual
    final userGender = _getUserGender(); // Função para detectar gênero

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Responder story em:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Opções de resposta baseadas no gênero
            Column(
              children: _buildReplyOptionsForUser(userGender),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Constrói uma opção de resposta
  Widget _buildReplyOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// Detecta o gênero do usuário (simulado por enquanto)
  String _getUserGender() {
    // TODO: Implementar detecção real do gênero do usuário
    // Por enquanto retorna 'masculino' como padrão
    return 'masculino'; // ou 'feminino'
  }

  /// Constrói opções de resposta baseadas no gênero do usuário
  List<Widget> _buildReplyOptionsForUser(String userGender) {
    List<Widget> options = [];

    // Chat Principal - sempre disponível
    options.add(_buildReplyOption(
      icon: Icons.chat,
      iconColor: Colors.green,
      title: 'Chat Principal',
      subtitle: 'Responder no chat geral',
      onTap: () => _replyToChat('principal'),
    ));

    // Opções baseadas no gênero
    if (userGender == 'masculino') {
      options.add(_buildReplyOption(
        icon: Icons.person,
        iconColor: Colors.pink,
        title: 'Sinais de Minha Rebeca',
        subtitle: 'Chat direcionado para mulheres',
        onTap: () => _replyToChat('sinais_rebeca'),
      ));
    } else if (userGender == 'feminino') {
      options.add(_buildReplyOption(
        icon: Icons.person,
        iconColor: Colors.blue,
        title: 'Sinais de Meu Isaque',
        subtitle: 'Chat direcionado para homens',
        onTap: () => _replyToChat('sinais_isaque'),
      ));
    }

    // Nosso Propósito - sempre disponível
    options.add(_buildReplyOption(
      icon: Icons.favorite,
      iconColor: Colors.purple,
      title: 'Nosso Propósito',
      subtitle: 'Chat especial (em breve)',
      onTap: () => _replyToChat('nosso_proposito'),
    ));

    return options;
  }

  /// Responde o story no chat especificado
  void _replyToChat(String chatType) {
    Get.back(); // Fecha o modal

    // Navegar para o chat com story pré-carregado
    _navigateToChatWithStory(chatType, storyId);
  }

  /// Navega para o chat especificado com story pré-carregado
  void _navigateToChatWithStory(String chatType, String storyId) {
    // Primeiro, buscar os dados do story
    _getStoryData(storyId).then((storyData) {
      if (storyData != null) {
        // Navegar para o chat apropriado
        switch (chatType) {
          case 'principal':
            _openChatWithPreloadedStory('principal', storyData);
            break;
          case 'sinais_isaque':
            _openChatWithPreloadedStory('sinais_isaque', storyData);
            break;
          case 'sinais_rebeca':
            _openChatWithPreloadedStory('sinais_rebeca', storyData);
            break;
          case 'nosso_proposito':
            Get.rawSnackbar(
              message: 'Chat "Nosso Propósito" em desenvolvimento',
              backgroundColor: Colors.orange,
            );
            break;
        }
      }
    });
  }

  /// Busca dados do story
  Future<Map<String, dynamic>?> _getStoryData(String storyId) async {
    try {
      // Buscar story real do repository
      final story = await StoriesRepository.getStoryById(storyId);

      if (story != null) {
        return {
          'id': story.id,
          'mediaUrl': story.fileUrl,
          'mediaType':
              story.fileType == StorieFileType.video ? 'video' : 'image',
          'titulo': story.titulo ?? 'Story',
          'descricao': story.descricao ?? '',
          'videoThumbnail': story.videoThumbnail,
        };
      }

      return null;
    } catch (e) {
      print('Erro ao buscar dados do story: $e');
      return null;
    }
  }

  /// Abre o chat com story pré-carregado
  void _openChatWithPreloadedStory(
      String chatType, Map<String, dynamic> storyData) {
    final TextEditingController commentController = TextEditingController();

    // Mostrar modal de composição de mensagem com story
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
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
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Responder em ${_getChatDisplayName(chatType)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Preview do story
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Thumbnail da mídia
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: storyData['mediaType'] == 'video'
                          ? Stack(
                              children: [
                                if (storyData['videoThumbnail'] != null)
                                  EnhancedImageLoader.buildCachedImage(
                                    imageUrl: storyData['videoThumbnail'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorWidget: const Icon(Icons.video_library,
                                        color: Colors.grey),
                                  )
                                else
                                  const Icon(Icons.video_library,
                                      color: Colors.grey),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            )
                          : EnhancedImageLoader.buildCachedImage(
                              imageUrl: storyData['mediaUrl'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget:
                                  const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Informações do story
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storyData['titulo'] ?? 'Story',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (storyData['descricao'] != null)
                          Text(
                            storyData['descricao'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Campo de comentário
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu comentário:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText:
                              'Escreva seu comentário sobre este story...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botão de enviar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final comment = commentController.text.trim();

                          if (comment.isEmpty) {
                            Get.rawSnackbar(
                              message: 'Digite um comentário antes de enviar',
                              backgroundColor: Colors.orange,
                            );
                            return;
                          }

                          try {
                            // Preparar mensagem com story
                            final messageText =
                                _buildStoryMessage(storyData, comment);

                            // Enviar para o chat apropriado
                            bool success =
                                await _sendToChat(chatType, messageText);

                            if (success) {
                              Get.back();
                              Get.rawSnackbar(
                                message:
                                    'Mensagem enviada para ${_getChatDisplayName(chatType)}!',
                                backgroundColor: Colors.green,
                              );
                            } else {
                              Get.rawSnackbar(
                                message: 'Erro ao enviar mensagem',
                                backgroundColor: Colors.red,
                              );
                            }
                          } catch (e) {
                            Get.rawSnackbar(
                              message: 'Erro ao enviar: $e',
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Enviar Mensagem',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Constrói a mensagem com informações do story
  String _buildStoryMessage(Map<String, dynamic> storyData, String comment) {
    final titulo = storyData['titulo'] ?? 'Story';
    final descricao = storyData['descricao'] ?? '';

    String message = '📱 Respondendo ao story: "$titulo"';

    if (descricao.isNotEmpty) {
      message += '\n📝 $descricao';
    }

    message += '\n\n💬 $comment';

    return message;
  }

  /// Envia mensagem para o chat especificado
  Future<bool> _sendToChat(String chatType, String message) async {
    try {
      switch (chatType) {
        case 'principal':
          return await ChatRepository.addText(
            msg: message,
            contexto: null, // Chat principal
          );
        case 'sinais_isaque':
          return await ChatRepository.addText(
            msg: message,
            contexto: 'sinais_isaque',
          );
        case 'sinais_rebeca':
          return await ChatRepository.addText(
            msg: message,
            contexto: 'sinais_rebeca',
          );
        case 'nosso_proposito':
          // TODO: Implementar quando o chat for criado
          throw Exception('Chat "Nosso Propósito" ainda não foi implementado');
        default:
          return false;
      }
    } catch (e) {
      print('Erro ao enviar mensagem para $chatType: $e');
      rethrow;
    }
  }

  /// Retorna o nome de exibição do chat
  String _getChatDisplayName(String chatType) {
    switch (chatType) {
      case 'principal':
        return 'Chat Principal';
      case 'sinais_isaque':
        return 'Sinais de Meu Isaque';
      case 'sinais_rebeca':
        return 'Sinais de Minha Rebeca';
      case 'nosso_proposito':
        return 'Nosso Propósito';
      default:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoryInteractionsController>();

    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          // Botão de Curtir (Oração) - Emoji 🙏 com animação de tremor
          _buildInteractionButton(
            icon: Obx(() => TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(
                      begin: 0.0, end: controller.isLiked.value ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(
                        value * 2 * sin(value * 20), // Tremor horizontal
                        0,
                      ),
                      child: Transform.scale(
                        scale: 1.0 + (value * 0.3), // Cresce quando curtido
                        child: Container(
                          decoration: controller.isLiked.value
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                )
                              : null,
                          child: Text(
                            '🙏',
                            style: TextStyle(
                              fontSize: 32,
                              color: controller.isLiked.value
                                  ? Colors.orange
                                  : Colors.white,
                              shadows: controller.isLiked.value
                                  ? [
                                      Shadow(
                                        color: Colors.orange.withOpacity(0.8),
                                        blurRadius: 10,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )),
            label: Obx(() => Text(
                  controller.likesCount.value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            onTap: controller.toggleLike,
          ),

          const SizedBox(height: 20),

          // Botão de Comentar
          _buildInteractionButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 32,
            ),
            label: Obx(() => Text(
                  controller.comments.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            onTap: onCommentTap ?? () {},
          ),

          const SizedBox(height: 20),

          // Botão de Favoritar
          _buildInteractionButton(
            icon: Obx(() => Icon(
                  controller.isFavorited.value
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: controller.isFavorited.value
                      ? Colors.yellow
                      : Colors.white,
                  size: 32,
                )),
            label: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: controller.toggleFavorite,
          ),

          const SizedBox(height: 20),

          // Botão de Compartilhar
          _buildInteractionButton(
            icon: const Icon(
              Icons.share,
              color: Colors.white,
              size: 32,
            ),
            label: const Text(
              'Compartilhar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => controller.shareStory(),
          ),

          const SizedBox(height: 20),

          // Botão de Responder
          _buildInteractionButton(
            icon: const Icon(
              Icons.reply,
              color: Colors.white,
              size: 32,
            ),
            label: const Text(
              'Responder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showReplyOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required Widget icon,
    required Widget label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            label,
          ],
        ),
      ),
    );
  }
}
