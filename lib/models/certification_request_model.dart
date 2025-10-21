import 'package:cloud_firestore/cloud_firestore.dart';

/// Status da solicitação de certificação
enum CertificationStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case CertificationStatus.pending:
        return 'Pendente';
      case CertificationStatus.approved:
        return 'Aprovado';
      case CertificationStatus.rejected:
        return 'Rejeitado';
    }
  }

  String get icon {
    switch (this) {
      case CertificationStatus.pending:
        return '⏱️';
      case CertificationStatus.approved:
        return '✅';
      case CertificationStatus.rejected:
        return '❌';
    }
  }
}

/// Modelo de dados para solicitação de certificação espiritual
class CertificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String purchaseEmail;
  final String proofFileUrl;
  final String proofFileName;
  final CertificationStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  CertificationRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.purchaseEmail,
    required this.proofFileUrl,
    required this.proofFileName,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  /// Criar modelo a partir de documento Firestore
  factory CertificationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return CertificationRequestModel.fromMap(data);
  }
  
  /// Criar modelo a partir de Map
  factory CertificationRequestModel.fromMap(Map<String, dynamic> data) {
    // Suportar ambos os formatos (transição)
    final createdAtTimestamp = data['createdAt'] as Timestamp? ?? data['requestedAt'] as Timestamp?;
    final processedAtTimestamp = data['processedAt'] as Timestamp? ?? data['reviewedAt'] as Timestamp?;
    
    return CertificationRequestModel(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      purchaseEmail: data['purchaseEmail'] as String? ?? '',
      proofFileUrl: data['proofFileUrl'] as String? ?? '',
      proofFileName: data['proofFileName'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      processedAt: processedAtTimestamp?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// Converter para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'purchaseEmail': purchaseEmail,
      'proofFileUrl': proofFileUrl,
      'proofFileName': proofFileName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Parse status string para enum
  static CertificationStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return CertificationStatus.approved;
      case 'rejected':
        return CertificationStatus.rejected;
      case 'pending':
      default:
        return CertificationStatus.pending;
    }
  }

  /// Copiar com modificações
  CertificationRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? purchaseEmail,
    String? proofFileUrl,
    String? proofFileName,
    CertificationStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return CertificationRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      purchaseEmail: purchaseEmail ?? this.purchaseEmail,
      proofFileUrl: proofFileUrl ?? this.proofFileUrl,
      proofFileName: proofFileName ?? this.proofFileName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Verificar se está pendente
  bool get isPending => status == CertificationStatus.pending;

  /// Verificar se foi aprovado
  bool get isApproved => status == CertificationStatus.approved;

  /// Verificar se foi rejeitado
  bool get isRejected => status == CertificationStatus.rejected;

  @override
  String toString() {
    return 'CertificationRequestModel(id: $id, userId: $userId, userName: $userName, status: ${status.name})';
  }
}
