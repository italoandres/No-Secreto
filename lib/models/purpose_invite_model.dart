import 'package:cloud_firestore/cloud_firestore.dart';

class PurposeInviteModel {
  String? id;
  String? fromUserId;
  String? fromUserName;
  String? toUserId;
  String? toUserEmail;
  String? type; // 'partnership' ou 'mention'
  String? message; // Para convites de menção
  String? status; // 'pending', 'accepted', 'rejected', 'blocked'
  Timestamp? dataCriacao;
  Timestamp? dataResposta;

  PurposeInviteModel({
    this.id,
    this.fromUserId,
    this.fromUserName,
    this.toUserId,
    this.toUserEmail,
    this.type,
    this.message,
    this.status,
    this.dataCriacao,
    this.dataResposta,
  });

  // Construtor para criar convite de parceria
  PurposeInviteModel.partnership({
    required String fromUserId,
    required String fromUserName,
    required String toUserEmail,
  }) : this(
    fromUserId: fromUserId,
    fromUserName: fromUserName,
    toUserEmail: toUserEmail,
    type: 'partnership',
    status: 'pending',
    dataCriacao: Timestamp.now(),
  );

  // Construtor para criar convite de menção
  PurposeInviteModel.mention({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String message,
  }) : this(
    fromUserId: fromUserId,
    fromUserName: fromUserName,
    toUserId: toUserId,
    type: 'mention',
    message: message,
    status: 'pending',
    dataCriacao: Timestamp.now(),
  );

  // Converter para Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserEmail': toUserEmail,
      'type': type,
      'message': message,
      'status': status,
      'dataCriacao': dataCriacao,
      'dataResposta': dataResposta,
    };
  }

  // Criar objeto a partir do Firebase
  factory PurposeInviteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PurposeInviteModel(
      id: doc.id,
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      toUserId: data['toUserId'],
      toUserEmail: data['toUserEmail'],
      type: data['type'],
      message: data['message'],
      status: data['status'],
      dataCriacao: data['dataCriacao'],
      dataResposta: data['dataResposta'],
    );
  }

  // Criar objeto a partir de Map
  factory PurposeInviteModel.fromMap(Map<String, dynamic> map) {
    return PurposeInviteModel(
      id: map['id'],
      fromUserId: map['fromUserId'],
      fromUserName: map['fromUserName'],
      toUserId: map['toUserId'],
      toUserEmail: map['toUserEmail'],
      type: map['type'],
      message: map['message'],
      status: map['status'],
      dataCriacao: map['dataCriacao'],
      dataResposta: map['dataResposta'],
    );
  }

  // Validações
  bool get isValid {
    return fromUserId != null && 
           fromUserName != null && 
           type != null && 
           status != null &&
           (type == 'partnership' ? toUserEmail != null : toUserId != null);
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isBlocked => status == 'blocked';
  bool get isPartnership => type == 'partnership';
  bool get isMention => type == 'mention';

  // Aceitar convite
  PurposeInviteModel accept() {
    return PurposeInviteModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: type,
      message: message,
      status: 'accepted',
      dataCriacao: dataCriacao,
      dataResposta: Timestamp.now(),
    );
  }

  // Rejeitar convite
  PurposeInviteModel reject() {
    return PurposeInviteModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: type,
      message: message,
      status: 'rejected',
      dataCriacao: dataCriacao,
      dataResposta: Timestamp.now(),
    );
  }

  // Bloquear usuário
  PurposeInviteModel block() {
    return PurposeInviteModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: type,
      message: message,
      status: 'blocked',
      dataCriacao: dataCriacao,
      dataResposta: Timestamp.now(),
    );
  }

  @override
  String toString() {
    return 'PurposeInviteModel(id: $id, type: $type, status: $status, from: $fromUserName)';
  }
}