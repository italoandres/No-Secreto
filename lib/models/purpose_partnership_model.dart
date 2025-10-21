import 'package:cloud_firestore/cloud_firestore.dart';

class PurposePartnershipModel {
  String? id;
  String? user1Id;
  String? user2Id;
  String? chatId; // ID único do chat compartilhado
  bool? isActive;
  Timestamp? dataConexao;
  Timestamp? dataDesconexao;

  PurposePartnershipModel({
    this.id,
    this.user1Id,
    this.user2Id,
    this.chatId,
    this.isActive,
    this.dataConexao,
    this.dataDesconexao,
  });

  // Construtor para criar nova parceria
  PurposePartnershipModel.create({
    required String user1Id,
    required String user2Id,
    required String chatId,
  }) : this(
    user1Id: user1Id,
    user2Id: user2Id,
    chatId: chatId,
    isActive: true,
    dataConexao: Timestamp.now(),
  );

  // Converter para Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'chatId': chatId,
      'isActive': isActive,
      'dataConexao': dataConexao,
      'dataDesconexao': dataDesconexao,
    };
  }

  // Criar objeto a partir do Firebase
  factory PurposePartnershipModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data();
      if (data == null) {
        throw Exception('Documento não contém dados');
      }
      
      final Map<String, dynamic> dataMap = data as Map<String, dynamic>;
      
      return PurposePartnershipModel(
        id: doc.id,
        user1Id: dataMap['user1Id']?.toString(),
        user2Id: dataMap['user2Id']?.toString(),
        chatId: dataMap['chatId']?.toString(),
        isActive: dataMap['isActive'] ?? false,
        dataConexao: dataMap['dataConexao'] as Timestamp?,
        dataDesconexao: dataMap['dataDesconexao'] as Timestamp?,
      );
    } catch (e) {
      throw Exception('Erro ao criar PurposePartnershipModel do Firestore: $e');
    }
  }

  // Criar objeto a partir de Map
  factory PurposePartnershipModel.fromMap(Map<String, dynamic> map) {
    return PurposePartnershipModel(
      id: map['id'],
      user1Id: map['user1Id'],
      user2Id: map['user2Id'],
      chatId: map['chatId'],
      isActive: map['isActive'] ?? false,
      dataConexao: map['dataConexao'],
      dataDesconexao: map['dataDesconexao'],
    );
  }

  // Validações
  bool get isValid {
    return user1Id != null && 
           user2Id != null && 
           chatId != null &&
           user1Id != user2Id;
  }

  // Verificar se usuário faz parte da parceria
  bool includesUser(String userId) {
    return user1Id == userId || user2Id == userId;
  }

  // Verificar se dois usuários fazem parte da parceria
  bool includesUsers(String userId1, String userId2) {
    return (user1Id == userId1 && user2Id == userId2) ||
           (user1Id == userId2 && user2Id == userId1);
  }

  // Obter ID do parceiro
  String? getPartnerId(String currentUserId) {
    if (user1Id == currentUserId) return user2Id;
    if (user2Id == currentUserId) return user1Id;
    return null;
  }

  // Desconectar parceria
  PurposePartnershipModel disconnect() {
    return PurposePartnershipModel(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      chatId: chatId,
      isActive: false,
      dataConexao: dataConexao,
      dataDesconexao: Timestamp.now(),
    );
  }

  // Reativar parceria
  PurposePartnershipModel reconnect() {
    return PurposePartnershipModel(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      chatId: chatId,
      isActive: true,
      dataConexao: dataConexao,
      dataDesconexao: null,
    );
  }

  // Gerar ID único para chat compartilhado
  static String generateChatId(String user1Id, String user2Id) {
    // Ordenar IDs para garantir consistência
    List<String> sortedIds = [user1Id, user2Id]..sort();
    return 'purpose_chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  // Verificar se a parceria está ativa
  bool get isActivePartnership => isActive == true && dataDesconexao == null;

  // Calcular duração da parceria
  Duration? get partnershipDuration {
    if (dataConexao == null) return null;
    
    DateTime endDate = dataDesconexao?.toDate() ?? DateTime.now();
    return endDate.difference(dataConexao!.toDate());
  }

  @override
  String toString() {
    return 'PurposePartnershipModel(id: $id, chatId: $chatId, isActive: $isActive, users: [$user1Id, $user2Id])';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PurposePartnershipModel &&
        other.id == id &&
        other.chatId == chatId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ chatId.hashCode;
  }
}