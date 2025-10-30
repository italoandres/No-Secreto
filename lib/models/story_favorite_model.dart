import 'package:cloud_firestore/cloud_firestore.dart';

class StoryFavoriteModel {
  String? id;
  String storyId;
  String userId;
  String contexto; // Novo campo para separar favoritos por contexto
  Timestamp dataCadastro;

  StoryFavoriteModel({
    this.id,
    required this.storyId,
    required this.userId,
    required this.contexto,
    required this.dataCadastro,
  });

  factory StoryFavoriteModel.fromJson(Map<String, dynamic> json) {
    return StoryFavoriteModel(
      id: json['id'],
      storyId: json['storyId'] ?? '',
      userId: json['userId'] ?? '',
      contexto: json['contexto'] ?? 'principal', // Default para compatibilidade
      dataCadastro: json['dataCadastro'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'userId': userId,
      'contexto': contexto,
      'dataCadastro': dataCadastro,
    };
  }
}
