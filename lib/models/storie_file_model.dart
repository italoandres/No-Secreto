import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';

class StorieFileModel {
  String? id;
  String? link;
  String? fileUrl;
  int? videoDuration;
  String? videoThumbnail;
  StorieFileType? fileType;
  Timestamp? dataCadastro;
  String? idioma;
  String? contexto; // 'principal', 'sinais_isaque', etc.
  UserSexo? publicoAlvo; // masculino, feminino, null (todos)

  // Novos campos para título e descrição estilo TikTok
  String? titulo;
  String? descricao;

  // Campos para notificações separadas por sexo
  String? tituloNotificacaoMasculino;
  String? tituloNotificacaoFeminino;
  String? notificacaoMasculino;
  String? notificacaoFeminino;
  bool? enviarNotificacao; // Se deve enviar notificação

  StorieFileModel({
    this.id,
    this.link,
    this.fileUrl,
    this.videoDuration,
    this.videoThumbnail,
    this.fileType,
    this.dataCadastro,
    this.idioma,
    this.contexto,
    this.publicoAlvo,
    this.titulo,
    this.descricao,
    this.tituloNotificacaoMasculino,
    this.tituloNotificacaoFeminino,
    this.notificacaoMasculino,
    this.notificacaoFeminino,
    this.enviarNotificacao,
  });

  static UserSexo? _parsePublicoAlvo(dynamic value) {
    if (value == null) return null;

    // Se já é um enum, retorna diretamente
    if (value is UserSexo) return value;

    // Se é string, converte para enum
    if (value is String) {
      try {
        return UserSexo.values.byName(value);
      } catch (e) {
        print(
            'DEBUG MODEL: Erro ao converter publicoAlvo "$value" para enum: $e');
        return null;
      }
    }

    print(
        'DEBUG MODEL: Tipo não suportado para publicoAlvo: ${value.runtimeType}');
    return null;
  }

  static StorieFileModel fromJson(Map<String, dynamic> json) {
    return StorieFileModel(
      id: json['id'], // 🔧 CRÍTICO: Ler o ID do JSON
      link: json['link'] ?? '',
      fileUrl: json['fileUrl'],
      videoThumbnail: json['videoThumbnail'] ?? '',
      videoDuration: json['videoDuration'] == null
          ? 0
          : int.parse('${json['videoDuration']}'),
      fileType: StorieFileType.values.byName(json['fileType']),
      dataCadastro: json['dataCadastro'],
      idioma: json['idioma'],
      contexto:
          json['contexto'] ?? 'principal', // Default para contexto principal
      publicoAlvo: json['publicoAlvo'] != null
          ? _parsePublicoAlvo(json['publicoAlvo'])
          : null, // null significa visível para todos
      titulo: json['titulo'],
      descricao: json['descricao'],
      tituloNotificacaoMasculino: json['tituloNotificacaoMasculino'],
      tituloNotificacaoFeminino: json['tituloNotificacaoFeminino'],
      notificacaoMasculino: json['notificacaoMasculino'],
      notificacaoFeminino: json['notificacaoFeminino'],
      enviarNotificacao: json['enviarNotificacao'] ?? false,
    );
  }

  static Map<String, dynamic> toJson(StorieFileModel item) {
    return {
      'link': item.link,
      'fileUrl': item.fileUrl,
      'videoThumbnail': item.videoThumbnail,
      'videoDuration': item.videoDuration,
      'fileType': item.fileType!.name,
      'dataCadastro': item.dataCadastro,
      'idioma': item.idioma,
      'contexto': item.contexto ?? 'principal',
      'publicoAlvo': item.publicoAlvo?.name, // null se for para todos
      'titulo': item.titulo,
      'descricao': item.descricao,
      'tituloNotificacaoMasculino': item.tituloNotificacaoMasculino,
      'tituloNotificacaoFeminino': item.tituloNotificacaoFeminino,
      'notificacaoMasculino': item.notificacaoMasculino,
      'notificacaoFeminino': item.notificacaoFeminino,
      'enviarNotificacao': item.enviarNotificacao ?? false,
    };
  }
}

enum StorieFileType { video, img }
