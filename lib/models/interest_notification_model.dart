import 'package:cloud_firestore/cloud_firestore.dart';

class InterestNotificationModel {
  String? id;
  String? fromUserId;
  String? fromUserName;
  String? fromUserEmail;
  String? toUserId;
  String? toUserEmail;
  String? type; // 'interest'
  String? message;
  String? status; // 'pending', 'accepted', 'rejected'
  Timestamp? dataCriacao;
  Timestamp? dataResposta;

  InterestNotificationModel({
    this.id,
    this.fromUserId,
    this.fromUserName,
    this.fromUserEmail,
    this.toUserId,
    this.toUserEmail,
    this.type,
    this.message,
    this.status,
    this.dataCriacao,
    this.dataResposta,
  });

  // Construtor para criar notificação de interesse
  InterestNotificationModel.interest({
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserId,
    required String toUserEmail,
    String? message,
  }) : this(
    fromUserId: fromUserId,
    fromUserName: fromUserName,
    fromUserEmail: fromUserEmail,
    toUserId: toUserId,
    toUserEmail: toUserEmail,
    type: 'interest',
    message: message ?? 'Tem interesse em conhecer seu perfil melhor',
    status: 'pending',
    dataCriacao: Timestamp.now(),
  );

  // Converter para Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
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
  factory InterestNotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return InterestNotificationModel(
      id: doc.id,
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      fromUserEmail: data['fromUserEmail'],
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
  factory InterestNotificationModel.fromMap(Map<String, dynamic> map) {
    return InterestNotificationModel(
      id: map['id'],
      fromUserId: map['fromUserId'],
      fromUserName: map['fromUserName'],
      fromUserEmail: map['fromUserEmail'],
      toUserId: map['toUserId'],
      toUserEmail: map['toUserEmail'],
      type: map['type'],
      message: map['message'],
      status: map['status'],
      dataCriacao: map['dataCriacao'],
      dataResposta: map['dataResposta'],
    );
  }

  // Converter para JSON (para cache)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'toUserEmail': toUserEmail,
      'type': type,
      'message': message,
      'status': status,
      'dataCriacao': dataCriacao?.millisecondsSinceEpoch,
      'dataResposta': dataResposta?.millisecondsSinceEpoch,
    };
  }

  // Criar objeto a partir de JSON (para cache)
  factory InterestNotificationModel.fromJson(Map<String, dynamic> json) {
    return InterestNotificationModel(
      id: json['id'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      fromUserEmail: json['fromUserEmail'],
      toUserId: json['toUserId'],
      toUserEmail: json['toUserEmail'],
      type: json['type'],
      message: json['message'],
      status: json['status'],
      dataCriacao: json['dataCriacao'] != null 
        ? Timestamp.fromMillisecondsSinceEpoch(json['dataCriacao'])
        : null,
      dataResposta: json['dataResposta'] != null 
        ? Timestamp.fromMillisecondsSinceEpoch(json['dataResposta'])
        : null,
    );
  }

  // Validações
  bool get isValid {
    return fromUserId != null && 
           fromUserName != null && 
           fromUserEmail != null &&
           toUserId != null &&
           toUserEmail != null &&
           type != null && 
           status != null;
  }

  // Getters de conveniência
  bool get isPending => status == 'pending' || status == 'new';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isInterest => type == 'interest';
  bool get isNew => status == 'new';
  bool get isViewed => status == 'viewed';

  // Aceitar interesse
  InterestNotificationModel accept() {
    return InterestNotificationModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: type,
      message: message,
      status: 'accepted',
      dataCriacao: dataCriacao,
      dataResposta: Timestamp.now(),
    );
  }

  // Rejeitar interesse
  InterestNotificationModel reject() {
    return InterestNotificationModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserId: toUserId,
      toUserEmail: toUserEmail,
      type: type,
      message: message,
      status: 'rejected',
      dataCriacao: dataCriacao,
      dataResposta: Timestamp.now(),
    );
  }

  @override
  String toString() {
    return 'InterestNotificationModel(id: $id, type: $type, status: $status, from: $fromUserName, to: $toUserId)';
  }
}