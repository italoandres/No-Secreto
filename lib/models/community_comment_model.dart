import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para comentários da Comunidade Viva
/// Suporta comentários raiz (chats) e respostas aninhadas
class CommunityCommentModel {
  final String commentId;
  final String storyId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final Timestamp createdAt;
  final String? parentId; // null se for comentário raiz (início de chat)
  final int replyCount;
  final int reactionCount;
  final Timestamp? lastReplyAt;
  final bool isCurated;

  CommunityCommentModel({
    required this.commentId,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.replyCount = 0,
    this.reactionCount = 0,
    this.lastReplyAt,
    this.isCurated = false,
  });

  /// Construtor para ler do Firestore
  factory CommunityCommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityCommentModel(
      commentId: doc.id,
      storyId: data['storyId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário',
      userAvatarUrl: data['userAvatarUrl'],
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      parentId: data['parentId'],
      replyCount: data['replyCount'] ?? 0,
      reactionCount: data['reactionCount'] ?? 0,
      lastReplyAt: data['lastReplyAt'],
      isCurated: data['isCurated'] ?? false,
    );
  }

  /// Método para converter para Map (para escrever no Firestore)
  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'text': text,
      'createdAt': createdAt,
      'parentId': parentId,
      'replyCount': replyCount,
      'reactionCount': reactionCount,
      'lastReplyAt': lastReplyAt,
      'isCurated': isCurated,
    };
  }

  /// Cria uma cópia com campos atualizados
  CommunityCommentModel copyWith({
    String? commentId,
    String? storyId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? text,
    Timestamp? createdAt,
    String? parentId,
    int? replyCount,
    int? reactionCount,
    Timestamp? lastReplyAt,
    bool? isCurated,
  }) {
    return CommunityCommentModel(
      commentId: commentId ?? this.commentId,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      replyCount: replyCount ?? this.replyCount,
      reactionCount: reactionCount ?? this.reactionCount,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      isCurated: isCurated ?? this.isCurated,
    );
  }

  /// Getter para compatibilidade (alias para commentId)
  String get id => commentId;
}
