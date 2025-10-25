import 'package:cloud_firestore/cloud_firestore.dart';

class StoryCommentModel {
  String? id;
  String storyId;
  String userId;
  String userName;
  String? userUsername;
  String? userPhotoUrl;
  String text;
  List<String>? mentions;
  String? parentCommentId;
  int likesCount;
  int repliesCount;
  Timestamp dataCadastro;
  bool isModerated;
  bool isBlocked;

  StoryCommentModel({
    this.id,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userUsername,
    this.userPhotoUrl,
    required this.text,
    this.mentions,
    this.parentCommentId,
    required this.likesCount,
    required this.repliesCount,
    required this.dataCadastro,
    required this.isModerated,
    required this.isBlocked,
  });

  factory StoryCommentModel.fromJson(Map<String, dynamic> json) {
    return StoryCommentModel(
      id: json['id'],
      storyId: json['storyId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userUsername: json['userUsername'],
      userPhotoUrl: json['userPhotoUrl'],
      text: json['text'] ?? '',
      mentions:
          json['mentions'] != null ? List<String>.from(json['mentions']) : null,
      parentCommentId: json['parentCommentId'],
      likesCount: json['likesCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      dataCadastro: json['dataCadastro'] ?? Timestamp.now(),
      isModerated: json['isModerated'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  /// Verifica se o comentário tem respostas
  bool get hasReplies => repliesCount > 0;

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'userUsername': userUsername,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'mentions': mentions,
      'parentCommentId': parentCommentId,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'dataCadastro': dataCadastro,
      'isModerated': isModerated,
      'isBlocked': isBlocked,
    };
  }
}
