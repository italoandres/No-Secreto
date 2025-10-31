import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/models/link_descricao_model.dart';

class ChatModel {
  String? id;
  String? idDe;
  bool? orginemAdmin;
  String? text;
  String? fileUrl;
  String? fileName;
  String? fileExtension;
  String? videoThumbnail;

  Timestamp? dataCadastro;
  ChatType? tipo;
  bool? isLoading;
  LinkDescricaoModel? linkDescricaoModel;
  Map<String, dynamic>? replyToStory; // 🙏 NOVO: Dados do story salvo

  ChatModel({
    this.id,
    this.idDe,
    this.orginemAdmin,
    this.text,
    this.fileUrl,
    this.fileName,
    this.fileExtension,
    this.videoThumbnail,
    this.dataCadastro,
    this.tipo,
    this.isLoading,
    this.linkDescricaoModel,
    this.replyToStory, // 🙏 NOVO
  });

  static ChatModel fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      idDe: json['idDe'],
      orginemAdmin: json['orginemAdmin'] ?? false,
      text: json['text'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'] ?? '',
      fileExtension: json['fileExtension'],
      videoThumbnail: json['videoThumbnail'],
      dataCadastro: json['dataCadastro'],
      tipo: ChatType.values.byName(json['tipo']),
      isLoading: json['isLoading'] ?? false,
      linkDescricaoModel: json['linkDescricaoModel'] == null
          ? null
          : LinkDescricaoModel.fromJson(json['linkDescricaoModel']),
      replyToStory: json['replyToStory'] != null // 🙏 NOVO
          ? Map<String, dynamic>.from(json['replyToStory'])
          : null,
    );
  }
}

enum ChatType { video, text, img, outro }
