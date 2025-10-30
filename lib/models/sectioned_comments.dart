import 'community_comment_model.dart';

/// Tipo de seção de comentário
enum CommentSection {
  trending, // Chats em Alta (>20 reações OU >5 respostas)
  recent,   // Chats Recentes (<24h com baixo engajamento)
  featured, // Chats do Pai (curados/fixados)
}

/// Comentários organizados por seções
class SectionedComments {
  final List<CommunityCommentModel> trending;
  final List<CommunityCommentModel> recent;
  final List<CommunityCommentModel> featured;

  SectionedComments({
    required this.trending,
    required this.recent,
    required this.featured,
  });

  /// Retorna true se não há comentários em nenhuma seção
  bool get isEmpty => trending.isEmpty && recent.isEmpty && featured.isEmpty;

  /// Retorna o total de comentários em todas as seções
  int get totalCount => trending.length + recent.length + featured.length;
}
