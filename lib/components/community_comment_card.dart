import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/community_comment_model.dart';

/// Card simples de comentário da Comunidade Viva
/// Layout antigo funcionando
class CommunityCommentCard extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  const CommunityCommentCard({
    super.key,
    required this.comment,
    this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha do usuário
          Row(
            children: [
              // Avatar com tratamento de erro
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: (comment.userAvatarUrl != null && 
                                  comment.userAvatarUrl!.isNotEmpty &&
                                  comment.userAvatarUrl!.startsWith('http'))
                    ? NetworkImage(comment.userAvatarUrl!)
                    : null,
                onBackgroundImageError: (exception, stackTrace) {
                  // Silenciosamente ignora erros de carregamento de imagem
                },
                child: (comment.userAvatarUrl == null || 
                        comment.userAvatarUrl!.isEmpty ||
                        !comment.userAvatarUrl!.startsWith('http'))
                    ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(width: 8),
              
              // Nome e tempo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeago.format(comment.createdAt.toDate(), locale: 'pt_BR'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge "Arauto" se curado
              if (comment.isCurated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.purple[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Arauto',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Texto do comentário
          Text(
            comment.text,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Estatísticas simples
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${comment.replyCount} respostas',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.favorite_border, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${comment.reactionCount} reações',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
