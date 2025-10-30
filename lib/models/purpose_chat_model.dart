import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/models/chat_model.dart';
import 'package:whatsapp_chat/models/link_descricao_model.dart';

class PurposeChatModel extends ChatModel {
  String? chatId; // ID do chat compartilhado
  List<String>? participantIds; // IDs dos participantes
  String? messagePosition; // 'left' (casal) ou 'right' (admin)
  String? mentionedUserId; // Para mensagens com @menção
  String? autorNome; // Nome do autor da mensagem
  String? autorSexo; // Sexo do autor da mensagem

  PurposeChatModel({
    // Campos herdados do ChatModel
    super.id,
    super.idDe,
    super.orginemAdmin,
    super.text,
    super.fileUrl,
    super.fileName,
    super.fileExtension,
    super.videoThumbnail,
    super.dataCadastro,
    super.tipo,
    super.isLoading,
    super.linkDescricaoModel,
    // Campos específicos do PurposeChatModel
    this.chatId,
    this.participantIds,
    this.messagePosition,
    this.mentionedUserId,
    this.autorNome,
    this.autorSexo,
  });

  // Construtor para mensagem de casal (lado esquerdo)
  PurposeChatModel.coupleMessage({
    required String chatId,
    required List<String> participantIds,
    required String autorId,
    required String autorNome,
    required String text,
    String? autorSexo,
    String? mentionedUserId,
    LinkDescricaoModel? linkDescricaoModel,
  }) : this(
          chatId: chatId,
          participantIds: participantIds,
          messagePosition: 'left',
          autorNome: autorNome,
          autorSexo: autorSexo,
          mentionedUserId: mentionedUserId,
          idDe: autorId,
          orginemAdmin: false,
          text: text,
          tipo: ChatType.text,
          dataCadastro: Timestamp.now(),
          linkDescricaoModel: linkDescricaoModel,
        );

  // Construtor para mensagem de admin (lado direito)
  PurposeChatModel.adminMessage({
    required String chatId,
    required List<String> participantIds,
    required String text,
    LinkDescricaoModel? linkDescricaoModel,
  }) : this(
          chatId: chatId,
          participantIds: participantIds,
          messagePosition: 'right',
          autorNome: 'Pai',
          idDe: 'admin',
          orginemAdmin: true,
          text: text,
          tipo: ChatType.text,
          dataCadastro: Timestamp.now(),
          linkDescricaoModel: linkDescricaoModel,
        );

  // Converter para Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participantIds': participantIds,
      'messagePosition': messagePosition,
      'mentionedUserId': mentionedUserId,
      'autorNome': autorNome,
      'autorSexo': autorSexo,
      'idDe': idDe,
      'orginemAdmin': orginemAdmin ?? false,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'videoThumbnail': videoThumbnail,
      'dataCadastro': dataCadastro,
      'tipo': tipo?.name,
      'linkDescricaoModel': linkDescricaoModel != null
          ? LinkDescricaoModel.toJson(linkDescricaoModel!)
          : null,
    };
  }

  // Criar objeto a partir do Firebase
  factory PurposeChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PurposeChatModel(
      id: doc.id,
      chatId: data['chatId'],
      participantIds: data['participantIds'] != null
          ? List<String>.from(data['participantIds'])
          : null,
      messagePosition: data['messagePosition'],
      mentionedUserId: data['mentionedUserId'],
      autorNome: data['autorNome'],
      autorSexo: data['autorSexo'],
      idDe: data['idDe'],
      orginemAdmin: data['orginemAdmin'] ?? false,
      text: data['text'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileExtension: data['fileExtension'],
      videoThumbnail: data['videoThumbnail'],
      dataCadastro: data['dataCadastro'],
      tipo: data['tipo'] != null ? ChatType.values.byName(data['tipo']) : null,
      linkDescricaoModel: data['linkDescricaoModel'] != null
          ? LinkDescricaoModel.fromJson(data['linkDescricaoModel'])
          : null,
    );
  }

  // Criar objeto a partir de Map
  factory PurposeChatModel.fromMap(Map<String, dynamic> map) {
    return PurposeChatModel(
      id: map['id'],
      chatId: map['chatId'],
      participantIds: map['participantIds'] != null
          ? List<String>.from(map['participantIds'])
          : null,
      messagePosition: map['messagePosition'],
      mentionedUserId: map['mentionedUserId'],
      autorNome: map['autorNome'],
      idDe: map['idDe'],
      orginemAdmin: map['orginemAdmin'] ?? false,
      text: map['text'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileExtension: map['fileExtension'],
      videoThumbnail: map['videoThumbnail'],
      dataCadastro: map['dataCadastro'],
      tipo: map['tipo'] != null ? ChatType.values.byName(map['tipo']) : null,
      linkDescricaoModel: map['linkDescricaoModel'] != null
          ? LinkDescricaoModel.fromJson(map['linkDescricaoModel'])
          : null,
    );
  }

  // Converter para ChatModel regular (para compatibilidade)
  ChatModel toChatModel() {
    return ChatModel(
      id: id,
      idDe: idDe,
      orginemAdmin: orginemAdmin,
      text: text,
      fileUrl: fileUrl,
      fileName: fileName,
      fileExtension: fileExtension,
      videoThumbnail: videoThumbnail,
      dataCadastro: dataCadastro,
      tipo: tipo,
      isLoading: isLoading,
      linkDescricaoModel: linkDescricaoModel,
    );
  }

  // Validações
  bool get isValid {
    return chatId != null &&
        participantIds != null &&
        participantIds!.isNotEmpty &&
        messagePosition != null &&
        (messagePosition == 'left' || messagePosition == 'right');
  }

  bool get isFromCouple => messagePosition == 'left';
  bool get isFromAdmin => messagePosition == 'right';
  bool get hasMention => mentionedUserId != null;

  // Verificar se usuário é participante
  bool includesParticipant(String userId) {
    return participantIds?.contains(userId) ?? false;
  }

  // Adicionar participante
  PurposeChatModel addParticipant(String userId) {
    List<String> newParticipants = List<String>.from(participantIds ?? []);
    if (!newParticipants.contains(userId)) {
      newParticipants.add(userId);
    }

    return PurposeChatModel(
      id: id,
      chatId: chatId,
      participantIds: newParticipants,
      messagePosition: messagePosition,
      mentionedUserId: mentionedUserId,
      autorNome: autorNome,
      idDe: idDe,
      orginemAdmin: orginemAdmin,
      text: text,
      fileUrl: fileUrl,
      fileName: fileName,
      fileExtension: fileExtension,
      videoThumbnail: videoThumbnail,
      dataCadastro: dataCadastro,
      tipo: tipo,
      isLoading: isLoading,
      linkDescricaoModel: linkDescricaoModel,
    );
  }

  @override
  String toString() {
    return 'PurposeChatModel(id: $id, chatId: $chatId, position: $messagePosition, author: $autorNome)';
  }
}
