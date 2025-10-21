import 'package:cloud_firestore/cloud_firestore.dart';

class StoryLikeModel {
  String? id;
  String storyId;
  String userId;
  String userName;
  String? userUsername;
  Timestamp dataCadastro;

  StoryLikeModel({
    this.id,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userUsername,
    required this.dataCadastro,
  });

  factory StoryLikeModel.fromJson(Map<String, dynamic> json) {
    return StoryLikeModel(
      id: json['id'],
      storyId: json['storyId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userUsername: json['userUsername'],
      dataCadastro: json['dataCadastro'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'userUsername': userUsername,
      'dataCadastro': dataCadastro,
    };
  }
}